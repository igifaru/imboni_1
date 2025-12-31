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

        if (!validation.success) {
            logger.warn('Invalid case creation request', { errors: validation.error.errors });
            return res.status(400).json({
                success: false,
                error: 'Validation failed',
                details: validation.error.errors.map(e => ({
                    field: e.path.join('.'),
                    message: e.message
                }))
            });
        }

        // Get user ID from auth token (may be undefined for anonymous submissions)
        const userId = (req as any).user?.userId;

        // Create case
        const newCase = await caseService.createCase(validation.data, userId);

        logger.info('Case created successfully', { caseReference: newCase.caseReference });

        res.status(201).json({
            success: true,
            data: newCase
        });
    } catch (error: any) {
        logger.error('Failed to create case', { error: error.message });
        next(error);
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
 * GET /cases/my-cases - Get current user's cases
 */
router.get('/my-cases', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;

        if (!userId) {
            return res.status(401).json({
                success: false,
                error: 'Authentication required'
            });
        }

        const limit = parseInt(req.query.limit as string) || 20;
        const offset = parseInt(req.query.offset as string) || 0;
        const status = req.query.status as string;

        const result = await caseService.getUserCases(userId, { limit, offset, status });

        res.json({
            success: true,
            data: {
                cases: result.cases,
                total: result.total
            }
        });
    } catch (error) {
        logger.error('Failed to fetch user cases', error);
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
        const locationId = req.query.locationId as string;

        const result = await caseService.getAllCases(page, limit, search, locationId);
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
 * GET /cases/:id/actions - Get case history/timeline
 * IMPORTANT: This route MUST come before GET /:id to avoid conflicts
 */
router.get('/:id/actions', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const userId = (req as any).user?.userId;

        if (!userId) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const history = await caseService.getCaseHistory(id);

        res.json({
            success: true,
            data: history
        });
    } catch (error) {
        logger.error('Failed to get case actions', error);
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

/**
 * POST /cases/:id/review - Review case (Accept/Reject)
 */
router.post('/:id/review', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { action, notes } = req.body;
        const userId = (req as any).user?.userId;

        if (!['ACCEPT', 'REJECT', 'REQUEST_INFO'].includes(action)) {
            return res.status(400).json({ error: 'Invalid action' });
        }

        const result = await caseService.reviewCase(id, action, userId, notes);

        res.json({
            success: true,
            data: result,
            message: `Case ${action.toLowerCase()}ed successfully`
        });
    } catch (error) {
        logger.error('Failed to review case', error);
        next(error);
    }
});

/**
 * POST /cases/:id/resolve - Resolve case
 */
router.post('/:id/resolve', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { notes } = req.body;
        const userId = (req as any).user?.userId;

        if (!notes) {
            return res.status(400).json({ error: 'Resolution notes are required' });
        }

        const result = await caseService.resolveCase(id, notes, userId);

        res.json({
            success: true,
            data: result,
            message: 'Case resolved successfully'
        });
    } catch (error) {
        logger.error('Failed to resolve case', error);
        next(error);
    }
});


/**
 * POST /cases/:id/escalate - Escalate case to next level
 */
router.post('/:id/escalate', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const userId = (req as any).user?.userId;

        if (!reason) return res.status(400).json({ error: 'Reason required' });

        const result = await caseService.escalateCase(id, reason, userId);

        res.json({
            success: true,
            data: result,
            message: 'Case escalated successfully'
        });
    } catch (error) {
        logger.error('Failed to escalate case', error);
        next(error);
    }
});

/**
 * POST /cases/:id/confirm - Citizen confirms case resolution
 */
router.post('/:id/confirm', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const userId = (req as any).user?.userId;

        if (!userId) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const result = await caseService.citizenConfirmResolution(id, userId);

        res.json({
            success: true,
            data: result,
            message: 'Resolution confirmed. Case is now closed.'
        });
    } catch (error) {
        logger.error('Failed to confirm resolution', error);
        next(error);
    }
});

/**
 * POST /cases/:id/dispute - Citizen disputes resolution, escalates case
 */
router.post('/:id/dispute', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { reason } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        if (!reason) {
            return res.status(400).json({ error: 'Dispute reason required' });
        }

        const result = await caseService.citizenDisputeResolution(id, userId, reason);

        res.json({
            success: true,
            data: result,
            message: 'Resolution disputed. Case escalated to next level.'
        });
    } catch (error) {
        logger.error('Failed to dispute resolution', error);
        next(error);
    }
});

// Import upload middleware
import { uploadMiddleware } from '../middleware/upload.middleware';

/**
 * POST /cases/:id/evidence - Upload evidence file
 */
router.post('/:id/evidence',
    uploadMiddleware.single('file'),
    async (req: Request, res: Response, next: NextFunction) => {
        try {
            const { id } = req.params;
            const file = req.file;

            if (!file) {
                logger.warn('Evidence upload failed: No file received', { caseId: id });
                return res.status(400).json({ error: 'No file provided' });
            }

            logger.info('Received evidence upload', {
                caseId: id,
                fileName: file.filename,
                mimeType: file.mimetype,
                originalName: file.originalname,
                size: file.size
            });

            // Verify case exists
            const caseExists = await caseService.getCaseById(id);
            if (!caseExists) {
                // Clean up uploaded file if case wrong
                // fs.unlinkSync(file.path); 
                return res.status(404).json({ error: 'Case not found' });
            }

            // Construct public URL (assuming static serve setup)
            const publicUrl = `/uploads/evidence/${file.filename}`;

            const evidence = await caseService.addEvidence(id, {
                fileName: file.originalname,
                fileSize: file.size,
                mimeType: file.mimetype,
                path: file.path,
                url: publicUrl
            });

            res.status(201).json({
                success: true,
                data: evidence
            });
        } catch (error) {
            logger.error('Failed to upload evidence', error);
            next(error);
        }
    });

export const caseController = router;
