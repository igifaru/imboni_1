"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.caseController = void 0;
/**
 * Case Controller - REST API Endpoints
 */
const express_1 = require("express");
const case_service_1 = require("../services/case.service");
const case_dto_1 = require("../dto/case.dto");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('case-controller');
const router = (0, express_1.Router)();
/**
 * POST /cases - Create new case
 */
router.post('/', async (req, res, next) => {
    try {
        const validation = case_dto_1.CreateCaseSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }
        const userId = req.user?.userId;
        const result = await case_service_1.caseService.createCase(validation.data, userId);
        res.status(201).json({
            success: true,
            data: result,
            message: 'Case submitted successfully',
        });
    }
    catch (error) {
        logger.error('Failed to create case', error);
        next(error);
    }
});
/**
 * GET /cases/track/:reference - Track case by reference
 */
router.get('/track/:reference', async (req, res, next) => {
    try {
        const { reference } = req.params;
        const validation = case_dto_1.TrackCaseSchema.safeParse({ caseReference: reference });
        if (!validation.success) {
            return res.status(400).json({
                error: 'Invalid case reference format',
            });
        }
        const result = await case_service_1.caseService.trackCase(reference);
        if (!result) {
            return res.status(404).json({
                error: 'Case not found',
            });
        }
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to track case', error);
        next(error);
    }
});
/**
 * GET /cases/assigned - Get assigned cases for logged-in leader
 */
router.get('/assigned', async (req, res, next) => {
    try {
        const userId = req.user?.userId;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        if (!userId) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        const result = await case_service_1.caseService.getLeaderCases(userId, page, limit);
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to get assigned cases', error);
        next(error);
    }
});
/**
 * GET /cases/escalation-alerts - Get escalation alerts
 */
router.get('/escalation-alerts', async (req, res, next) => {
    try {
        const userId = req.user?.userId;
        const result = await case_service_1.caseService.getEscalationAlerts(userId);
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to get escalation alerts', error);
        next(error);
    }
});
/**
 * GET /cases/metrics - Get performance metrics
 */
router.get('/metrics', async (req, res, next) => {
    try {
        const userId = req.user?.userId;
        const result = await case_service_1.caseService.getPerformanceMetrics(userId);
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to get metrics', error);
        next(error);
    }
});
/**
 * GET /cases/:id - Get case details
 */
router.get('/:id', async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await case_service_1.caseService.getCaseById(id);
        if (!result) {
            return res.status(404).json({
                error: 'Case not found',
            });
        }
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to get case', error);
        next(error);
    }
});
/**
 * GET /cases/leader/:leaderId - Get cases assigned to leader
 */
router.get('/leader/:leaderId', async (req, res, next) => {
    try {
        const { leaderId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const result = await case_service_1.caseService.getLeaderCases(leaderId, page, limit);
        res.json({
            success: true,
            data: result,
        });
    }
    catch (error) {
        logger.error('Failed to get leader cases', error);
        next(error);
    }
});
/**
 * PATCH /cases/:id - Update case
 */
router.patch('/:id', async (req, res, next) => {
    try {
        const { id } = req.params;
        const validation = case_dto_1.UpdateCaseSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({
                error: 'Authentication required',
            });
        }
        const result = await case_service_1.caseService.updateCase(id, validation.data, userId);
        res.json({
            success: true,
            data: result,
            message: 'Case updated successfully',
        });
    }
    catch (error) {
        logger.error('Failed to update case', error);
        next(error);
    }
});
exports.caseController = router;
//# sourceMappingURL=case.controller.js.map