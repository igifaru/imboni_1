"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.caseService = exports.CaseService = void 0;
/**
 * Case Service - Business Logic
 */
const case_repository_1 = require("../repositories/case.repository");
const messaging_service_1 = require("../../../../libs/messaging/messaging.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const config_service_1 = require("../../../../libs/config/config.service");
const client_1 = require("@prisma/client");
const logger = (0, logger_service_1.createServiceLogger)('case-service');
// Professionalization: Pre-load static hierarchy once
const rwandaAdminData = require('../../../api-gateway/src/data/rwanda-admin.json');
const ADMIN_JSON = rwandaAdminData.default || rwandaAdminData;
/**
 * Province name mapping: Kinyarwanda -> data.json keys
 */
const provinceMapping = {
    'Kigali': 'Kigali',
    'City of Kigali': 'Kigali',
    'Kigali City': 'Kigali',
    'Amajyaruguru': 'North',
    'Northern Province': 'North',
    'Amajyepfo': 'South',
    'Southern Province': 'South',
    'Iburasirazuba': 'East',
    'Eastern Province': 'East',
    'Iburengerazuba': 'West',
    'Western Province': 'West',
};
/**
 * Find the unit's path in the database to traverse JSON
 */
async function getUnitFullPath(unitId) {
    const path = [];
    let currId = unitId;
    while (currId) {
        const u = await prisma_service_1.prisma.administrativeUnit.findUnique({ where: { id: currId } });
        if (!u)
            break;
        path.unshift(u);
        currId = u.parentId;
    }
    return path;
}
/**
 * Navigate through Rwanda Admin JSON using the unit path
 */
function getDataAtUnitPath(path, data) {
    let current = data;
    for (const unit of path) {
        let nameToFind = unit.name;
        if (unit.level === client_1.AdministrativeLevel.PROVINCE) {
            nameToFind = provinceMapping[unit.name] || unit.name;
        }
        if (Array.isArray(current)) {
            const found = current.find(item => item.name === nameToFind);
            if (!found)
                return null;
            current = found;
        }
        else if (current && typeof current === 'object') {
            current = current[nameToFind];
        }
        else {
            return null;
        }
    }
    return current;
}
/**
 * Extract names of children from the administrative data structure
 */
function getChildrenFromJson(path, data) {
    const container = getDataAtUnitPath(path, data);
    if (!container)
        return [];
    // The JSON structure:
    // Province/District level: objects where keys are child names
    // Sector level: objects where keys are cell names
    // Cell level: objects/arrays for villages
    if (Array.isArray(container)) {
        return container.map(c => typeof c === 'string' ? c : c.name).filter(Boolean);
    }
    if (container && typeof container === 'object') {
        return Object.keys(container);
    }
    return [];
}
class CaseService {
    repository;
    constructor() {
        this.repository = case_repository_1.caseRepository;
    }
    /**
     * Create a new case
     */
    async createCase(dto, userId) {
        logger.info('Creating new case', { category: dto.category, anonymous: dto.submittedAnonymously });
        // Create the case
        const newCase = await this.repository.create(dto, userId);
        // Create initial assignment to village leader
        await this.createAssignment(newCase);
        // Publish event for other services
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_CREATED, {
            caseId: newCase.id,
            caseReference: newCase.caseReference,
            category: newCase.category,
            urgency: newCase.urgency,
        });
        // Log audit event
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.AUDIT_LOG, {
            entityType: 'Case',
            entityId: newCase.id,
            action: 'CREATE',
            performedBy: userId || 'ANONYMOUS',
        });
        logger.info('Case created successfully', { caseReference: newCase.caseReference });
        return this.toResponseDto(newCase);
    }
    /**
     * Track case by reference
     */
    async trackCase(caseReference) {
        const foundCase = await this.repository.findByReference(caseReference);
        if (!foundCase) {
            return null;
        }
        return this.toResponseDto(foundCase);
    }
    /**
     * Get case details
     */
    async getCaseById(id) {
        const foundCase = await this.repository.findById(id);
        if (!foundCase) {
            return null;
        }
        return this.toResponseDto(foundCase);
    }
    /**
     * Get cases assigned to leader
     */
    async getLeaderCases(leaderId, page = 1, limit = 20) {
        const result = await this.repository.findByLeader(leaderId, page, limit);
        return {
            cases: result.cases.map((c) => this.toResponseDto(c)),
            total: result.total,
            page,
            limit,
        };
    }
    /**
     * Update case status (for leaders)
     */
    async updateCase(caseId, dto, userId) {
        const existingCase = await this.repository.findById(caseId);
        if (!existingCase) {
            throw new Error('Case not found');
        }
        // Update status if provided
        if (dto.status) {
            await this.repository.updateStatus(caseId, dto.status);
            // Log the action
            await prisma_service_1.prisma.caseAction.create({
                data: {
                    caseId,
                    performedBy: userId,
                    actionType: 'STATUS_UPDATE',
                    notes: dto.notes || `Status changed to ${dto.status}`,
                },
            });
            // Publish event
            await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_UPDATED, {
                caseId,
                status: dto.status,
                updatedBy: userId,
            });
            // If resolved, mark assignment as complete
            if (dto.status === 'RESOLVED') {
                await this.completeAssignment(caseId);
                await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.CASE_RESOLVED, { caseId });
            }
        }
        const updatedCase = await this.repository.findById(caseId);
        return this.toResponseDto(updatedCase);
    }
    /**
     * Create assignment to leader of administrative unit
     */
    async createAssignment(caseData) {
        // Find the leader for the administrative unit
        const leader = await prisma_service_1.prisma.leaderAssignment.findFirst({
            where: {
                administrativeUnitId: caseData.administrativeUnitId,
                isActive: true,
            },
        });
        if (!leader) {
            logger.warn('No leader found for unit', { unitId: caseData.administrativeUnitId });
            return;
        }
        // Calculate deadline
        const deadlineHours = this.getDeadlineHours(caseData.urgency);
        const deadlineAt = new Date();
        deadlineAt.setHours(deadlineAt.getHours() + deadlineHours);
        await prisma_service_1.prisma.caseAssignment.create({
            data: {
                caseId: caseData.id,
                administrativeUnitId: caseData.administrativeUnitId,
                leaderId: leader.userId,
                deadlineAt,
                isActive: true,
            },
        });
        // Send notification to leader
        await (0, messaging_service_1.publishEvent)(messaging_service_1.CHANNELS.NOTIFICATION_SEND, {
            userId: leader.userId,
            caseId: caseData.id,
            channel: 'PUSH',
            message: `New case assigned: ${caseData.title}`,
        });
    }
    /**
     * Complete active assignment
     */
    async completeAssignment(caseId) {
        await prisma_service_1.prisma.caseAssignment.updateMany({
            where: { caseId, isActive: true },
            data: { completedAt: new Date(), isActive: false },
        });
    }
    /**
     * Get deadline hours based on urgency
     */
    getDeadlineHours(urgency) {
        switch (urgency) {
            case 'EMERGENCY':
                return config_service_1.config.escalation.emergencyHours;
            case 'HIGH':
                return config_service_1.config.escalation.highHours;
            default:
                return config_service_1.config.escalation.normalHours;
        }
    }
    /**
     * Get escalation alerts for leader
     */
    async getEscalationAlerts(leaderId) {
        // Find active assignments with approaching deadlines (< 24 hours)
        const now = new Date();
        const tomorrow = new Date();
        tomorrow.setHours(tomorrow.getHours() + 24);
        const assignments = await prisma_service_1.prisma.caseAssignment.findMany({
            where: {
                leaderId,
                isActive: true,
                deadlineAt: {
                    lte: tomorrow, // Deadline is before tomorrow (so it's today or past due)
                },
            },
            include: {
                case: true,
            },
            orderBy: {
                deadlineAt: 'asc',
            },
        });
        return assignments.map(a => this.toResponseDto(a.case));
    }
    /**
     * Get performance metrics for leader (Jurisdiction View)
     */
    async getPerformanceMetrics(leaderId, filters) {
        // 1. Get Leader's Unit and Direct Children (for Regional Breakdown)
        const leadership = await prisma_service_1.prisma.leaderAssignment.findFirst({
            where: { userId: leaderId, isActive: true },
            include: {
                administrativeUnit: {
                    include: { children: true }
                }
            }
        });
        logger.info('DEBUG getPerformanceMetrics', { leaderId, leadership: !!leadership });
        // Initialize trends early to be available in all return paths
        const weeklyTrends = Array(7).fill(0).map((_, i) => {
            const d = new Date();
            d.setDate(d.getDate() - (6 - i));
            return {
                day: d.toLocaleDateString('en-US', { weekday: 'short' }),
                date: d.toISOString().split('T')[0],
                newCases: 0,
                resolvedCases: 0,
                activeCases: 0
            };
        });
        if (!leadership) {
            logger.warn('No active leader assignment for user', { leaderId });
            return {
                totalCases: 0,
                resolvedCases: 0,
                pendingCases: 0,
                escalatedCases: 0,
                resolutionRate: 0,
                avgResponseTimeHours: 0,
                escalationRate: 0,
                overdueCases: 0,
                casesByCategory: {},
                weeklyTrends,
                subUnitBreakdown: []
            };
        }
        const myUnit = leadership.administrativeUnit;
        const dbSubUnits = myUnit.children;
        // Use pre-loaded JSON
        const unitPath = await getUnitFullPath(myUnit.id);
        const jsonChildrenNames = getChildrenFromJson(unitPath, ADMIN_JSON);
        logger.info('DEBUG Hierarchy Info', {
            unitName: myUnit.name,
            unitLevel: myUnit.level,
            dbSubUnitsCount: dbSubUnits.length,
            unitPath: unitPath.map(u => u.name),
            jsonChildrenCount: jsonChildrenNames.length,
            jsonChildren: jsonChildrenNames.slice(0, 5)
        });
        // Merge: Use DB children where they exist, and JSON children as fallbacks
        const subUnitsForBreakdown = [];
        const dbNames = new Set(dbSubUnits.map(u => u.name));
        // Add DB units first
        subUnitsForBreakdown.push(...dbSubUnits.map(u => ({ id: u.id, name: u.name })));
        // Add JSON-only units as virtual units
        jsonChildrenNames.forEach(name => {
            if (!dbNames.has(name)) {
                subUnitsForBreakdown.push({ id: name, name });
            }
        });
        logger.info('DEBUG FINAL merged subunits', {
            count: subUnitsForBreakdown.length,
            names: subUnitsForBreakdown.map(s => s.name)
        });
        // For case filtering, we use hierarchical codes for subtree fetch
        const whereClause = {
            administrativeUnit: {
                code: { startsWith: myUnit.code }
            }
        };
        if (filters?.locationId && filters.locationId !== 'All Locations') {
            const selectedUnit = dbSubUnits.find(u => u.id === filters.locationId || u.name === filters.locationId);
            if (selectedUnit) {
                whereClause.administrativeUnit = { code: { startsWith: selectedUnit.code } };
            }
            else if (filters.locationId === myUnit.id) {
                whereClause.administrativeUnit = { code: { startsWith: myUnit.code } };
            }
            else {
                return {
                    totalCases: 0,
                    resolvedCases: 0,
                    pendingCases: 0,
                    escalatedCases: 0,
                    resolutionRate: 0,
                    avgResponseTimeHours: 0,
                    escalationRate: 0,
                    overdueCases: 0,
                    casesByCategory: {},
                    weeklyTrends,
                    subUnitBreakdown: subUnitsForBreakdown.map(u => ({
                        unitId: u.id,
                        unitName: u.name,
                        totalCases: 0,
                        resolutionRate: 0,
                        avgResponseTimeHours: 0,
                        escalationRate: 0,
                        status: 'On Track'
                    }))
                };
            }
        }
        if (filters?.category && filters.category !== 'All Categories') {
            whereClause.category = filters.category;
        }
        if (filters?.startDate || filters?.endDate) {
            whereClause.createdAt = {};
            if (filters.startDate)
                whereClause.createdAt.gte = filters.startDate;
            if (filters.endDate)
                whereClause.createdAt.lte = filters.endDate;
        }
        const cases = await prisma_service_1.prisma.case.findMany({
            where: whereClause,
            include: {
                administrativeUnit: true,
                assignments: {
                    where: { isActive: true }
                }
            }
        });
        const total = cases.length;
        if (total === 0) {
            return {
                totalCases: 0,
                resolvedCases: 0,
                pendingCases: 0,
                escalatedCases: 0,
                resolutionRate: 0,
                avgResponseTimeHours: 0,
                escalationRate: 0,
                overdueCases: 0,
                casesByCategory: {},
                weeklyTrends,
                subUnitBreakdown: subUnitsForBreakdown.map(u => ({
                    unitId: u.id,
                    unitName: u.name,
                    totalCases: 0,
                    resolutionRate: 0,
                    avgResponseTimeHours: 0,
                    escalationRate: 0,
                    status: 'On Track'
                }))
            };
        }
        let resolved = 0;
        let escalated = 0;
        let overdue = 0;
        let totalResponseTimeMinutes = 0;
        let casesWithResponseTime = 0;
        const byCategory = {};
        const now = new Date();
        const getTrendIndex = (date) => {
            const dateString = date.toISOString().split('T')[0];
            return weeklyTrends.findIndex((t) => t.date === dateString);
        };
        const rollupMap = new Map();
        subUnitsForBreakdown.forEach(u => rollupMap.set(u.id, []));
        for (const c of cases) {
            if (c.status === 'RESOLVED') {
                resolved++;
                if (c.resolvedAt) {
                    const diffMins = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                    totalResponseTimeMinutes += diffMins;
                    casesWithResponseTime++;
                    const idx = getTrendIndex(new Date(c.resolvedAt));
                    if (idx !== -1)
                        weeklyTrends[idx].resolvedCases++;
                }
            }
            else if (c.status === 'ESCALATED') {
                escalated++;
            }
            if (c.status !== 'RESOLVED' && c.assignments.length > 0) {
                if (new Date(c.assignments[0].deadlineAt) < now)
                    overdue++;
            }
            byCategory[c.category] = (byCategory[c.category] || 0) + 1;
            const idx = getTrendIndex(new Date(c.createdAt));
            if (idx !== -1)
                weeklyTrends[idx].newCases++;
            const caseCode = c.administrativeUnit.code;
            const myCodeParts = myUnit.code.split(':').length;
            const parts = caseCode.split(':');
            if (parts.length > myCodeParts) {
                const childCode = parts.slice(0, myCodeParts + 1).join(':');
                const directChild = dbSubUnits.find(u => u.code === childCode);
                if (directChild) {
                    rollupMap.get(directChild.id)?.push(c);
                }
                else {
                    const childNameToken = parts[myCodeParts].replace(/_/g, ' ');
                    if (rollupMap.has(childNameToken)) {
                        rollupMap.get(childNameToken)?.push(c);
                    }
                }
            }
        }
        weeklyTrends.forEach(t => {
            t.activeCases = Math.max(0, t.newCases - t.resolvedCases);
        });
        const subUnitBreakdown = subUnitsForBreakdown.map(unit => {
            const unitCases = rollupMap.get(unit.id) || [];
            let uResolved = 0;
            let uEscalated = 0;
            let uResponseTime = 0;
            let uTimeCount = 0;
            unitCases.forEach(c => {
                if (c.status === 'RESOLVED') {
                    uResolved++;
                    if (c.resolvedAt) {
                        const diff = (new Date(c.resolvedAt).getTime() - new Date(c.createdAt).getTime()) / 60000;
                        uResponseTime += diff;
                        uTimeCount++;
                    }
                }
                if (c.status === 'ESCALATED')
                    uEscalated++;
            });
            const uTotal = unitCases.length;
            return {
                unitId: unit.id,
                unitName: unit.name,
                totalCases: uTotal,
                resolutionRate: uTotal > 0 ? (uResolved / uTotal) * 100 : 0,
                avgResponseTimeHours: uTimeCount > 0 ? (uResponseTime / uTimeCount / 60) : 0,
                escalationRate: uTotal > 0 ? (uEscalated / uTotal) * 100 : 0,
                status: (uTotal > 0 && (uResolved / uTotal) < 0.5) ? 'Critical' : 'On Track'
            };
        });
        return {
            totalCases: total,
            resolvedCases: resolved,
            pendingCases: total - resolved,
            escalatedCases: escalated,
            resolutionRate: total > 0 ? (resolved / total) * 100 : 0,
            avgResponseTimeHours: casesWithResponseTime > 0 ? (totalResponseTimeMinutes / casesWithResponseTime) / 60 : 0,
            escalationRate: total > 0 ? (escalated / total) * 100 : 0,
            overdueCases: overdue,
            casesByCategory: byCategory,
            weeklyTrends,
            subUnitBreakdown
        };
    }
    /**
     * Transform entity to response DTO
     */
    toResponseDto(entity) {
        return {
            id: entity.id,
            caseReference: entity.caseReference,
            category: entity.category,
            urgency: entity.urgency,
            title: entity.title,
            description: entity.description,
            currentLevel: entity.currentLevel,
            status: entity.status,
            createdAt: entity.createdAt.toISOString(),
            resolvedAt: entity.resolvedAt?.toISOString() || null,
            deadline: null, // Will be populated from assignment
            daysRemaining: null,
        };
    }
}
exports.CaseService = CaseService;
exports.caseService = new CaseService();
//# sourceMappingURL=case.service.js.map