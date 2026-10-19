import { startServer } from './server';
import { database } from './plugins/database';

startServer().catch(() => {
  console.error('Server startup failed; check local configuration and database availability');
  process.exitCode = 1;
});
// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('📴 SIGTERM received, shutting down gracefully...');
  await database.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('📴 SIGINT received, shutting down gracefully...');
  await database.disconnect();
  process.exit(0);
});
