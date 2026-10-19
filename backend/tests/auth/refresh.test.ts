import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';

describe('POST /auth/refresh', () => {
  let app: FastifyInstance;
  let validRefreshToken: string;

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

    // Create a test user and get refresh token
    const registerResponse = await app.inject({
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
    validRefreshToken = loginBody.refreshToken;
  });

  it('should refresh tokens with valid refresh token', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: validRefreshToken,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('message', 'Token refreshed successfully');
    expect(body).toHaveProperty('accessToken');
    expect(body).toHaveProperty('refreshToken');
  });

  it('should not refresh with invalid token', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: 'invalid-token',
      },
    });

    expect(response.statusCode).toBe(401);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error', 'Invalid refresh token');
  });

  it('should not refresh with access token', async () => {
    // Get access token
    const loginResponse = await app.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'test@example.com',
        password: 'password123',
      },
    });

    const loginBody = JSON.parse(loginResponse.body);
    const accessToken = loginBody.accessToken;

    const response = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: accessToken,
      },
    });

    expect(response.statusCode).toBe(401);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error', 'Invalid refresh token');
  });

  it('should validate refresh token is provided', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: '',
      },
    });

    expect(response.statusCode).toBe(400);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error');
  });
});
