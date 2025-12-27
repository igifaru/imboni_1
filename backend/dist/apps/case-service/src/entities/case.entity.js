"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ESCALATION_ORDER = void 0;
exports.generateCaseReference = generateCaseReference;
exports.getNextLevel = getNextLevel;
exports.canEscalate = canEscalate;
/**
 * Generate unique case reference code
 * Format: IMB-XXXXXX-XX
 */
function generateCaseReference() {
    const timestamp = Date.now().toString(36).toUpperCase().slice(-6);
    const random = Math.random().toString(36).substring(2, 4).toUpperCase();
    return `IMB-${timestamp}-${random}`;
}
/**
 * Escalation path order
 */
exports.ESCALATION_ORDER = [
    'VILLAGE',
    'CELL',
    'SECTOR',
    'DISTRICT',
    'PROVINCE',
    'NATIONAL',
];
/**
 * Get next escalation level
 */
function getNextLevel(current) {
    const index = exports.ESCALATION_ORDER.indexOf(current);
    if (index === -1 || index >= exports.ESCALATION_ORDER.length - 1) {
        return null;
    }
    return exports.ESCALATION_ORDER[index + 1];
}
/**
 * Check if case can be escalated
 */
function canEscalate(status, level) {
    return (status !== 'RESOLVED' &&
        status !== 'CLOSED' &&
        level !== 'NATIONAL');
}
//# sourceMappingURL=case.entity.js.map