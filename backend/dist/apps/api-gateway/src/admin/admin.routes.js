"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRoutes = void 0;
const express_1 = require("express");
const zod_1 = require("zod");
const prisma_service_1 = require("../../../../libs/database/prisma.service");
const password_service_1 = require("../../../../libs/auth/password.service");
const logger_service_1 = require("../../../../libs/logging/logger.service");
const client_1 = require("@prisma/client");
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
exports.adminRoutes = router;
//# sourceMappingURL=admin.routes.js.map