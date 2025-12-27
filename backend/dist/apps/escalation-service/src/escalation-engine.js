"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ESCALATION_PATH = exports.ESCALATION_DEADLINES = void 0;
exports.getNextLevel = getNextLevel;
exports.calculateDeadline = calculateDeadline;
exports.shouldEscalate = shouldEscalate;
exports.ESCALATION_DEADLINES = {
    NORMAL: 48, // 2 days
    HIGH: 24, // 1 day  
    EMERGENCY: 4, // 4 hours
};
exports.ESCALATION_PATH = [
    'VILLAGE',
    'CELL',
    'SECTOR',
    'DISTRICT',
    'PROVINCE',
    'NATIONAL',
];
function getNextLevel(current) {
    const index = exports.ESCALATION_PATH.indexOf(current);
    if (index === -1 || index === exports.ESCALATION_PATH.length - 1)
        return null;
    return exports.ESCALATION_PATH[index + 1];
}
function calculateDeadline(urgency, start = new Date()) {
    const hours = exports.ESCALATION_DEADLINES[urgency];
    const deadline = new Date(start);
    deadline.setHours(deadline.getHours() + hours);
    return deadline;
}
function shouldEscalate(deadline) {
    return new Date() >= deadline;
}
//# sourceMappingURL=escalation-engine.js.map