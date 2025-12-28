"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRoutes = void 0;
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const password_service_1 = require("../../../../libs/auth/password.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const client_1 = require("@prisma/client");
const jwt_middleware_1 = require("../auth/jwt.middleware");
const logger = (0, logger_service_1.createServiceLogger)('admin-routes');
const router = (0, express_1.Router)();
/**
 * Hierarchy mapping: Registrar Level -> Subordinate Level
 */
const HIERARCHY = {
    [client_1.AdministrativeLevel.NATIONAL]: client_1.AdministrativeLevel.PROVINCE,
    [client_1.AdministrativeLevel.PROVINCE]: client_1.AdministrativeLevel.DISTRICT,
    [client_1.AdministrativeLevel.DISTRICT]: client_1.AdministrativeLevel.SECTOR,
    [client_1.AdministrativeLevel.SECTOR]: client_1.AdministrativeLevel.CELL,
    [client_1.AdministrativeLevel.CELL]: client_1.AdministrativeLevel.VILLAGE,
};
/**
 * Province name mapping: Kinyarwanda -> data.json keys
 */
const provinceMapping = {
    'Kigali': 'Kigali',
    'Amajyaruguru': 'North',
    'Amajyepfo': 'South',
    'Iburasirazuba': 'East',
    'Iburengerazuba': 'West',
};
// Validation schema for registering a subordinate
const RegisterSubordinateSchema = zod_1.z.object({
    name: zod_1.z.string().min(2),
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6), // Initial password
    role: zod_1.z.nativeEnum(client_1.UserRole).default(client_1.UserRole.LEADER),
    administrativeUnitId: zod_1.z.string().optional(),
    level: zod_1.z.nativeEnum(client_1.AdministrativeLevel),
    jurisdictionName: zod_1.z.string(), // e.g. "Kigali", "Gasabo", etc.
});
/**
 * Find the unit's path in the database to traverse JSON
 */
async function getUnitFullPath(unitId) {
    const path = [];
    let currId = unitId;
    while (currId) {
        const u = await prisma_service_1.prisma.administrativeUnit.findUnique({ where: { id: currId } });
        if (!u)
            break;
        path.unshift(u);
        currId = u.parentId;
    }
    return path;
}
/**
 * Traverse the JSON data to find current node for a given path of units
 */
function getDataAtUnitPath(path, data) {
    let current = data;
    // Follow the path
    for (const unit of path) {
        const key = provinceMapping[unit.name] || unit.name;
        if (current[key]) {
            current = current[key];
        }
        else {
            return null; // Path not found in JSON
        }
    }
    return current;
}
/**
 * Traverse the JSON data to find children for a given path of units
 */
function getChildrenFromJson(path, data) {
    const node = getDataAtUnitPath(path, data);
    if (!node)
        return [];
    // Return keys (cities/sectors/cells) or values (villages)
    return Array.isArray(node) ? node : Object.keys(node);
}
/**
 * POST /register-subordinate
 * Allows a leader to register a direct subordinate in the hierarchy.
 */
