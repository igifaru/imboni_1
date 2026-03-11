/**
 * Community Controller - REST API Endpoints
 */
import { Router, Request, Response } from 'express';
import { communityService } from '../services/community.service';
import { CreateMessageSchema } from '../dto/community.dto';
import { createServiceLogger } from '@shared/helpers/logging/logger.service';
import { prisma } from '@shared/database/prisma.service';

const logger = createServiceLogger('community-controller');
const router = Router();

// GET /api/community/channels
router.get('/channels', async (req: Request, res: Response) => {
    try {
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        let channels = await communityService.getUserChannels(userId);

        if (channels.length < 6 || req.query.refresh === 'true') {
            try {
                // 1. Try Leader Assignment Enrollment first (for Leaders)
                await communityService.enrollLeaderByAssignment(userId);

                // 2. Try Citizen Profile Enrollment
                // We check profile even if leader enrollment happened, to ensure dual-citizenship scenarios (leader + resident) cover all bases
                const profile = await prisma.citizenProfile.findUnique({
                    where: { userId },
                });

                if (profile) {
                    await communityService.enrollUserByProfile(userId, profile);
                }

                // Refresh list after attempts
                channels = await communityService.getUserChannels(userId);
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
        if (!userId) return res.status(401).json({ error: 'Unauthorized' });

        // Permission Check: Leader or Admin only
        const role = (req as any).user?.role;
        if (role !== 'LEADER' && role !== 'ADMIN') {
            return res.status(403).json({ error: 'Forbidden. Only leaders can pin messages.' });
        }

        const updatedMessage = await communityService.togglePin(messageId);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error toggling pin', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/community/messages/:messageId/poll-vote
router.post('/messages/:messageId/poll-vote', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { attachmentId, votes } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!attachmentId || votes === undefined) return res.status(400).json({ error: 'Attachment ID and votes required' });

        const updatedMessage = await communityService.voteOnPoll(userId, messageId, attachmentId, votes);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error voting on poll', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/community/messages/:messageId/list-entry
router.post('/messages/:messageId/list-entry', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { attachmentId, data } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!attachmentId || !data) return res.status(400).json({ error: 'Attachment ID and entry data required' });

        const updatedMessage = await communityService.addListEntry(userId, messageId, attachmentId, data);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error adding list entry', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// PATCH /api/community/messages/:messageId/list-entry
router.patch('/messages/:messageId/list-entry', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { attachmentId, entryIndex, data } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!attachmentId || entryIndex === undefined || !data) {
            return res.status(400).json({ error: 'Attachment ID, entryIndex, and data required' });
        }

        const updatedMessage = await communityService.editListEntry(userId, messageId, attachmentId, entryIndex, data);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error editing list entry', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// PATCH /api/community/messages/:messageId/list-metadata
router.patch('/messages/:messageId/list-metadata', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { attachmentId, title, columns } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!attachmentId || (!title && !columns)) {
            return res.status(400).json({ error: 'Attachment ID and either title or columns required' });
        }

        const updatedMessage = await communityService.updateCollaborativeList(userId, messageId, attachmentId, title, columns);
        res.json(updatedMessage);
    } catch (error) {
        logger.error('Error updating list metadata', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// PATCH /api/community/messages/:messageId
router.patch('/messages/:messageId', async (req: Request, res: Response) => {
    try {
        const { messageId } = req.params;
        const { content, attachments } = req.body;
        const userId = (req as any).user?.userId;

        if (!userId) return res.status(401).json({ error: 'Unauthorized' });
        if (!content && !attachments) return res.status(400).json({ error: 'Content or attachments required' });

        // Validate user is author

        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });
        if (!message) return res.status(404).json({ error: 'Message not found' });
        if (message.authorId !== userId) return res.status(403).json({ error: 'Forbidden' });

        const updated = await communityService.updateMessage(messageId, content ?? message.content, attachments);
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

        // Permission check: Author OR Mod
        const role = (req as any).user?.role;
        const message = await prisma.channelMessage.findUnique({ where: { id: messageId } });

        if (!message) return res.status(404).json({ error: 'Message not found' });

        // Strict: Only Author can delete for now, unless Mod check is robust
        // Assuming role 'MODERATOR' exists based on ChannelRole enum, but this is system role.
        // Let's stick to Author for MVP safety unless "admin" system role.

        const isAuthor = message.authorId === userId;
        const isAdmin = role === 'ADMIN' || role === 'LEADER'; // Assuming these roles based on context

        if (!isAuthor && !isAdmin) return res.status(403).json({ error: 'Forbidden' });

        await communityService.deleteMessage(messageId);
        res.json({ success: true });
    } catch (error) {
        logger.error('Error deleting message', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

export const communityController = router;
