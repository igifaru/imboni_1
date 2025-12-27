/**
 * User Routes - Profile management
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../../../libs/database/prisma.service';
import { hashPassword, verifyPassword } from '../../../../libs/auth/password.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('user-routes');
const router = Router();

// Validation schemas
const UpdateProfileSchema = z.object({
    name: z.string().min(2).max(100).optional(),
    phone: z.string().min(10).max(15).optional(),
    email: z.string().email().optional(),
});

const ChangePasswordSchema = z.object({
    currentPassword: z.string(),
    newPassword: z.string().min(6),
});

/**
 * PATCH /user/profile - Update user profile
 */
router.patch('/profile', async (req: Request, res: Response) => {
    const userId = (req as any).user?.userId;

    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    try {
        const validation = UpdateProfileSchema.safeParse(req.body);

        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }

        const { name, phone, email } = validation.data;

        // Check for duplicates
        if (phone || email) {
            const existing = await prisma.user.findFirst({
                where: {
                    AND: [
                        { id: { not: userId } },
                        {
                            OR: [
                                phone ? { phone } : {},
                                email ? { email } : {},
                            ].filter((o) => Object.keys(o).length > 0),
                        },
                    ],
                },
            });

            if (existing) {
                return res.status(409).json({ error: 'Phone or email already in use' });
            }
        }

        const user = await prisma.user.update({
            where: { id: userId },
            data: {
                ...(name && { name }),
                ...(phone && { phone }),
                ...(email && { email }),
            },
            select: {
                id: true,
                role: true,
                name: true,
                phone: true,
                email: true,
                profilePicture: true,
                status: true,
            },
        });

        logger.info('Profile updated', { userId });

        res.json({ success: true, user });
    } catch (error) {
        logger.error('Profile update failed', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});

/**
 * POST /user/change-password - Change password
 */
router.post('/change-password', async (req: Request, res: Response) => {
    const userId = (req as any).user?.userId;

    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    try {
        const validation = ChangePasswordSchema.safeParse(req.body);

        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }

        const { currentPassword, newPassword } = validation.data;

        // Get current user
        const user = await prisma.user.findUnique({
            where: { id: userId },
        });

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Verify current password
        const isValid = await verifyPassword(currentPassword, user.password);

        if (!isValid) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }

        // Hash new password
        const hashedPassword = await hashPassword(newPassword);

        await prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword },
        });

        logger.info('Password changed', { userId });

        res.json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        logger.error('Password change failed', error);
        res.status(500).json({ error: 'Failed to change password' });
    }
});

export const userRoutes = router;