router.post('/register-subordinate', jwt_middleware_1.authMiddleware, async (req, res) => {
    const registrarId = req.user?.userId;
    const registrarRole = req.user?.role;
    if (!registrarId)
        return res.status(401).json({ error: 'Not authenticated' });
    try {
        const validation = RegisterSubordinateSchema.safeParse(req.body);
        if (!validation.success) {
            return res.status(400).json({ error: 'Validation failed', details: validation.error.errors });
        }
        const { name, email, password, role, level, jurisdictionName } = validation.data;
        // Load Rwanda administrative data
        const rwandaData = await Promise.resolve().then(() => __importStar(require('../data/rwanda-admin.json')));
        const adminJson = rwandaData.default || rwandaData;
        let parentUnitId = null;
        let registrarLevel = client_1.AdministrativeLevel.NATIONAL;
        let registrarPath = [];
        if (registrarRole !== 'ADMIN') {
            const assignment = await prisma_service_1.prisma.leaderAssignment.findFirst({
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
        const targetUnit = await prisma_service_1.prisma.administrativeUnit.upsert({
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
        const hashedPassword = await (0, password_service_1.hashPassword)(password);
        const existingUser = await prisma_service_1.prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ error: 'User with this email already exists' });
        }
        const newUser = await prisma_service_1.prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role,
                status: 'ACTIVE',
            }
        });
        // 5. Create Leader Assignment
        await prisma_service_1.prisma.leaderAssignment.create({
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
    }
    catch (error) {
        logger.error('Failed to register subordinate', error);
        res.status(500).json({ error: 'Internal server error while registering subordinate' });
    }
});
/**
 * GET /users
 * List all users with optional filtering.
 */
router.get('/users', jwt_middleware_1.authMiddleware, async (req, res) => {
    try {
        const { role, status, search, page = '1', limit = '50' } = req.query;
        const where = {};
        if (role) {
            const roles = String(role).split(',');
            where.role = roles.length > 1 ? { in: roles } : role;
        }
        if (status)
            where.status = status;
        if (search) {
            where.OR = [
                { name: { contains: String(search), mode: 'insensitive' } },
                { email: { contains: String(search), mode: 'insensitive' } },
            ];
        }
        const skip = (Number(page) - 1) * Number(limit);
        const [users, total] = await Promise.all([
            prisma_service_1.prisma.user.findMany({
                where,
                select: { id: true, name: true, email: true, role: true, status: true, createdAt: true },
                skip,
                take: Number(limit),
                orderBy: { createdAt: 'desc' }
            }),
            prisma_service_1.prisma.user.count({ where })
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
    }
    catch (error) {
        logger.error('Failed to fetch users', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
/**
 * PATCH /users/:id/status
 */
router.patch('/users/:id/status', jwt_middleware_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!['ACTIVE', 'INACTIVE'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status.' });
        }
        const user = await prisma_service_1.prisma.user.update({
            where: { id },
            data: { status },
            select: { id: true, status: true }
        });
        res.json({ success: true, user });
    }
    catch (error) {
        logger.error('Failed to update user status', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
/**
 * GET /stats/users-by-province
 */
router.get('/stats/users-by-province', jwt_middleware_1.authMiddleware, (0, jwt_middleware_1.roleMiddleware)('ADMIN'), async (req, res) => {
    try {
        const stats = await prisma_service_1.prisma.$queryRaw `
            SELECT cp.province, u.status, COUNT(u.id)::int as count
            FROM citizen_profiles cp
            JOIN users u ON u.id = cp.user_id
            WHERE cp.province IS NOT NULL
            GROUP BY cp.province, u.status;
        `;
        const formattedStats = {};
        stats.forEach(row => {
            if (!formattedStats[row.province])
                formattedStats[row.province] = { active: 0, inactive: 0 };
            if (row.status === 'ACTIVE')
                formattedStats[row.province].active += row.count;
            else
                formattedStats[row.province].inactive += row.count;
        });
        res.json({
            success: true,
            data: Object.entries(formattedStats).map(([province, counts]) => ({ province, ...counts }))
        });
    }
    catch (error) {
        logger.error('Failed to fetch user stats by province', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});
/**
 * GET /my-jurisdiction
 */
router.get('/my-jurisdiction', jwt_middleware_1.authMiddleware, async (req, res) => {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    try {
        const rwandaData = await Promise.resolve().then(() => __importStar(require('../data/rwanda-admin.json')));
        const adminJson = rwandaData.default || rwandaData;
        if (userRole === 'ADMIN') {
            const provinces = getChildrenFromJson([], adminJson);
            return res.json({
                success: true,
                role: 'ADMIN',
                level: client_1.AdministrativeLevel.NATIONAL,
                jurisdiction: 'Rwanda',
                targetLevel: client_1.AdministrativeLevel.PROVINCE,
                children: provinces,
                districts: provinces, // Compatibility
                hierarchyData: adminJson
            });
        }
        const assignment = await prisma_service_1.prisma.leaderAssignment.findFirst({
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
            hierarchyData: nodeData, // Raw data for nested counting (Renamed from 'data' to avoid ApiClient unwrap)
            assignment: { province: unit.name } // Backward compatibility
        });
    }
    catch (error) {
        logger.error('Failed to fetch jurisdiction data', error);
        res.status(500).json({ error: 'Failed to fetch jurisdiction data' });
    }
});
exports.adminRoutes = router;
//# sourceMappingURL=admin.routes.js.map