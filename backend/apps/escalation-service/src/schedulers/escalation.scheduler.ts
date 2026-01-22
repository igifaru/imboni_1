/**
 * Escalation Scheduler - Automatic Deadline Enforcement
 * 
 * Runs every minute to check for expired deadlines and trigger escalations.
 * This is SYSTEM-CONTROLLED - no leader can block escalation.
 */
import cron from 'node-cron';
import { prisma } from '../../../../libs/database/prisma.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { publishEvent, CHANNELS } from '../../../../libs/messaging/messaging.service';
import {
    getNextEscalationLevel,
    isEligibleForEscalation,
    calculateNewDeadline,
    getEmergencyNotificationLevels,
    AdministrativeLevel,
} from '../rules/escalation.rules';
import { findNearestLeader } from '../../../../libs/database/assignment.utils';

const logger = createServiceLogger('escalation-scheduler');

export class EscalationScheduler {
    private cronJob: cron.ScheduledTask | null = null;

    /**
     * Start the scheduler
     */
    start(): void {
        // Run every minute
        this.cronJob = cron.schedule('* * * * *', async () => {
            await this.checkAndEscalate();
        });

        logger.info('Escalation scheduler started - running every minute');
    }

    /**
     * Stop the scheduler
     */
    stop(): void {
        if (this.cronJob) {
            this.cronJob.stop();
            this.cronJob = null;
            logger.info('Escalation scheduler stopped');
        }
    }

    /**
     * Check for expired deadlines and trigger escalations
     */
    async checkAndEscalate(): Promise<void> {
        try {
            const now = new Date();

            // Find all active assignments with expired deadlines
            const expiredAssignments = await prisma.caseAssignment.findMany({
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
        } catch (error) {
            logger.error('Error in escalation check', error);
        }
    }

    /**
     * Escalate a single case
     */
    private async escalateCase(assignment: any): Promise<void> {
        const caseData = assignment.case;
        const currentLevel = caseData.currentLevel as AdministrativeLevel;

        // Check if eligible for escalation
        if (!isEligibleForEscalation(caseData.status, currentLevel)) {
            logger.debug(`Case ${caseData.id} not eligible for escalation`);
            return;
        }

        // Get next level
        const nextLevel = getNextEscalationLevel(currentLevel);

        if (!nextLevel) {
            logger.warn(`Case ${caseData.id} already at maximum level`);
            return;
        }

        logger.info(`Escalating case ${caseData.caseReference} from ${currentLevel} to ${nextLevel}`);

        try {
            // Start transaction
            await prisma.$transaction(async (tx) => {
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
                    // 5. Find nearest active leader in hierarchy (recursive up)
                    // We use the transaction client 'tx' for consistency
                    const parentLeader = await findNearestLeader(tx, currentUnit.parentId);

                    if (parentLeader) {
                        // 6. Create new assignment at parent level (or nearest available)
                        const newDeadline = calculateNewDeadline(caseData.urgency);

                        await tx.caseAssignment.create({
                            data: {
                                caseId: caseData.id,
                                administrativeUnitId: parentLeader.administrativeUnitId, // Use the unit where leader was found
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
                                message: `Case escalated to you (Time Expired): ${caseData.title}`,
                            },
                        });

                        // 8. Update case location to match the leader's unit (optional but good for consistency)
                        await tx.case.update({
                            where: { id: caseData.id },
                            data: {
                                administrativeUnitId: parentLeader.administrativeUnitId
                                // Note: We might want to keep original location? 
                                // But 'case.administrativeUnitId' usually tracks where the case IS currently.
                                // The original location is preserved in historical path if needed?
                                // Actually, usually we move the case UP.
                            }
                        });

                    } else {
                        // Log warn: Escaled but no leader found
                        logger.warn(`Case ${caseData.id} escalated to ${nextLevel} but no leader found in upstream hierarchy!`);
                    }
                }
            });

            // Publish escalation event
            await publishEvent(CHANNELS.CASE_ESCALATED, {
                caseId: caseData.id,
                caseReference: caseData.caseReference,
                fromLevel: currentLevel,
                toLevel: nextLevel,
                reason: 'TIME_EXPIRED',
            });

            // Log audit event
            await publishEvent(CHANNELS.AUDIT_LOG, {
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
        } catch (error) {
            logger.error(`Failed to escalate case ${caseData.id}`, error);
        }
    }

    /**
     * Send parallel notifications for emergency cases
     */
    private async sendEmergencyNotifications(caseData: any): Promise<void> {
        const levels = getEmergencyNotificationLevels();

        logger.info(`Sending emergency notifications for case ${caseData.caseReference}`);

        // Find leaders at emergency notification levels
        for (const level of levels) {
            const leaders = await prisma.leaderAssignment.findMany({
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
                await prisma.notification.create({
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

export const escalationScheduler = new EscalationScheduler();
