import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { PersonalDetails } from '../../src/models/PersonalDetails';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';

describe('GET /user/personal-details', () => {
  let app: FastifyInstance;
  let accessToken: string;

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
    await PersonalDetails.deleteMany({});
    
    // Create a test user and get token
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
  });

  it('should require authentication', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/personal-details',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should return 404 if no personal details exist', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(404);
    
    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('error', 'Personal details not found');
  });

  it('should return personal details', async () => {
    // First create personal details
    await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'American',
        phone: '+1234567890',
        address: {
          street: '123 Main St',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'USA',
        },
      },
    });

    // Then retrieve them
    const response = await app.inject({
      method: 'GET',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);
    
    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('personalDetails');
    expect(body.personalDetails).toHaveProperty('nationality', 'American');
    expect(body.personalDetails).toHaveProperty('phone', '+1234567890');
    expect(body.personalDetails).toHaveProperty('address');
    expect(body.personalDetails.address).toHaveProperty('city', 'New York');
  });
});
