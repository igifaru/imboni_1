/**
 * Community Controller - REST API Endpoints
 */
import { Router, Request, Response } from 'express';
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

        // Auto-enrollment logic: Enroll based on full profile or leader assignment
        if (channels.length === 0) {
            try {
                // 1. Try Leader Assignment Enrollment first (for Leaders)
                await communityService.enrollLeaderByAssignment(userId);

                // Refresh list
                channels = await communityService.getUserChannels(userId);

                // 2. If still empty, try Citizen Profile Enrollment (fallback for Citizens)
                if (channels.length === 0) {
                    const profile = await prisma.citizenProfile.findUnique({
                        where: { userId },
                    });

                    if (profile) {
                        await communityService.enrollUserByProfile(userId, profile);
                        channels = await communityService.getUserChannels(userId);
                    }
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

// GET /api/community/channels/:channelId/members
router.get('/channels/:channelId/members', async (req: Request, res: Response) => {
    try {
        const { channelId } = req.params;
        const query = req.query.query as string || '';

        const members = await communityService.searchChannelMembers(channelId, query);
        // Transform to return user objects directly
        const users = members.map(m => m.user);
        res.json(users);
    } catch (error) {
        logger.error('Error searching members', error);
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

// POST /api/community/messages/:messageId/react
router.post('/messages/:messageId/react', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { emoji } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!emoji) return res.status(400).json({ error: 'Emoji is required' });

        const updatedMessage = await communityService.toggleReaction(userId, messageId, emoji);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error toggling reaction', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/community/messages/:messageId/pin
router.post('/messages/:messageId/pin', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        // TODO: Add permission check (Leader/Admin only)

        const updatedMessage = await communityService.togglePin(messageId);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error toggling pin', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// PATCH /api/community/messages/:messageId
router.patch('/messages/:messageId', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { content } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!content) return res.status(400).json({ error: 'Content is required' });

        // TODO: Validate user is author
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) return res.status(404).json({ error: 'Message not found' });
        if (message.authorId !== userId) return res.status(403).json({ error: 'Forbidden' });

        const updated = await communityService.updateMessage(messageId, content);
        res.json(updated);
    } catch (error) {
        logger.error('Error updating message', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// DELETE /api/community/messages/:messageId
router.delete('/messages/:messageId', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        // TODO: Validate user is author or mod
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) return res.status(404).json({ error: 'Message not found' });
        if (message.authorId !== userId) return res.status(403).json({ error: 'Forbidden' });

        await communityService.deleteMessage(messageId);
        res.json({ success: true });
    } catch (error) {
        logger.error('Error deleting message', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export const communityController = router;
