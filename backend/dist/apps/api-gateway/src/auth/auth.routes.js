"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRoutes = void 0;
/**
 * Authentication Routes
 */
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const jwt_service_1 = require("../../../../libs/auth/jwt.service");
const password_service_1 = require("../../../../libs/auth/password.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const logger = (0, logger_service_1.createServiceLogger)('auth-routes');
const router = (0, express_1.Router)();
// Validation schemas
const RegisterSchema = zod_1.z.object({
    phone: zod_1.z.string().min(10).max(15).optional(),
    email: zod_1.z.string().email().optional(),
    password: zod_1.z.string().min(6),
    role: zod_1.z.enum(['CITIZEN', 'LEADER', 'ADMIN', 'OVERSIGHT', 'NGO']).default('CITIZEN'),
});
const LoginSchema = zod_1.z.object({
    identifier: zod_1.z.string(), // phone or email
    password: zod_1.z.string(),
});
/**
 * POST /auth/register - Register new user
 */
router.post('/register', async (req, res) => {
    try {
        const validation = RegisterSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }
        const { phone, email, password, role } = validation.data;
        // Check if user exists
        const existing = await prisma_service_1.prisma.user.findFirst({
            where: {
                OR: [
                    phone ? { phone } : {},
                    email ? { email } : {},
                ].filter((o) => Object.keys(o).length > 0),
            },
        });
        if (existing) {
            return res.status(409).json({ error: 'User already exists' });
        }
        // Hash password
        const hashedPassword = await (0, password_service_1.hashPassword)(password);
        // Create user
        const user = await prisma_service_1.prisma.user.create({
            data: {
                phone,
                email,
                password: hashedPassword,
                role,
                status: 'ACTIVE',
            },
        });
        // Create citizen profile
        if (role === 'CITIZEN') {
            await prisma_service_1.prisma.citizenProfile.create({
                data: {
                    userId: user.id,
                    protectionLevel: 'ANONYMOUS',
                },
            });
        }
        // Generate token
        const token = (0, jwt_service_1.generateToken)({
            userId: user.id,
            role: user.role,
            email: user.email || undefined,
            phone: user.phone || undefined,
        });
        logger.info('User registered', { userId: user.id, role: user.role });
        res.status(201).json({
            success: true,
            token,
            user: {
                id: user.id,
                role: user.role,
                name: user.name,
                phone: user.phone,
                email: user.email,
                profilePicture: user.profilePicture,
                status: user.status,
            },
        });
    }
    catch (error) {
        logger.error('Registration failed', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});
/**
 * POST /auth/login - User login
 */
router.post('/login', async (req, res) => {
    try {
        const validation = LoginSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }
        const { identifier, password } = validation.data;
        // Find user by phone or email
        const user = await prisma_service_1.prisma.user.findFirst({
            where: {
                OR: [
                    { phone: identifier },
                    { email: identifier },
                ],
            },
        });
        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        if (user.status !== 'ACTIVE') {
            return res.status(403).json({ error: 'Account is not active' });
        }
        // Verify password
        const isValid = await (0, password_service_1.verifyPassword)(password, user.password);
        if (!isValid) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        // Generate token
        const token = (0, jwt_service_1.generateToken)({
            userId: user.id,
            role: user.role,
            email: user.email || undefined,
            phone: user.phone || undefined,
        });
        logger.info('User logged in', { userId: user.id });
        res.json({
            success: true,
            token,
            user: {
                id: user.id,
                role: user.role,
                name: user.name,
                phone: user.phone,
                email: user.email,
                profilePicture: user.profilePicture,
                status: user.status,
            },
        });
    }
    catch (error) {
        logger.error('Login failed', error);
        res.status(500).json({ error: 'Login failed' });
    }
});
/**
 * GET /auth/me - Get current user with profile
 */
router.get('/me', async (req, res) => {
    const userId = req.user?.userId;
    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }
    try {
        const user = await prisma_service_1.prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                role: true,
                name: true,
                phone: true,
                email: true,
                profilePicture: true,
                status: true,
                createdAt: true,
                profile: {
                    select: {
                        nationalId: true,
                        country: true,
                        province: true,
                        district: true,
                        sector: true,
                        cell: true,
                        village: true,
                    },
                },
            },
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        // Flatten the response to include profile fields at top level
        res.json({
            success: true,
            user: {
                ...user,
                nationalId: user.profile?.nationalId || null,
                country: user.profile?.country || 'Rwanda',
                province: user.profile?.province || null,
                district: user.profile?.district || null,
                sector: user.profile?.sector || null,
                cell: user.profile?.cell || null,
                village: user.profile?.village || null,
                profile: undefined,
            },
        });
    }
    catch (error) {
        res.status(500).json({ error: 'Failed to get user' });
    }
});
exports.authRoutes = router;
//# sourceMappingURL=auth.routes.js.map