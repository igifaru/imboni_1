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
// Validation schema for registering a subordinate
const RegisterSubordinateSchema = zod_1.z.object({
    name: zod_1.z.string().min(2),
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6), // Initial password
    role: zod_1.z.nativeEnum(client_1.UserRole).default(client_1.UserRole.LEADER),
    administrativeUnitId: zod_1.z.string().optional(), // Optional if parent logic determines it
    level: zod_1.z.nativeEnum(client_1.AdministrativeLevel),
    jurisdictionName: zod_1.z.string(), // e.g. "Kigali", "Gasabo", etc.
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
router.post('/register-subordinate', async (req, res) => {
    // Current user (the one trying to register someone)
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
        // 1. Verify Registrar's Jurisdiction and Permissions
        // const registrarAssignment = await prisma.leaderAssignment.findFirst({
        //     where: { userId: registrarId, isActive: true },
        //     include: { administrativeUnit: true }
        // });
        let parentUnitId = null;
        // Logic to determine if registrar can register this level
        if (registrarRole === 'ADMIN') {
            // Admin can register Province Leaders
            if (level !== client_1.AdministrativeLevel.PROVINCE) {
                return res.status(403).json({ error: 'System Admin can only register Province Leaders directly.' });
            }
            // Parent for Province is National (or null in this simplified schema where Admin is top)
            // parentUnitId remains null or we find a "National" unit if it existed.
        }
        else {
            // For other leaders, we need to know their current unit
            const registrarAssignment = await prisma_service_1.prisma.leaderAssignment.findFirst({
                where: { userId: registrarId, isActive: true },
                include: { administrativeUnit: true }
            });
            if (!registrarAssignment) {
                return res.status(403).json({ error: 'You do not have an active leader assignment to perform this action.' });
            }
            const registrarLevel = registrarAssignment.administrativeUnit.level;
            parentUnitId = registrarAssignment.administrativeUnitId;
            // Enforce hierarchy
            const hierarchy = {
                [client_1.AdministrativeLevel.PROVINCE]: client_1.AdministrativeLevel.DISTRICT,
                [client_1.AdministrativeLevel.DISTRICT]: client_1.AdministrativeLevel.SECTOR,
                [client_1.AdministrativeLevel.SECTOR]: client_1.AdministrativeLevel.CELL,
                [client_1.AdministrativeLevel.CELL]: client_1.AdministrativeLevel.VILLAGE,
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
        const targetUnit = await prisma_service_1.prisma.administrativeUnit.upsert({
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
        const hashedPassword = await (0, password_service_1.hashPassword)(password);
        // Check duplicate email
        const existingUser = await prisma_service_1.prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(409).json({ error: 'User with this email already exists' });
        }
        const newUser = await prisma_service_1.prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: role, // Likely LEADER
                status: 'ACTIVE',
            }
        });
        // 4. Create Leader Assignment
        await prisma_service_1.prisma.leaderAssignment.create({
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
router.get('/users', async (req, res) => {
    try {
        const { role, status, search, page = '1', limit = '50' } = req.query;
        const where = {};
        if (role) {
            const roles = String(role).split(',');
            if (roles.length > 1) {
                where.role = { in: roles };
            }
            else {
                where.role = role;
            }
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
        logger.error('Failed to items users', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
/**
 * PATCH /users/:id/status
 * Activate or Deactivate a user.
 */
router.patch('/users/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;
        if (!['ACTIVE', 'INACTIVE'].includes(status)) {
            return res.status(400).json({ error: 'Invalid status. Use ACTIVE or INACTIVE.' });
        }
        const user = await prisma_service_1.prisma.user.update({
            where: { id },
            data: { status },
            select: { id: true, status: true }
        });
        logger.info(`User ${id} status updated to ${status} by ${req.user?.userId}`);
        res.json({ success: true, user });
    }
    catch (error) {
        logger.error('Failed to update user status', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});
/**
 * GET /stats/users-by-province
 * Aggregate user counts by Province and Status
 */
router.get('/stats/users-by-province', jwt_middleware_1.authMiddleware, (0, jwt_middleware_1.roleMiddleware)('ADMIN'), async (req, res) => {
    try {
        const stats = await prisma_service_1.prisma.$queryRaw `
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
        const formattedStats = {};
        stats.forEach(row => {
            const province = row.province;
            const status = row.status; // 'ACTIVE', 'INACTIVE', 'SUSPENDED'
            const count = Number(row.count);
            if (!formattedStats[province]) {
                formattedStats[province] = { active: 0, inactive: 0 };
            }
            if (status === 'ACTIVE') {
                formattedStats[province].active += count;
            }
            else {
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
    }
    catch (error) {
        logger.error('Failed to fetch user stats by province', error);
        res.status(500).json({ error: 'Failed to fetch statistics' });
    }
});
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
/**
 * GET /my-jurisdiction
 * Returns the logged-in leader's assigned province and its districts from data.json
 */
router.get('/my-jurisdiction', jwt_middleware_1.authMiddleware, async (req, res) => {
    const userId = req.user?.userId;
    const userRole = req.user?.role;
    if (!userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }
    try {
        // Find the leader's active assignment
        const assignment = await prisma_service_1.prisma.leaderAssignment.findFirst({
            where: { userId, isActive: true },
            include: {
                administrativeUnit: true
            }
        });
        if (!assignment) {
            // If no assignment, check if user is ADMIN (super admin sees all)
            if (userRole === 'ADMIN') {
                // Return all provinces for super admin
                const rwandaData = await Promise.resolve().then(() => __importStar(require('../data/rwanda-admin.json')));
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
        const rwandaData = await Promise.resolve().then(() => __importStar(require('../data/rwanda-admin.json')));
        const data = rwandaData.default || rwandaData;
        // Map the assignment's jurisdiction name to data.json key
        const provinceKey = provinceMapping[unit.name] || unit.name;
        console.log(`[my-jurisdiction] Unit name: ${unit.name}, Province key: ${provinceKey}`);
        // Get the province data (districts and below)
        const provinceData = data[provinceKey];
        console.log(`[my-jurisdiction] Province data found: ${!!provinceData}`);
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
    }
    catch (error) {
        logger.error('Failed to fetch jurisdiction data', error);
        res.status(500).json({ error: 'Failed to fetch jurisdiction data' });
    }
});
exports.adminRoutes = router;
//# sourceMappingURL=admin.routes.js.map