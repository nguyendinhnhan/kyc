import { requireEditable } from './services/workflow';
import {
  listSubmissionsHandler,
  getSubmissionDetailsHandler,
  approveSubmissionHandler,
  rejectSubmissionHandler,
  getStatsHandler,
} from './routes/admin';
import {
  submitKYCHandler,
  getSubmissionHandler,
  resetSubmissionHandler,
} from './routes/submission';
import { uploadSelfieHandler, getSelfieHandler, getSelfieImageHandler } from './routes/selfie';
import {
  uploadDocumentHandler,
  getDocumentsHandler,
  getDocumentImageHandler,
} from './routes/documents';
import { savePersonalDetailsHandler, getPersonalDetailsHandler } from './routes/user';
import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import { config } from './config';
import { database } from './plugins/database';
import { registerHandler, loginHandler, refreshTokenHandler, logoutHandler } from './routes/auth';
import { RegisterInput, LoginInput, RefreshInput, LogoutInput } from './schemas/auth';
import { PersonalDetailsInput } from './schemas/personalDetails';
import { registerSchema, loginSchema, refreshSchema, logoutSchema } from './schemas/auth';
import { personalDetailsSchema } from './schemas/personalDetails';
import { authenticate } from './middleware/auth';
import { requireAdmin } from './middleware/admin';

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: config.nodeEnv === 'development' ? 'info' : 'warn',
      redact: {
        paths: [
          'req.headers.authorization',
          'req.body.password',
          'req.body.token',
          'req.body.refreshToken',
          'req.body.accessToken',
        ],
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
  app.post<{ Body: RegisterInput }>('/auth/register', {
    schema: {
      body: registerSchema,
    },
    handler: async (request, reply) => {
      return registerHandler(request, reply);
    },
  });

  app.post<{ Body: LoginInput }>('/auth/login', {
    schema: {
      body: loginSchema,
    },
    handler: async (request, reply) => {
      return loginHandler(request, reply);
    },
  });

  app.post<{ Body: RefreshInput }>('/auth/refresh', {
    schema: {
      body: refreshSchema,
    },
    handler: async (request, reply) => {
      return refreshTokenHandler(request, reply);
    },
  });

  app.post<{ Body: LogoutInput }>('/auth/logout', {
    schema: {
      body: logoutSchema,
    },
    preHandler: authenticate,
    handler: async (request, reply) => {
      return logoutHandler(request, reply);
    },
  });

  // User routes (protected)
  app.post<{ Body: PersonalDetailsInput }>('/user/personal-details', {
    schema: {
      body: personalDetailsSchema,
    },
    preHandler: [authenticate, requireEditable],
    handler: async (request, reply) => {
      return savePersonalDetailsHandler(request, reply);
    },
  });

  app.get('/user/personal-details', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getPersonalDetailsHandler(request, reply);
    },
  });

  // Document routes (protected)
  app.post('/user/documents', {
    preHandler: [authenticate, requireEditable],
    handler: async (request, reply) => {
      return uploadDocumentHandler(request, reply);
    },
  });

  app.get('/user/documents', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getDocumentsHandler(request, reply);
    },
  });

  // Selfie routes (protected)
  app.post('/user/selfie', {
    preHandler: [authenticate, requireEditable],
    handler: async (request, reply) => {
      return uploadSelfieHandler(request, reply);
    },
  });

  app.get('/user/selfie', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getSelfieHandler(request, reply);
    },
  });

  app.get('/user/selfie/image', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getSelfieImageHandler(request, reply);
    },
  });

  app.get('/user/documents/:id/image', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getDocumentImageHandler(request, reply);
    },
  });

  // Submission routes (protected)
  app.post('/user/submit', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return submitKYCHandler(request, reply);
    },
  });

  app.get('/user/submission', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return getSubmissionHandler(request, reply);
    },
  });

  app.delete('/user/submission', {
    preHandler: authenticate,
    handler: async (request, reply) => {
      return resetSubmissionHandler(request, reply);
    },
  });

  // Admin routes (protected, admin only)
  app.get('/admin/submissions', {
    preHandler: [authenticate, requireAdmin],
    handler: async (request, reply) => {
      return listSubmissionsHandler(request, reply);
    },
  });

  app.get('/admin/submissions/:id', {
    preHandler: [authenticate, requireAdmin],
    handler: async (request, reply) => {
      return getSubmissionDetailsHandler(request, reply);
    },
  });

  app.post('/admin/submissions/:id/approve', {
    preHandler: [authenticate, requireAdmin],
    handler: async (request, reply) => {
      return approveSubmissionHandler(request, reply);
    },
  });

  app.post('/admin/submissions/:id/reject', {
    preHandler: [authenticate, requireAdmin],
    handler: async (request, reply) => {
      return rejectSubmissionHandler(request, reply);
    },
  });

  app.get('/admin/stats', {
    preHandler: [authenticate, requireAdmin],
    handler: async (request, reply) => {
      return getStatsHandler(request, reply);
    },
  });

  // Error handling
  app.setErrorHandler<{ statusCode?: number; message?: string }>((error, _request, reply) => {
    app.log.error({ code: 'OPERATION_FAILED' }, 'Server operation failed');

    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';

    reply.status(statusCode).send({
      error: statusCode >= 500 ? 'Internal Server Error' : message,
      code: `HTTP_${statusCode}`,
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
    app.log.error({ code: 'OPERATION_FAILED' }, 'Server operation failed');
    process.exit(1);
  }
}
