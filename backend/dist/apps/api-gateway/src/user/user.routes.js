"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.userRoutes = void 0;
/**
 * User Routes - Profile management
 */
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const password_service_1 = require("../../../../libs/auth/password.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('user-routes');
const router = (0, express_1.Router)();
// Validation schemas
const UpdateProfileSchema = zod_1.z.object({
    name: zod_1.z.string().min(2).max(100).optional(),
    phone: zod_1.z.string().min(10).max(15).optional(),
    email: zod_1.z.string().email().optional(),
});
const ChangePasswordSchema = zod_1.z.object({
    currentPassword: zod_1.z.string(),
    newPassword: zod_1.z.string().min(6),
});
/**
 * PATCH /user/profile - Update user profile
 */
router.patch('/profile', async (req, res) => {
    const userId = req.user?.userId;
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
            const existing = await prisma_service_1.prisma.user.findFirst({
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
        const user = await prisma_service_1.prisma.user.update({
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
    }
    catch (error) {
        logger.error('Profile update failed', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
});
/**
 * POST /user/change-password - Change password
 */
router.post('/change-password', async (req, res) => {
    const userId = req.user?.userId;
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
        const user = await prisma_service_1.prisma.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Verify current password
        const isValid = await (0, password_service_1.verifyPassword)(currentPassword, user.password);
        if (!isValid) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }
        // Hash new password
        const hashedPassword = await (0, password_service_1.hashPassword)(newPassword);
        await prisma_service_1.prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword },
        });
        logger.info('Password changed', { userId });
        res.json({ success: true, message: 'Password changed successfully' });
    }
    catch (error) {
        logger.error('Password change failed', error);
        res.status(500).json({ error: 'Failed to change password' });
    }
});
exports.userRoutes = router;
//# sourceMappingURL=user.routes.js.map