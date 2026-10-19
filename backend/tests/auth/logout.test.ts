import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';

describe('POST /auth/logout', () => {
  let app: FastifyInstance;
  let accessToken: string;
  let refreshToken: string;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await database.disconnect();
  });

  beforeEach(async () => {
    await User.deleteMany({});

    // Create a test user and get tokens
    await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Test User',
      },
    });

    const loginResponse = await app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'test@example.com',
        password: 'password123',
      },
    });

    const loginBody = JSON.parse(loginResponse.body);
    accessToken = loginBody.accessToken;
    refreshToken = loginBody.refreshToken;
  });

  it('should logout with valid tokens', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/logout',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        refreshToken,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('message', 'Logged out successfully');
  });

  it('should require authentication', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/logout',
      payload: {
        refreshToken,
      },
    });

    expect(response.statusCode).toBe(401);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error');
  });

  it('should validate refresh token is provided', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/logout',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        refreshToken: '',
      },
    });

    expect(response.statusCode).toBe(400);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error');
  });

  it('should reject invalid access token', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/logout',
      headers: {
        authorization: 'Bearer invalid-token',
      },
      payload: {
        refreshToken,
      },
    });

    expect(response.statusCode).toBe(401);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error');
  });
});
