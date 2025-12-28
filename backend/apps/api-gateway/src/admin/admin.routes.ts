import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../../../libs/database/prisma.service';
import { hashPassword } from '../../../../libs/auth/password.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { UserRole, AdministrativeLevel } from '@prisma/client';
import { authMiddleware, roleMiddleware } from '../auth/jwt.middleware';

const logger = createServiceLogger('admin-routes');
const router = Router();

// Validation schema for registering a subordinate
const RegisterSubordinateSchema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    password: z.string().min(6), // Initial password
    role: z.nativeEnum(UserRole).default(UserRole.LEADER),
    administrativeUnitId: z.string().optional(), // Optional if parent logic determines it
    level: z.nativeEnum(AdministrativeLevel),
    jurisdictionName: z.string(), // e.g. "Kigali", "Gasabo", etc.
});

/**
 * POST /register-subordinate
 * Allows a leader to register a direct subordinate in the hierarchy.
 * Rules:
 * - Admin -> Province Leader
 * - Province Leader -> District Leader (Mayor)
 * - District Leader -> Sector Leader
 * - Sector Leader -> Cell Leader
 * - Cell Leader -> Village Leader
 */
router.post('/register-subordinate', async (req: Request, res: Response) => {
    // Current user (the one trying to register someone)
    const registrarId = (req as any).user?.userId;
    const registrarRole = (req as any).user?.role;

    if (!registrarId) return res.status(401).json({ error: 'Not authenticated' });

    try {
        const validation = RegisterSubordinateSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({ error: 'Validation failed', details: validation.error.errors });
        }

        const { name, email, password, role, level, jurisdictionName } = validation.data;

        // 1. Verify Registrar's Jurisdiction and Permissions
        // const registrarAssignment = await prisma.leaderAssignment.findFirst({
        //     where: { userId: registrarId, isActive: true },
        //     include: { administrativeUnit: true }
        // });

        let parentUnitId: string | null = null;

        // Logic to determine if registrar can register this level
        if (registrarRole === 'ADMIN') {
            // Admin can register Province Leaders
            if (level !== AdministrativeLevel.PROVINCE) {
                return res.status(403).json({ error: 'System Admin can only register Province Leaders directly.' });
            }
            // Parent for Province is National (or null in this simplified schema where Admin is top)
            // parentUnitId remains null or we find a "National" unit if it existed.
        } else {
            // For other leaders, we need to know their current unit
            const registrarAssignment = await prisma.leaderAssignment.findFirst({
                where: { userId: registrarId, isActive: true },
                include: { administrativeUnit: true }
            });

            if (!registrarAssignment) {
                return res.status(403).json({ error: 'You do not have an active leader assignment to perform this action.' });
            }

            const registrarLevel = registrarAssignment.administrativeUnit.level;
            parentUnitId = registrarAssignment.administrativeUnitId;

            // Enforce hierarchy
            const hierarchy: Record<string, AdministrativeLevel> = {
                [AdministrativeLevel.PROVINCE]: AdministrativeLevel.DISTRICT,
                [AdministrativeLevel.DISTRICT]: AdministrativeLevel.SECTOR,
                [AdministrativeLevel.SECTOR]: AdministrativeLevel.CELL,
                [AdministrativeLevel.CELL]: AdministrativeLevel.VILLAGE,
            };

            const allowedChildLevel = hierarchy[registrarLevel];

            if (allowedChildLevel !== level) {
                return res.status(403).json({
                    error: `A ${registrarLevel} leader can only register a ${allowedChildLevel} leader. You are trying to register a ${level}.`
                });
            }
        }

        // 2. Check or Create the Administrative Unit
        // For provinces, we seeded them. For others, we might need to create them if they don't exist.
        // We expect the user to provide the NAME of the unit (e.g., "Kigali", "Gasabo").
        // We should check if it exists under the parent.

        // Note: For simplified MVP, we assume the unit might simply be created if not found, 
        // OR we enforce it must exist. Let's try to upsert it for flexibility, 
        // ensuring it's linked to the parent.

        // Generate a code (simple slug)
        const code = jurisdictionName.toUpperCase().replace(/\s+/g, '_');

        const targetUnit = await prisma.administrativeUnit.upsert({
            where: { code }, // Assuming codes are unique globally for now (or composite unique in reality)
            update: {},
            create: {
                name: jurisdictionName,
                level: level,
                code: code,
                parentId: parentUnitId, // Link to the registrar's unit
            }
        });

        // Verify parent link correctness (if unit existed, ensure it belongs to this parent)
        if (parentUnitId && targetUnit.parentId !== parentUnitId) {
            // If we really want to be strict. For now, let's warn or fail.
            // If unit exists but has different parent, that's a data consistency issue or collision.
        }


        // 3. Create the User (Subordinate)
        const hashedPassword = await hashPassword(password);

        // Check duplicate email
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ error: 'User with this email already exists' });
        }

        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role, // Likely LEADER
                status: 'ACTIVE',
            }
        });

        // 4. Create Leader Assignment
        await prisma.leaderAssignment.create({
            data: {
                userId: newUser.id,
                administrativeUnitId: targetUnit.id,
                positionTitle: `Head of ${jurisdictionName}`, // Default title
                startDate: new Date(),
                isActive: true
            }
        });

        logger.info(`Registered subordinate ${newUser.email} for ${jurisdictionName} by ${registrarId}`);

        res.json({
            success: true,
            user: {
                id: newUser.id,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role
            },
            unit: targetUnit
        });

    } catch (error) {
        logger.error('Failed to register subordinate', error);
        res.status(500).json({ error: 'Internal server error while registering subordinate' });
    }
});

