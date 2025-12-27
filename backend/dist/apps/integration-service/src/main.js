"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Integration Service - Main Entry Point
 * Connects to government, judiciary, and NGO systems
 */
const express_1 = __importDefault(require("express"));
const app = (0, express_1.default)();
const PORT = process.env.INTEGRATION_SERVICE_PORT || 3005;
app.use(express_1.default.json());
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'integration-service' });
});
// TODO: Import integrations
// import { GovernmentIntegration } from './government';
// import { JudiciaryIntegration } from './judiciary';
app.listen(PORT, () => {
    console.log(`🔗 Integration Service running on port ${PORT}`);
});
exports.default = app;
//# sourceMappingURL=main.js.map