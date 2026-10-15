import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import { config } from './config';
import { database } from './plugins/database';
import authRoutes from './routes/auth';
import { registerSchema, loginSchema, refreshSchema } from './schemas/auth';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: config.nodeEnv === 'development' ? 'info' : 'warn',
      redact: {
        paths: ['req.headers.authorization', 'req.body.password', 'req.body.token'],
        censor: '[REDACTED]',
      },
    },
  });

  // Register plugins
  await app.register(cors, {
    origin: config.cors.origin,
    credentials: true,
  });

  await app.register(jwt, {
    secret: config.jwt.secret,
    sign: {
      expiresIn: config.jwt.accessExpiresIn,
    },
  });

  await app.register(multipart, {
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB
    },
  });

  // Connect to database
  await database.connect();

  // Register routes
  app.get('/health', async () => {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: database.isConnected() ? 'connected' : 'disconnected',
    };
  });

  // Auth routes with validation
  app.post('/auth/register', {
    schema: {
      body: registerSchema,
    },
    handler: async (request, reply) => {
      const { registerHandler } = await import('./routes/auth');
      return registerHandler(request, reply);
    },
  });

  app.post('/auth/login', {
    schema: {
      body: loginSchema,
    },
    handler: async (request, reply) => {
      const { loginHandler } = await import('./routes/auth');
      return loginHandler(request, reply);
    },
  });

  app.post('/auth/refresh', {
    schema: {
      body: refreshSchema,
    },
    handler: async (request, reply) => {
      const { refreshTokenHandler } = await import('./routes/auth');
      return refreshTokenHandler(request, reply);
    },
  });

  // Error handling
  app.setErrorHandler((error, request, reply) => {
    app.log.error(error);

    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';

    reply.status(statusCode).send({
      error: {
        code: statusCode,
        message: statusCode >= 500 ? 'Internal Server Error' : message,
        ...(config.nodeEnv === 'development' && { details: error.message }),
      },
    });
  });

  return app;
}

export async function startServer(): Promise<void> {
  const app = await buildApp();

  try {
    await app.listen({ port: config.port, host: '0.0.0.0' });
    console.log(`🚀 Server running on port ${config.port}`);
    console.log(`📝 Environment: ${config.nodeEnv}`);
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

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
