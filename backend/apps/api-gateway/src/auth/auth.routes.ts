/**
 * Authentication Routes
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../../../libs/database/prisma.service';
import { generateToken } from '../../../../libs/auth/jwt.service';
import { hashPassword, verifyPassword } from '../../../../libs/auth/password.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';

const logger = createServiceLogger('auth-routes');
const router = Router();

// Validation schemas
const RegisterSchema = z.object({
    phone: z.string().min(10).max(15).optional(),
    email: z.string().email().optional(),
    password: z.string().min(6),
    role: z.enum(['CITIZEN', 'LEADER', 'ADMIN', 'OVERSIGHT', 'NGO']).default('CITIZEN'),
    name: z.string().min(2).optional(),
    nationalId: z.string().length(16).optional(),
    province: z.string().optional(),
    district: z.string().optional(),
    sector: z.string().optional(),
    cell: z.string().optional(),
    village: z.string().optional(),
});

const LoginSchema = z.object({
    identifier: z.string(), // phone or email
    password: z.string(),
});

/**
 * POST /auth/register - Register new user with profile
 */
router.post('/register', async (req: Request, res: Response) => {
    try {
        const validation = RegisterSchema.safeParse(req.body);

        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }

        const { phone, email, password, role, name, nationalId, province, district, sector, cell, village } = validation.data;

        // Check if user exists
        const existing = await prisma.user.findFirst({
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

        // Check if national ID is already registered
        if (nationalId) {
            const existingNationalId = await prisma.citizenProfile.findUnique({
                where: { nationalId },
            });
            if (existingNationalId) {
                return res.status(409).json({ error: 'National ID already registered' });
            }
        }

        // Hash password
        const hashedPassword = await hashPassword(password);

        // Create user with name
        const user = await prisma.user.create({
            data: {
                phone,
                email,
                name,
                password: hashedPassword,
                role,
                status: 'ACTIVE',
            },
        });

        // Create citizen profile with location
        if (role === 'CITIZEN') {
            await prisma.citizenProfile.create({
                data: {
                    userId: user.id,
                    nationalId,
                    protectionLevel: 'ANONYMOUS',
                    country: 'Rwanda',
                    province,
                    district,
                    sector,
                    cell,
                    village,
                },
            });
        }

        // Generate token
        const token = generateToken({
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
                nationalId,
                country: 'Rwanda',
                province,
                district,
                sector,
                cell,
                village,
            },
        });
    } catch (error) {
        logger.error('Registration failed', error);
        res.status(500).json({ error: 'Registration failed' });
    }
});

/**
 * POST /auth/login - User login
 */
router.post('/login', async (req: Request, res: Response) => {
    try {
        const validation = LoginSchema.safeParse(req.body);

        if (!validation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                details: validation.error.errors,
            });
        }

        const { identifier, password } = validation.data;

        // Find user by phone or email WITH profile
        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { phone: identifier },
                    { email: identifier },
                ],
            },
            include: {
                profile: {
                    select: {
                        nationalId: true,
                        country: true,
                        province: true,
                        district: true,
                        sector: true,
                        cell: true,
                        village: true,
                    }
                }
            }
        });

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        if (user.status !== 'ACTIVE') {
            return res.status(403).json({ error: 'Account is not active' });
        }

        // Verify password
        const isValid = await verifyPassword(password, user.password);

        if (!isValid) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Generate token
        const token = generateToken({
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
                createdAt: user.createdAt,
                // Profile location data
                nationalId: user.profile?.nationalId || null,
                country: user.profile?.country || 'Rwanda',
                province: user.profile?.province || null,
                district: user.profile?.district || null,
                sector: user.profile?.sector || null,
                cell: user.profile?.cell || null,
                village: user.profile?.village || null,
            },
        });
    } catch (error) {
        logger.error('Login failed', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

/**
 * GET /auth/me - Get current user with profile
 */
router.get('/me', async (req: Request, res: Response) => {
    const userId = (req as any).user?.userId;

    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    try {
        const user = await prisma.user.findUnique({
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
    } catch (error) {
        res.status(500).json({ error: 'Failed to get user' });
    }
});

export const authRoutes = router;
