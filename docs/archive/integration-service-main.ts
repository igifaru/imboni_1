/**
 * Integration Service - Main Entry Point
 * Connects to government, judiciary, and NGO systems
 */
import express from 'express';

const app = express();
const PORT = process.env.INTEGRATION_SERVICE_PORT || 3005;

app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'integration-service' });
});

// TODO: Import integrations
// import { GovernmentIntegration } from './government';
// import { JudiciaryIntegration } from './judiciary';

app.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`🔗 Integration Service running on port ${PORT}`);
});

export default app;
