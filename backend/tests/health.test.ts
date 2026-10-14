import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify, { FastifyInstance } from 'fastify';

describe('Health Check Endpoint', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify();
    
    app.get('/health', async () => {
      return {
        status: 'ok',
        timestamp: new Date().toISOString(),
        database: 'connected',
      };
    });

    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should return 200 status', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
  });

  it('should return status ok', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    const body = JSON.parse(response.body);
    expect(body.status).toBe('ok');
  });

  it('should return timestamp', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    const body = JSON.parse(response.body);
    expect(body.timestamp).toBeDefined();
    expect(() => new Date(body.timestamp)).not.toThrow();
  });

  it('should return database status', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    const body = JSON.parse(response.body);
    expect(body.database).toBeDefined();
    expect(['connected', 'disconnected']).toContain(body.database);
  });
});
