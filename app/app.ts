import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { rateLimitMiddleware } from '@shared/middleware/rate-limit.middleware';
import { errorMiddleware } from '@shared/middleware/error.middleware';
import { registerRoutes } from './routes';

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(rateLimitMiddleware);

registerRoutes(app);
app.use(errorMiddleware);

export default app;
