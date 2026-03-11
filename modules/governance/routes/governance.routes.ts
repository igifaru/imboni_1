import { Router } from 'express';
import { caseController } from '../controllers/case.controller';
import { communityController } from '../controllers/community.controller';
import { pftcvController } from '../controllers/pftcv.controller';
import { authMiddleware } from '@core/auth/auth.middleware';

const router = Router();

// Cases
router.use('/cases', authMiddleware, caseController);

// Community
router.use('/community', authMiddleware, communityController);

// PFTCV (Public Fund Transparency & Citizen Verification)
router.use('/projects', authMiddleware, pftcvController);

export default router;
