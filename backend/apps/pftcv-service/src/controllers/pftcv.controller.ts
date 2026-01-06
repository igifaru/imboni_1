/**
 * PFTCV Controller - REST API Endpoints
 */
import { Router, Request, Response, NextFunction } from 'express';
import { pftcvService } from '../services/pftcv.service';
import { uploadMiddleware } from '../middleware/upload.middleware';
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
        const { deliveryStatus, completionPercent, qualityRating, comment, isAnonymous, gpsLatitude, gpsLongitude, evidence } = req.body;

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
            gpsLongitude,
            evidence
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
 * PATCH /projects/:id/verify - Update citizen verification
 */
router.patch('/:id/verify', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const { id } = req.params;
        const userId = (req as any).user?.userId;
        const { deliveryStatus, completionPercent, qualityRating, comment, isAnonymous, gpsLatitude, gpsLongitude, evidence } = req.body;

        const verification = await pftcvService.updateVerification({
            projectId: id,
            verifierId: userId, // Must be logged in to update, or handle anonymous cookie logic if applicable (assume logged for edit)
            isAnonymous: isAnonymous,
            deliveryStatus,
            completionPercent: completionPercent || 0,
            qualityRating,
            comment,
            gpsLatitude,
            gpsLongitude,
            evidence
        });

        res.json({ success: true, data: verification, message: 'Verification updated successfully' });
    } catch (error: any) {
        logger.error('Failed to update verification', error);
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

/**
 * POST /projects/upload - Upload evidence file
 */
router.post('/upload',
    uploadMiddleware.single('file'),
    async (req: Request, res: Response, next: NextFunction) => {
        try {
            const file = req.file;

            if (!file) {
                return res.status(400).json({ success: false, error: 'No file provided' });
            }

            // Construct public URL
            const publicUrl = `/uploads/pftcv-evidence/${file.filename}`;

            logger.info('File uploaded', {
                filename: file.filename,
                mimetype: file.mimetype,
                size: file.size
            });

            // Determine type based on mime type or extension fallback
            let type: 'IMAGE' | 'VIDEO' | 'AUDIO' | 'DOCUMENT' = 'DOCUMENT';

            if (file.mimetype.startsWith('image/')) type = 'IMAGE';
            else if (file.mimetype.startsWith('video/')) type = 'VIDEO';
            else if (file.mimetype.startsWith('audio/')) type = 'AUDIO';
            else {
                // Fallback to extension check
                const ext = file.originalname.split('.').pop()?.toLowerCase();
                if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].includes(ext || '')) type = 'IMAGE';
                else if (['mp4', 'webm', 'mov', 'avi', 'mkv', '3gp'].includes(ext || '')) type = 'VIDEO';
                else if (['mp3', 'wav', 'ogg', 'm4a', 'aac'].includes(ext || '')) type = 'AUDIO';
            }

            res.status(201).json({
                success: true,
                data: {
                    url: publicUrl,
                    fileName: file.originalname,
                    mimeType: file.mimetype,
                    fileSize: file.size,
                    type: type
                }
            });
        } catch (error) {
            logger.error('Failed to upload evidence', error);
            next(error);
        }
    });

export const pftcvController = router;
