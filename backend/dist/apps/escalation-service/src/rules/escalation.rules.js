"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ESCALATION_PATH = void 0;
exports.getDeadlineHours = getDeadlineHours;
exports.getNextEscalationLevel = getNextEscalationLevel;
exports.isEligibleForEscalation = isEligibleForEscalation;
exports.isDeadlineExpired = isDeadlineExpired;
exports.calculateNewDeadline = calculateNewDeadline;
exports.getEmergencyNotificationLevels = getEmergencyNotificationLevels;
exports.getLevelDisplayName = getLevelDisplayName;
/**
 * Escalation Rules - Non-Blockable Business Logic
 *
 * CRITICAL: No leader can block or override system escalation
 */
const config_service_1 = require("../../../../libs/config/config.service");
/**
 * Escalation path following Rwanda's administrative hierarchy
 */
exports.ESCALATION_PATH = [
    'VILLAGE', // Umudugudu
    'CELL', // Akagari
    'SECTOR', // Umurenge
    'DISTRICT', // Akarere
    'PROVINCE', // Intara
    'NATIONAL', // National level / Presidential Cabinet
];
/**
 * Deadline hours by urgency level
 */
function getDeadlineHours(urgency) {
    switch (urgency) {
        case 'EMERGENCY':
            return config_service_1.config.escalation.emergencyHours;
        case 'HIGH':
            return config_service_1.config.escalation.highHours;
        case 'NORMAL':
        default:
            return config_service_1.config.escalation.normalHours;
    }
}
/**
 * Get next level in escalation path
 * Returns null if already at NATIONAL level
 */
function getNextEscalationLevel(current) {
    const currentIndex = exports.ESCALATION_PATH.indexOf(current);
    if (currentIndex === -1) {
        throw new Error(`Invalid administrative level: ${current}`);
    }
    if (currentIndex >= exports.ESCALATION_PATH.length - 1) {
        return null; // Already at national level
    }
    return exports.ESCALATION_PATH[currentIndex + 1];
}
/**
 * Check if case is eligible for escalation
 */
function isEligibleForEscalation(status, currentLevel) {
    // Cannot escalate resolved or closed cases
    if (status === 'RESOLVED' || status === 'CLOSED') {
        return false;
    }
    // Cannot escalate beyond national level
    if (currentLevel === 'NATIONAL') {
        return false;
    }
    return true;
}
/**
 * Check if deadline has expired
 */
function isDeadlineExpired(deadline, now = new Date()) {
    return now >= deadline;
}
/**
 * Calculate new deadline for escalated case
 */
function calculateNewDeadline(urgency) {
    const hours = getDeadlineHours(urgency);
    const deadline = new Date();
    deadline.setHours(deadline.getHours() + hours);
    return deadline;
}
/**
 * Emergency cases trigger parallel notifications to multiple levels
 */
function getEmergencyNotificationLevels() {
    return ['SECTOR', 'DISTRICT'];
}
/**
 * Get level display name in Kinyarwanda
 */
function getLevelDisplayName(level) {
    const names = {
        VILLAGE: 'Umudugudu',
        CELL: 'Akagari',
        SECTOR: 'Umurenge',
        DISTRICT: 'Akarere',
        PROVINCE: 'Intara',
        NATIONAL: 'Urwego rw\'Igihugu',
    };
    return names[level];
}
//# sourceMappingURL=escalation.rules.js.map