/**
 * GET /users
 * List all users with optional filtering.
 */
router.get('/users', async (req: Request, res: Response) => {
    try {
        const { role, status, search, page = '1', limit = '50' } = req.query;

        const where: any = {};

        if (role) {
            const roles = String(role).split(',');
            if (roles.length > 1) {
                where.role = { in: roles };
            } else {
                where.role = role;
            }
        }
        if (status) where.status = status;

        if (search) {
            where.OR = [
                { name: { contains: String(search), mode: 'insensitive' } },
                { email: { contains: String(search), mode: 'insensitive' } },
            ];
        }

        const skip = (Number(page) - 1) * Number(limit);

        const [users, total] = await Promise.all([
            prisma.user.findMany({
                where,
                select: {
                    id: true,
                    name: true,
                    email: true,
                    role: true,
                    status: true,
                    createdAt: true
                },
                skip,
                take: Number(limit),
                orderBy: { createdAt: 'desc' }
            }),
            prisma.user.count({ where })
        ]);

        res.json({
            data: users,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                pages: Math.ceil(total / Number(limit))
            }
        });
    } catch (error) {
        logger.error('Failed to items users', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * PATCH /users/:id/status
 * Activate or Deactivate a user.
 */
router.patch('/users/:id/status', async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!['ACTIVE', 'INACTIVE'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status. Use ACTIVE or INACTIVE.' });
        }

        const user = await prisma.user.update({
            where: { id },
            data: { status },
            select: { id: true, status: true }
        });

        logger.info(`User ${id} status updated to ${status} by ${(req as any).user?.userId}`);
        res.json({ success: true, user });
    } catch (error) {
        logger.error('Failed to update user status', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /stats/users-by-province
 * Aggregate user counts by Province and Status
 */
router.get('/stats/users-by-province', authMiddleware, roleMiddleware('ADMIN'), async (req, res) => {
    try {
        const stats = await prisma.$queryRaw`
            SELECT 
                cp.province,
                u.status,
                COUNT(u.id)::int as count
            FROM citizen_profiles cp
            JOIN users u ON u.id = cp.user_id
            WHERE cp.province IS NOT NULL
            GROUP BY cp.province, u.status
            ORDER BY cp.province ASC;
        `;

        // Process data into a reliable format { province: string, active: number, inactive: number }
        const formattedStats: Record<string, { active: number, inactive: number }> = {};

        (stats as any[]).forEach(row => {
            const province = row.province;
            const status = row.status as string; // 'ACTIVE', 'INACTIVE', 'SUSPENDED'
            const count = Number(row.count);

            if (!formattedStats[province]) {
                formattedStats[province] = { active: 0, inactive: 0 };
            }

            if (status === 'ACTIVE') {
                formattedStats[province].active += count;
            } else {
                formattedStats[province].inactive += count;
            }
        });

        const result = Object.entries(formattedStats).map(([province, counts]) => ({
            province,
            ...counts
        }));

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        logger.error('Failed to fetch user stats by province', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});

/**
 * Province name mapping: Kinyarwanda -> data.json keys
 */
const provinceMapping: Record<string, string> = {
    'Kigali': 'Kigali',
    'Amajyaruguru': 'North',
    'Amajyepfo': 'South',
    'Iburasirazuba': 'East',
    'Iburengerazuba': 'West',
};

/**
 * GET /my-jurisdiction
 * Returns the logged-in leader's assigned province and its districts from data.json
 */
router.get('/my-jurisdiction', authMiddleware, async (req: Request, res: Response) => {
    const userId = (req as any).user?.userId;
    const userRole = (req as any).user?.role;

    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }

    try {
        // Find the leader's active assignment
        const assignment = await prisma.leaderAssignment.findFirst({
            where: { userId, isActive: true },
            include: {
                administrativeUnit: true
            }
        });

        if (!assignment) {
            // If no assignment, check if user is ADMIN (super admin sees all)
            if (userRole === 'ADMIN') {
                // Return all provinces for super admin
                const rwandaData = await import('../data/rwanda-admin.json');
                return res.json({
                    success: true,
                    role: 'ADMIN',
                    provinces: Object.keys(rwandaData.default || rwandaData),
                    data: rwandaData.default || rwandaData
                });
            }
            return res.status(404).json({ error: 'No active assignment found for this user' });
        }

        const unit = assignment.administrativeUnit;

        // Load Rwanda administrative data
        const rwandaData = await import('../data/rwanda-admin.json');
        const data = rwandaData.default || rwandaData;

        // Map the assignment's jurisdiction name to data.json key
        const provinceKey = provinceMapping[unit.name] || unit.name;

        // Get the province data (districts and below)
        const provinceData = data[provinceKey as keyof typeof data];

        if (!provinceData) {
            return res.status(404).json({
                error: `Province "${unit.name}" not found in administrative data`,
                mappedKey: provinceKey
            });
        }

        res.json({
            success: true,
            assignment: {
                province: unit.name,
                provinceKey,
                level: unit.level,
                unitId: unit.id
            },
            districts: Object.keys(provinceData),
            data: provinceData
        });

    } catch (error) {
        logger.error('Failed to fetch jurisdiction data', error);
        res.status(500).json({ error: 'Failed to fetch jurisdiction data' });
    }
});

export const adminRoutes = router;
