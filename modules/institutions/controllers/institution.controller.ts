/**
 * Institution Controller - Request Handling
 */
import { Request, Response } from 'express';
import { institutionService } from '../services/institution.service';

export class InstitutionController {
    // Institution Types
    async createType(req: Request, res: Response) {
        try {
            const result = await institutionService.registerInstitutionType(req.body.name, req.body.description);
            res.status(201).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async getTypes(req: Request, res: Response) {
        const types = await institutionService.getInstitutionTypes();
        res.json(types);
    }

    // Institutions
    async createInstitution(req: Request, res: Response) {
        try {
            const result = await institutionService.registerInstitution(req.body);
            res.status(201).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async getInstitutions(req: Request, res: Response) {
        const typeId = req.query.typeId as string;
        const list = await institutionService.getInstitutions(typeId);
        res.json(list);
    }

    async getInstitutionDetails(req: Request, res: Response) {
        const details = await institutionService.getInstitutionDetails(req.params.id);
        if (!details) return res.status(404).json({ error: 'Institution not found' });
        res.json(details);
    }

    // Branches & Services
    async createBranch(req: Request, res: Response) {
        try {
            const result = await institutionService.addBranch(req.body);
            res.status(201).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async getBranches(req: Request, res: Response) {
        const list = await institutionService.getBranches(req.params.institutionId);
        res.json(list);
    }

    async createService(req: Request, res: Response) {
        try {
            const result = await institutionService.addService(req.body);
            res.status(201).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async getServices(req: Request, res: Response) {
        const list = await institutionService.getServices(req.params.institutionId);
        res.json(list);
    }

    // Requests
    async submitRequest(req: Request, res: Response) {
        try {
            // @ts-ignore - Assuming user ID is attached by auth middleware
            const citizenId = req.user.id;
            const result = await institutionService.submitRequest(citizenId, req.body);
            res.status(201).json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async getMyRequests(req: Request, res: Response) {
        // @ts-ignore
        const citizenId = req.user.id;
        const list = await institutionService.getCitizenRequests(citizenId);
        res.json(list);
    }

    async updateRequestStatus(req: Request, res: Response) {
        try {
            const result = await institutionService.updateRequestStatus(req.params.id, req.body.status, req.body.notes);
            res.json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }

    async escalateRequest(req: Request, res: Response) {
        try {
            const result = await institutionService.escalateRequest(
                req.params.id,
                req.body.fromRole,
                req.body.toRole,
                req.body.reason
            );
            res.json(result);
        } catch (error: any) {
            res.status(400).json({ error: error.message });
        }
    }
}

export const institutionController = new InstitutionController();
