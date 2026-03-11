/**
 * Bank Controller - REST API Endpoints for Bank Module
 */
import { NextFunction, Request, Response, Router } from 'express';
import { createServiceLogger } from '../../../../libs/logging/logger.service';
import { bankService } from '../services/bank.service';

const logger = createServiceLogger('bank-controller');
const router = Router();

/**
 * Public/Citizen Endpoints
 */

// Submit a new complaint
router.post('/cases', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;
        const result = await bankService.submitBankCase({
            ...req.body,
            submitterId: userId
        });
        res.status(201).json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Get current user's bank complaints
router.get('/cases/my-cases', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;
        const result = await bankService.getCasesBySubmitter(userId);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Get all active banks
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.getAllBanks();
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Get branches and services for a bank
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.getBankById(req.params.id);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

/**
 * Admin/Bank Staff Endpoints
 */

// Register a new bank (Admin)
router.post('/register', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.createBank(req.body);
        res.status(201).json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Add a branch to a bank
router.post('/:id/branches', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.createBranch(req.params.id, req.body);
        res.status(201).json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Add a service type to a bank
router.post('/:id/services', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.addService(req.params.id, req.body);
        res.status(201).json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Toggle service availability
router.patch('/services/:serviceId', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.toggleService(req.params.serviceId, req.body.enabled);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Update bank case status (Staff)
router.patch('/cases/:caseId/status', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const userId = (req as any).user?.userId;
        const { status, notes } = req.body;
        const result = await bankService.updateCaseStatus(req.params.caseId, status, userId, notes);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Get case details
router.get('/cases/:caseId', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.getCaseDetails(req.params.caseId);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

// Get cases by branch (Branch Staff)
router.get('/branches/:branchId/cases', async (req: Request, res: Response, next: NextFunction) => {
    try {
        const result = await bankService.getCasesByBranch(req.params.branchId);
        res.json({ success: true, data: result });
    } catch (e) {
        next(e);
    }
});

export { router as bankController };
