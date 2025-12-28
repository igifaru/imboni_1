/**
 * Case Controller - REST API Endpoints
 */
import { Router, Request, Response, NextFunction } from 'express';
import { caseService } from '../services/case.service';
import { CreateCaseSchema, UpdateCaseSchema, TrackCaseSchema } from '../dto/case.dto';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('case-controller');
const router = Router();

/**
 * POST /cases - Create new case
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const validation = CreateCaseSchema.safeParse(req.body);
        // ... existing code ...
    } catch (error) {
        // ... existing code ...
    }
});

/**
 * GET /cases/stats/global - Get global statistics (Admin)
 */
router.get('/stats/global', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await caseService.getGlobalStats();
        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get global stats', error);
        next(error);
    }
});

/**
 * GET /cases - Get all cases (Admin)
 */
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 50;
        const search = req.query.search as string;

        const result = await caseService.getAllCases(page, limit, search);
        res.json({
            success: true,
            data: result.cases,
            meta: {
                total: result.total,
                page: result.page,
                limit: result.limit
            }
        });
    } catch (error) {
        logger.error('Failed to fetch all cases', error);
        next(error);
    }
});



/**
 * GET /cases/track/:reference - Track case by reference
 */
router.get('/track/:reference', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { reference } = req.params;
        const validation = TrackCaseSchema.safeParse({ caseReference: reference });

        if (!validation.success) {
            return res.status(400).json({
                error: 'Invalid case reference format',
            });
        }

        const result = await caseService.trackCase(reference);

        if (!result) {
            return res.status(404).json({
                error: 'Case not found',
            });
        }

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to track case', error);
        next(error);
    }
});

/**
 * GET /cases/assigned - Get assigned cases for logged-in leader
 */
router.get('/assigned', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;

        if (!userId) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const result = await caseService.getLeaderCases(userId, page, limit);

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get assigned cases', error);
        next(error);
    }
});

/**
 * GET /cases/escalation-alerts - Get escalation alerts
 */
router.get('/escalation-alerts', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;
        const result = await caseService.getEscalationAlerts(userId);

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get escalation alerts', error);
        next(error);
    }
});

/**
 * GET /cases/metrics - Get performance metrics
 */
router.get('/metrics', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;

        const filters = {
            startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
            endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
            category: req.query.category as string,
            locationId: req.query.locationId as string,
        };

        const result = await caseService.getPerformanceMetrics(userId, filters);

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get metrics', error);
        next(error);
    }
});

/**
 * GET /cases/:id - Get case details
 */
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const result = await caseService.getCaseById(id);

        if (!result) {
            return res.status(404).json({
                error: 'Case not found',
            });
        }

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get case', error);
        next(error);
    }
});

/**
 * GET /cases/leader/:leaderId - Get cases assigned to leader
 */
router.get('/leader/:leaderId', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { leaderId } = req.params;
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;

        const result = await caseService.getLeaderCases(leaderId, page, limit);

        res.json({
            success: true,
            data: result,
        });
    } catch (error) {
        logger.error('Failed to get leader cases', error);
        next(error);
    }
});

/**
 * PATCH /cases/:id - Update case
 */
router.patch('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const validation = UpdateCaseSchema.safeParse(req.body);

        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }

        const userId = (req as any).user?.userId;

        if (!userId) {
            return res.status(401).json({
                error: 'Authentication required',
            });
        }

        const result = await caseService.updateCase(id, validation.data, userId);

        res.json({
            success: true,
            data: result,
            message: 'Case updated successfully',
        });
    } catch (error) {
        logger.error('Failed to update case', error);
        next(error);
    }
});

export const caseController = router;
