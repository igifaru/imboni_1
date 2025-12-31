/**
 * Community Controller - REST API Endpoints
 */
import { Router, Request, Response, NextFunction } from 'express';
import { communityService } from '../services/community.service';
import { CreateMessageSchema } from '../dto/community.dto';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { prisma } from '../../../../libs/database/prisma.service';

const logger = createServiceLogger('community-controller');
const router = Router();

// GET /api/community/channels
router.get('/channels', async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        let channels = await communityService.getUserChannels(userId);

        // Auto-enrollment logic: Enroll based on full profile
        if (channels.length === 0) {
            try {
                // 1. Get profile
                const profile = await prisma.citizenProfile.findUnique({
                    where: { userId },
                });

                if (profile) {
                    // 2. Robust Enrollment based on ALL profile fields
                    // This handles partial profiles (e.g. only District) and ensures all units are linked
                    await communityService.enrollUserByProfile(userId, profile);

                    // 3. Refresh channels list immediately so user sees them
                    channels = await communityService.getUserChannels(userId);
                }
            } catch (e) {
                logger.warn('Failed to auto-enroll user', e);
            }
        }

        res.json(channels);
    } catch (error) {
        logger.error('Error fetching channels', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// GET /api/community/channels/:channelId/messages
router.get('/channels/:channelId/messages', async (req: Request, res: Response) => {
    try {
        const { channelId } = req.params;
        const limit = parseInt(req.query.limit as string) || 50;
        const cursor = req.query.cursor as string;

        const messages = await communityService.getChannelMessages(channelId, limit, cursor);
        res.json(messages);
    } catch (error) {
        logger.error('Error fetching messages', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/community/messages
router.post('/messages', async (req: Request, res: Response) => {
    try {
        const validation = CreateMessageSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({ error: 'Validation failed', details: validation.error.errors });
        }

        const userId = (req as any).user?.userId;
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        const message = await communityService.createMessage({
            ...validation.data,
            authorId: userId
        });

        res.status(201).json(message);
    } catch (error) {
        logger.error('Error creating message', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/community/join-category
router.post('/join-category', async (req: Request, res: Response) => {
    try {
        const { unitId, category } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!unitId || !category) return res.status(400).json({ error: 'Unit ID and Category required' });

        const channel = await communityService.joinCategoryChannel(userId, unitId, category);
        res.json(channel);
    } catch (error) {
        logger.error('Error joining category channel', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export const communityController = router;
