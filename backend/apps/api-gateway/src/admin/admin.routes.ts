import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../../../../libs/database/prisma.service';
import { hashPassword } from '../../../../libs/auth/password.service';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { UserRole, AdministrativeLevel } from '@prisma/client';
import { authMiddleware, roleMiddleware } from '../auth/jwt.middleware';

const logger = createServiceLogger('admin-routes');
const router = Router();

/**
 * Hierarchy mapping: Registrar Level -> Subordinate Level
 */
const HIERARCHY: Record<string, AdministrativeLevel> = {
    [AdministrativeLevel.NATIONAL]: AdministrativeLevel.PROVINCE,
    [AdministrativeLevel.PROVINCE]: AdministrativeLevel.DISTRICT,
    [AdministrativeLevel.DISTRICT]: AdministrativeLevel.SECTOR,
    [AdministrativeLevel.SECTOR]: AdministrativeLevel.CELL,
    [AdministrativeLevel.CELL]: AdministrativeLevel.VILLAGE,
};

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

// Validation schema for registering a subordinate
const RegisterSubordinateSchema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    password: z.string().min(6), // Initial password
    role: z.nativeEnum(UserRole).default(UserRole.LEADER),
    administrativeUnitId: z.string().optional(),
    level: z.nativeEnum(AdministrativeLevel),
    jurisdictionName: z.string(), // e.g. "Kigali", "Gasabo", etc.
});

/**
 * Find the unit's path in the database to traverse JSON
 */
async function getUnitFullPath(unitId: string) {
    const path = [];
    let currId: string | null = unitId;
    while (currId) {
        const u: any = await prisma.administrativeUnit.findUnique({ where: { id: currId } });
        if (!u) break;
        path.unshift(u);
        currId = u.parentId;
    }
    return path;
}

/**
 * Traverse the JSON data to find current node for a given path of units
 */
function getDataAtUnitPath(path: any[], data: any) {
    let current = data;

    // Follow the path
    for (const unit of path) {
        const key = provinceMapping[unit.name] || unit.name;
        if (current[key]) {
            current = current[key];
        } else {
            return null; // Path not found in JSON
        }
    }
    return current;
}

/**
 * Traverse the JSON data to find children for a given path of units
 */
function getChildrenFromJson(path: any[], data: any) {
    const node = getDataAtUnitPath(path, data);
    if (!node) return [];

    // Return keys (cities/sectors/cells) or values (villages)
    return Array.isArray(node) ? node : Object.keys(node);
}

/**
 * POST /register-subordinate
 * Allows a leader to register a direct subordinate in the hierarchy.
 */
