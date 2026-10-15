import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { PersonalDetails } from '../../src/models/PersonalDetails';
import { DocumentModel } from '../../src/models/Document';
import { SelfieModel } from '../../src/models/Selfie';
import { SubmissionModel } from '../../src/models/Submission';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';

describe('POST /user/submit', () => {
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
    await DocumentModel.deleteMany({});
    await SelfieModel.deleteMany({});
    await SubmissionModel.deleteMany({});
    
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

    const body = JSON.parse(loginResponse.body);
    accessToken = body.accessToken;
  });

  it('should require authentication', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/user/submit',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should require personal details', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/user/submit',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error).toContain('Personal details');
  });

  it('should require at least one document', async () => {
    // Add personal details
    await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'US',
        phone: '+1234567890',
        address: {
          street: '123 Test St',
          city: 'Test City',
          state: 'TS',
          postalCode: '12345',
          country: 'US',
        },
      },
    });

    const response = await app.inject({
      method: 'POST',
      url: '/user/submit',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error).toContain('document');
  });

  it('should require selfie', async () => {
    // Add personal details
    await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'US',
        phone: '+1234567890',
        address: {
          street: '123 Test St',
          city: 'Test City',
          state: 'TS',
          postalCode: '12345',
          country: 'US',
        },
      },
    });

    // Add document
    const fakeImage = Buffer.from('fake-image-data');
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const docBody = [
      `--${boundary}`,
      'Content-Disposition: form-data; name="file"; filename="doc.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage.toString('binary'),
      `--${boundary}`,
      'Content-Disposition: form-data; name="type"',
      '',
      'passport',
      `--${boundary}`,
      'Content-Disposition: form-data; name="documentNumber"',
      '',
      'AB123456',
      `--${boundary}--`,
      '',
    ].join('\r\n');

    await app.inject({
      method: 'POST',
      url: '/user/documents',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.from(docBody, 'binary'),
    });

    const response = await app.inject({
      method: 'POST',
      url: '/user/submit',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error.toLowerCase()).toContain('selfie');
  });

  it('should submit successfully when all requirements are met', async () => {
    // Add personal details
    await app.inject({
      method: 'POST',
      url: '/user/personal-details',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
      payload: {
        dateOfBirth: '1990-01-01',
        nationality: 'US',
        phone: '+1234567890',
        address: {
          street: '123 Test St',
          city: 'Test City',
          state: 'TS',
          postalCode: '12345',
          country: 'US',
        },
      },
    });

    // Add document
    const fakeImage = Buffer.from('fake-image-data');
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const docBody = [
      `--${boundary}`,
      'Content-Disposition: form-data; name="file"; filename="doc.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage.toString('binary'),
      `--${boundary}`,
      'Content-Disposition: form-data; name="type"',
      '',
      'passport',
      `--${boundary}`,
      'Content-Disposition: form-data; name="documentNumber"',
      '',
      'AB123456',
      `--${boundary}--`,
      '',
    ].join('\r\n');

    await app.inject({
      method: 'POST',
      url: '/user/documents',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.from(docBody, 'binary'),
    });

    // Add selfie
    const selfieBoundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const selfieBody = [
      `--${selfieBoundary}`,
      'Content-Disposition: form-data; name="file"; filename="selfie.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage.toString('binary'),
      `--${selfieBoundary}--`,
      '',
    ].join('\r\n');

    await app.inject({
      method: 'POST',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${selfieBoundary}`,
      },
      payload: Buffer.from(selfieBody, 'binary'),
    });

    // Submit
    const response = await app.inject({
      method: 'POST',
      url: '/user/submit',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.message).toBe('KYC submitted successfully');
    expect(body.submission).toBeDefined();
    expect(body.submission.status).toBe('submitted');
    expect(body.submission.submittedAt).toBeDefined();
  });
});

describe('GET /user/submission', () => {
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
    await SubmissionModel.deleteMany({});
    
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

    const body = JSON.parse(loginResponse.body);
    accessToken = body.accessToken;
  });

  it('should require authentication', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/submission',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should return null if no submission exists', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/submission',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.submission).toBeNull();
  });
});
