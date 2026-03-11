import app from './app';
import { config } from '@config/environment';
import { logger } from '@config/logger';
import { prisma } from '@shared/database/prisma.service';

const PORT = config.port ?? 3000;

app.listen(PORT, () => {
  logger.info(`🚀 IMBONI server running on port ${PORT}`);
});

process.on('SIGTERM', async () => {
  logger.info('Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});
