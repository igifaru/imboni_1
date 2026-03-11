/**
 * Institution Routes
 */
import { Router } from 'express';
import { institutionController } from '../controllers/institution.controller';

const router = Router();

// Institution Types
router.post('/types', institutionController.createType);
router.get('/types', institutionController.getTypes);

// Institutions
router.post('/', institutionController.createInstitution);
router.get('/', institutionController.getInstitutions);
router.get('/:id', institutionController.getInstitutionDetails);

// Branches
router.post('/branches', institutionController.createBranch);
router.get('/:institutionId/branches', institutionController.getBranches);

// Services
router.post('/services', institutionController.createService);
router.get('/:institutionId/services', institutionController.getServices);

// Requests
router.post('/requests', institutionController.submitRequest);
router.get('/my-requests', institutionController.getMyRequests);
router.patch('/requests/:id/status', institutionController.updateRequestStatus);
router.post('/requests/:id/escalate', institutionController.escalateRequest);

export const institutionRoutes = router;
