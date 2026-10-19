import { beforeAll, afterAll, describe, it, expect } from 'vitest';
import { buildApp } from '../../src/server';
import { database } from '../../src/plugins/database';
import { User } from '../../src/models/User';
import type { FastifyInstance } from 'fastify';

describe('session rotation and logout', () => {
  let app: FastifyInstance;
  beforeAll(async () => {
    app = await buildApp();
    await User.deleteMany({});
  });
  afterAll(async () => {
    await app.close();
    await database.disconnect();
  });
  async function login() {
    await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'session@example.com',
        password: 'synthetic-password',
        fullName: 'Synthetic User',
      },
    });
    return (
      await app.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'session@example.com',
          password: 'synthetic-password',
        },
      })
    ).json();
  }
  it('consumes each refresh token exactly once, including concurrent requests', async () => {
    const tokens = await login();
    const responses = await Promise.all(
      [1, 2].map(() =>
        app.inject({
          method: 'POST',
          url: '/auth/refresh',
          payload: { refreshToken: tokens.refreshToken },
        })
      )
    );
    expect(responses.map((r) => r.statusCode).sort()).toEqual([200, 401]);
    const rotated = responses.find((r) => r.statusCode === 200)!.json();
    expect(rotated.refreshToken).not.toBe(tokens.refreshToken);
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/auth/refresh',
          payload: {
            refreshToken: rotated.refreshToken,
          },
        })
      ).statusCode
    ).toBe(200);
  });
  it('revokes the session on logout without revoking another login', async () => {
    const first = await login();
    const second = await login();
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/auth/logout',
          headers: { authorization: `Bearer ${first.accessToken}` },
          payload: { refreshToken: first.refreshToken },
        })
      ).statusCode
    ).toBe(200);
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/auth/refresh',
          payload: {
            refreshToken: first.refreshToken,
          },
        })
      ).statusCode
    ).toBe(401);
    expect(
      (
        await app.inject({
          method: 'GET',
          url: '/user/submission',
          headers: { authorization: `Bearer ${first.accessToken}` },
        })
      ).statusCode
    ).toBe(401);
    expect(
      (
        await app.inject({
          method: 'POST',
          url: '/auth/refresh',
          payload: {
            refreshToken: second.refreshToken,
          },
        })
      ).statusCode
    ).toBe(200);
  });
});
