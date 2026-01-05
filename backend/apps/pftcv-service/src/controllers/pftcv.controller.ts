/**
 * PFTCV Controller - REST API Endpoints
 */
import { Router, Request, Response, NextFunction } from 'express';
import { pftcvService } from '../services/pftcv.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('pftcv-controller');
const router = Router();

/**
 * GET /projects - List all projects with filters
 */
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 20;
        const sector = req.query.sector as string;
        const status = req.query.status as string;
        const riskLevel = req.query.riskLevel as string;
        const locationId = req.query.locationId as string;
        const locationName = req.query.locationName as string;
        const locationLevel = req.query.locationLevel as string;
        const search = req.query.search as string;

        const result = await pftcvService.getProjects({
            page, limit, sector, status, riskLevel, locationId, locationName, locationLevel, search
        });

        res.json({ success: true, data: result.projects, meta: { total: result.total, page, limit } });
    } catch (error) {
        logger.error('Failed to fetch projects', error);
        next(error);
    }
});

/**
 * GET /projects/stats - Dashboard statistics
 */
router.get('/stats', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const locationId = req.query.locationId as string;
        const locationName = req.query.locationName as string;
        const locationLevel = req.query.locationLevel as string;
        const result = await pftcvService.getStats(locationId, locationName, locationLevel);
        res.json({ success: true, data: result });
    } catch (error) {
        logger.error('Failed to fetch stats', error);
        next(error);
    }
});

/**
 * GET /projects/:id - Get project details
 */
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const project = await pftcvService.getProjectById(id);

        if (!project) {
            return res.status(404).json({ success: false, error: 'Project not found' });
        }

        res.json({ success: true, data: project });
    } catch (error) {
        logger.error('Failed to fetch project', error);
        next(error);
    }
});

/**
 * POST /projects/:id/verify - Submit citizen verification
 */
router.post('/:id/verify', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const userId = (req as any).user?.userId;
        const { deliveryStatus, completionPercent, qualityRating, comment, isAnonymous, gpsLatitude, gpsLongitude } = req.body;

        if (!deliveryStatus) {
            return res.status(400).json({ success: false, error: 'Delivery status is required' });
        }

        const verification = await pftcvService.submitVerification({
            projectId: id,
            verifierId: isAnonymous ? null : userId,
            isAnonymous: isAnonymous || !userId,
            deliveryStatus,
            completionPercent: completionPercent || 0,
            qualityRating,
            comment,
            gpsLatitude,
            gpsLongitude
        });

        res.status(201).json({ success: true, data: verification, message: 'Verification submitted successfully' });
    } catch (error: any) {
        logger.error('Failed to submit verification', error);
        if (error.message === 'Already verified') {
            return res.status(409).json({ success: false, error: 'You have already verified this project' });
        }
        next(error);
    }
});

/**
 * GET /projects/:id/verifications - Get verifications for a project
 */
router.get('/:id/verifications', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const verifications = await pftcvService.getProjectVerifications(id);
        res.json({ success: true, data: verifications });
    } catch (error) {
        logger.error('Failed to fetch verifications', error);
        next(error);
    }
});

/**
 * POST /projects - Create a new project (Admin only)
 */
router.post('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const project = await pftcvService.createProject(req.body);
        res.status(201).json({ success: true, data: project });
    } catch (error) {
        logger.error('Failed to create project', error);
        next(error);
    }
});

/**
 * POST /projects/:id/releases - Add fund release (Admin only)
 */
router.post('/:id/releases', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const { amount, releaseDate, releaseRef, description } = req.body;

        if (!amount || !releaseDate) {
            return res.status(400).json({ success: false, error: 'Amount and release date are required' });
        }

        const release = await pftcvService.addFundRelease({
            projectId: id,
            amount,
            releaseDate: new Date(releaseDate),
            releaseRef,
            description
        });

        res.status(201).json({ success: true, data: release });
    } catch (error) {
        logger.error('Failed to add fund release', error);
        next(error);
    }
});

export const pftcvController = router;