router.post('/register-subordinate', authMiddleware, async (req: Request, res: Response) => {
    const registrarId = (req as any).user?.userId;
    const registrarRole = (req as any).user?.role;

    if (!registrarId) return res.status(401).json({ error: 'Not authenticated' });

    try {
        const validation = RegisterSubordinateSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({ error: 'Validation failed', details: validation.error.errors });
        }

        const { name, email, password, role, level, jurisdictionName } = validation.data;

        // Load Rwanda administrative data
        const rwandaData = await import('../data/rwanda-admin.json');
        const adminJson = rwandaData.default || rwandaData;

        let parentUnitId: string | null = null;
        let registrarLevel: AdministrativeLevel = AdministrativeLevel.NATIONAL;
        let registrarPath: any[] = [];

        if (registrarRole !== 'ADMIN') {
            const assignment = await prisma.leaderAssignment.findFirst({
                where: { userId: registrarId, isActive: true },
                include: { administrativeUnit: true }
            });

            if (!assignment) {
                return res.status(403).json({ error: 'No active leader assignment found.' });
            }

            registrarLevel = assignment.administrativeUnit.level;
            parentUnitId = assignment.administrativeUnitId;
            registrarPath = await getUnitFullPath(parentUnitId);
        }

        // 1. Enforce strict hierarchy
        const allowedChildLevel = HIERARCHY[registrarLevel];
        if (allowedChildLevel !== level) {
            return res.status(403).json({
                error: `A ${registrarLevel} leader can only register a ${allowedChildLevel} leader.`
            });
        }

        // 2. Validate jurisdiction existence in JSON
        const validChildren = getChildrenFromJson(registrarPath, adminJson);
        if (!validChildren.includes(jurisdictionName)) {
            return res.status(400).json({
                error: `Jurisdiction "${jurisdictionName}" is not a valid child of your current assignment.`
            });
        }

        // 3. Check or Create the Administrative Unit
        const parentCodes = registrarPath.map(u => u.name.toUpperCase().replace(/\s+/g, '_'));
        const unitNameCode = jurisdictionName.toUpperCase().replace(/\s+/g, '_');
        const code = [...parentCodes, unitNameCode].join(':');

        const targetUnit = await prisma.administrativeUnit.upsert({
            where: { code },
            update: {},
            create: {
                name: jurisdictionName,
                level: level,
                code: code,
                parentId: parentUnitId,
            }
        });

        // 4. Create the User (Subordinate)
        const hashedPassword = await hashPassword(password);
        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ error: 'User with this email already exists' });
        }

        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role,
                status: 'ACTIVE',
            }
        });

        // 5. Create Leader Assignment
        await prisma.leaderAssignment.create({
            data: {
                userId: newUser.id,
                administrativeUnitId: targetUnit.id,
                positionTitle: `Head of ${jurisdictionName}`,
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
router.get('/users', authMiddleware, async (req: Request, res: Response) => {
    try {
        const { role, status, search, page = '1', limit = '50' } = req.query;

        const where: any = {};
        if (role) {
            const roles = String(role).split(',');
            where.role = roles.length > 1 ? { in: roles } : role;
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
                select: { id: true, name: true, email: true, role: true, status: true, createdAt: true },
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
        logger.error('Failed to fetch users', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * PATCH /users/:id/status
 */
router.patch('/users/:id/status', authMiddleware, async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!['ACTIVE', 'INACTIVE'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status.' });
        }

        const user = await prisma.user.update({
            where: { id },
            data: { status },
            select: { id: true, status: true }
        });

        res.json({ success: true, user });
    } catch (error) {
        logger.error('Failed to update user status', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /stats/users-by-province
 */
router.get('/stats/users-by-province', authMiddleware, roleMiddleware('ADMIN'), async (req, res) => {
    try {
        const stats = await prisma.$queryRaw`
            SELECT cp.province, u.status, COUNT(u.id)::int as count
            FROM citizen_profiles cp
            JOIN users u ON u.id = cp.user_id
            WHERE cp.province IS NOT NULL
            GROUP BY cp.province, u.status;
        `;

        const formattedStats: Record<string, { active: number, inactive: number }> = {};
        (stats as any[]).forEach(row => {
            if (!formattedStats[row.province]) formattedStats[row.province] = { active: 0, inactive: 0 };
            if (row.status === 'ACTIVE') formattedStats[row.province].active += row.count;
            else formattedStats[row.province].inactive += row.count;
        });

        res.json({
            success: true,
            data: Object.entries(formattedStats).map(([province, counts]) => ({ province, ...counts }))
        });
    } catch (error) {
        logger.error('Failed to fetch user stats by province', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});

/**
 * GET /my-jurisdiction
 */
router.get('/my-jurisdiction', authMiddleware, async (req: Request, res: Response) => {
    const userId = (req as any).user?.userId;
    const userRole = (req as any).user?.role;

    try {
        const rwandaData = await import('../data/rwanda-admin.json');
        const adminJson = rwandaData.default || rwandaData;

        if (userRole === 'ADMIN') {
            const provinces = getChildrenFromJson([], adminJson);
            return res.json({
                success: true,
                role: 'ADMIN',
                level: AdministrativeLevel.NATIONAL,
                jurisdiction: 'Rwanda',
                targetLevel: AdministrativeLevel.PROVINCE,
                children: provinces,
                districts: provinces, // Compatibility
                data: adminJson
            });
        }

        const assignment = await prisma.leaderAssignment.findFirst({
            where: { userId, isActive: true },
            include: { administrativeUnit: true }
        });

        if (!assignment) {
            return res.status(404).json({ error: 'No active assignment found' });
        }

        const unit = assignment.administrativeUnit;
        const unitPath = await getUnitFullPath(unit.id);
        const children = getChildrenFromJson(unitPath, adminJson);
        const nodeData = getDataAtUnitPath(unitPath, adminJson);

        res.json({
            success: true,
            role: userRole,
            level: unit.level,
            jurisdiction: unit.name,
            unitId: unit.id,
            targetLevel: HIERARCHY[unit.level],
            children: children,
            districts: children, // Backward compatibility for DistrictCasesWidget
            data: nodeData,      // Raw data for nested counting (sectors etc)
            assignment: { province: unit.name } // Backward compatibility
        });

    } catch (error) {
        logger.error('Failed to fetch jurisdiction data', error);
        res.status(500).json({ error: 'Failed to fetch jurisdiction data' });
    }
});

export const adminRoutes = router;
