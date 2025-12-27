"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.escalationScheduler = exports.EscalationScheduler = void 0;
/**
 * Escalation Scheduler - Automatic Deadline Enforcement
 *
 * Runs every minute to check for expired deadlines and trigger escalations.
 * This is SYSTEM-CONTROLLED - no leader can block escalation.
 */
const node_cron_1 = __importDefault(require("node-cron"));
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const messaging_service_1 = require("../../../../libs/messaging/messaging.service");
const escalation_rules_1 = require("../rules/escalation.rules");
const logger = (0, logger_service_1.createServiceLogger)('escalation-scheduler');
class EscalationScheduler {
    cronJob = null;
    /**
     * Start the scheduler
     */
    start() {
        // Run every minute
        this.cronJob = node_cron_1.default.schedule('* * * * *', async () => {
            await this.checkAndEscalate();
        });
        logger.info('Escalation scheduler started - running every minute');
    }
    /**
     * Stop the scheduler
     */
    stop() {
        if (this.cronJob) {
            this.cronJob.stop();
            this.cronJob = null;
            logger.info('Escalation scheduler stopped');
        }
    }
    /**
     * Check for expired deadlines and trigger escalations
     */
    async checkAndEscalate() {
        try {
            const now = new Date();
            // Find all active assignments with expired deadlines
            const expiredAssignments = await prisma_service_1.prisma.caseAssignment.findMany({
                where: {
                    isActive: true,
                    completedAt: null,
                    deadlineAt: { lte: now },
                },
                include: {
                    case: true,
                },
            });
            if (expiredAssignments.length === 0) {
                return;
            }
            logger.info(`Found ${expiredAssignments.length} expired assignments`);
            for (const assignment of expiredAssignments) {
                await this.escalateCase(assignment);
            }
        }
        catch (error) {
            logger.error('Error in escalation check', error);
        }
    }
    /**
     * Escalate a single case
     */
    async escalateCase(assignment) {
        const caseData = assignment.case;
        const currentLevel = caseData.currentLevel;
        // Check if eligible for escalation
        if (!(0, escalation_rules_1.isEligibleForEscalation)(caseData.status, currentLevel)) {
            logger.debug(`Case ${caseData.id} not eligible for escalation`);
            return;
        }
        // Get next level
        const nextLevel = (0, escalation_rules_1.getNextEscalationLevel)(currentLevel);
        if (!nextLevel) {
            logger.warn(`Case ${caseData.id} already at maximum level`);
            return;
        }
        logger.info(`Escalating case ${caseData.caseReference} from ${currentLevel} to ${nextLevel}`);
        try {
            // Start transaction
            await prisma_service_1.prisma.$transaction(async (tx) => {
                // 1. Mark current assignment as completed (with escalation reason)
                await tx.caseAssignment.update({
                    where: { id: assignment.id },
                    data: {
                        isActive: false,
                        escalationReason: 'TIME_EXPIRED',
                    },
                });
                // 2. Update case level and status
                await tx.case.update({
                    where: { id: caseData.id },
                    data: {
                        currentLevel: nextLevel,
                        status: 'ESCALATED',
                    },
                });
                // 3. Create escalation event (IMMUTABLE RECORD)
                await tx.escalationEvent.create({
                    data: {
                        caseId: caseData.id,
                        fromLevel: currentLevel,
                        toLevel: nextLevel,
                        triggeredBy: 'SYSTEM',
                        triggerReason: 'TIME_EXPIRED',
                    },
                });
                // 4. Find parent administrative unit
                const currentUnit = await tx.administrativeUnit.findUnique({
                    where: { id: caseData.administrativeUnitId },
                });
                if (currentUnit?.parentId) {
                    // 5. Find leader at parent level
                    const parentLeader = await tx.leaderAssignment.findFirst({
                        where: {
                            administrativeUnitId: currentUnit.parentId,
                            isActive: true,
                        },
                    });
                    if (parentLeader) {
                        // 6. Create new assignment at parent level
                        const newDeadline = (0, escalation_rules_1.calculateNewDeadline)(caseData.urgency);
                        await tx.caseAssignment.create({
                            data: {
                                caseId: caseData.id,
                                administrativeUnitId: currentUnit.parentId,
                                leaderId: parentLeader.userId,
                                deadlineAt: newDeadline,
                                isActive: true,
                            },
                        });
                        // 7. Send notification to new leader
                        await tx.notification.create({
                            data: {
                                userId: parentLeader.userId,
                                caseId: caseData.id,
                                channel: 'PUSH',
                                message: `Case escalated to you: ${caseData.title}`,
                            },
                        });
                    }
                }
            });
            // Publish escalation event
            await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_ESCALATED, {
                caseId: caseData.id,
                caseReference: caseData.caseReference,
                fromLevel: currentLevel,
                toLevel: nextLevel,
                reason: 'TIME_EXPIRED',
            });
            // Log audit event
            await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.AUDIT_LOG, {
                entityType: 'Case',
                entityId: caseData.id,
                action: 'ESCALATE',
                performedBy: 'SYSTEM',
                newValue: { fromLevel: currentLevel, toLevel: nextLevel },
            });
            logger.info(`Successfully escalated case ${caseData.caseReference}`);
            // Handle emergency notifications
            if (caseData.urgency === 'EMERGENCY') {
                await this.sendEmergencyNotifications(caseData);
            }
        }
        catch (error) {
            logger.error(`Failed to escalate case ${caseData.id}`, error);
        }
    }
    /**
     * Send parallel notifications for emergency cases
     */
    async sendEmergencyNotifications(caseData) {
        const levels = (0, escalation_rules_1.getEmergencyNotificationLevels)();
        logger.info(`Sending emergency notifications for case ${caseData.caseReference}`);
        // Find leaders at emergency notification levels
        for (const level of levels) {
            const leaders = await prisma_service_1.prisma.leaderAssignment.findMany({
                where: {
                    isActive: true,
                    administrativeUnit: {
                        level: level,
                    },
                },
                include: {
                    user: true,
                },
            });
            for (const leader of leaders) {
                await prisma_service_1.prisma.notification.create({
                    data: {
                        userId: leader.userId,
                        caseId: caseData.id,
                        channel: 'SMS',
                        message: `EMERGENCY: ${caseData.title} - Requires immediate attention`,
                    },
                });
            }
        }
    }
}
exports.EscalationScheduler = EscalationScheduler;
exports.escalationScheduler = new EscalationScheduler();
//# sourceMappingURL=escalation.scheduler.js.map