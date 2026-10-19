import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { PersonalDetails } from '../../src/models/PersonalDetails';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';

describe('POST /user/personal-details', () => {
  let app: FastifyInstance;
  let accessToken: string;
  let userId: string;

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
    userId = loginBody.user.id;
  });

  it('should require authentication', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/user/personal-details',
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

    expect(response.statusCode).toBe(401);
  });

  it('should create personal details', async () => {
    const response = await app.inject({
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

    expect(response.statusCode).toBe(201);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('message', 'Personal details saved successfully');
    expect(body).toHaveProperty('personalDetails');
    expect(body.personalDetails).toHaveProperty('dateOfBirth');
    expect(body.personalDetails).toHaveProperty('nationality', 'American');
    expect(body.personalDetails).toHaveProperty('phone');
    expect(body.personalDetails).toHaveProperty('address');
  });

  it('should update existing personal details', async () => {
    // First create
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

    // Then update
    const response = await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1995-05-15',
        nationality: 'Canadian',
        phone: '+9876543210',
        address: {
          street: '456 Oak Ave',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 2T6',
          country: 'Canada',
        },
      },
    });

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('message', 'Personal details updated successfully');
    expect(body.personalDetails.nationality).toBe('Canadian');
  });

  it('should validate required fields', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '',
        nationality: '',
        phone: '',
        address: {
          street: '',
          city: '',
          state: '',
          postalCode: '',
          country: '',
        },
      },
    });

    expect(response.statusCode).toBe(400);
  });

  it('should validate phone number format', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'American',
        phone: 'invalid-phone',
        address: {
          street: '123 Main St',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'USA',
        },
      },
    });

    expect(response.statusCode).toBe(400);
  });
});
