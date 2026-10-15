import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { SelfieModel } from '../../src/models/Selfie';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';
import fs from 'fs';
import path from 'path';

describe('POST /user/selfie', () => {
  let app: FastifyInstance;
  let accessToken: string;

  beforeAll(async () => {
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
    await database.disconnect();
    // Clean up test uploads
    const uploadsDir = path.join(__dirname, '../../uploads');
    if (fs.existsSync(uploadsDir)) {
      const files = fs.readdirSync(uploadsDir);
      for (const file of files) {
        fs.unlinkSync(path.join(uploadsDir, file));
      }
    }
  });

  beforeEach(async () => {
    await User.deleteMany({});
    await SelfieModel.deleteMany({});
    
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
      url: '/user/selfie',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should upload a selfie', async () => {
    // Create a fake image buffer
    const fakeImage = Buffer.from('fake-image-data');
    
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const body = [
      `--${boundary}`,
      'Content-Disposition: form-data; name="file"; filename="selfie.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage.toString('binary'),
      `--${boundary}--`,
      '',
    ].join('\r\n');

    const response = await app.inject({
      method: 'POST',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.from(body, 'binary'),
    });

    console.log('Response status:', response.statusCode);
    console.log('Response body:', response.body);

    expect(response.statusCode).toBe(201);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.message).toBe('Selfie uploaded successfully');
    expect(responseBody.selfie).toBeDefined();
    expect(responseBody.selfie.status).toBe('pending');
  });

  it('should update existing selfie', async () => {
    // Upload first selfie
    const fakeImage1 = Buffer.from('fake-image-data-1');
    const boundary1 = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const body1 = [
      `--${boundary1}`,
      'Content-Disposition: form-data; name="file"; filename="selfie1.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage1.toString('binary'),
      `--${boundary1}--`,
      '',
    ].join('\r\n');

    await app.inject({
      method: 'POST',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary1}`,
      },
      payload: Buffer.from(body1, 'binary'),
    });

    // Upload second selfie (should replace first)
    const fakeImage2 = Buffer.from('fake-image-data-2');
    const boundary2 = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const body2 = [
      `--${boundary2}`,
      'Content-Disposition: form-data; name="file"; filename="selfie2.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage2.toString('binary'),
      `--${boundary2}--`,
      '',
    ].join('\r\n');

    const response = await app.inject({
      method: 'POST',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary2}`,
      },
      payload: Buffer.from(body2, 'binary'),
    });

    expect(response.statusCode).toBe(201);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.selfie).toBeDefined();
  });
});

describe('GET /user/selfie', () => {
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
    await SelfieModel.deleteMany({});
    
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
      url: '/user/selfie',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should return empty if no selfie exists', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.selfie).toBeNull();
  });

  it('should return user selfie', async () => {
    // Upload selfie first
    const fakeImage = Buffer.from('fake-image-data');
    const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
    const body = [
      `--${boundary}`,
      'Content-Disposition: form-data; name="file"; filename="selfie.jpg"',
      'Content-Type: image/jpeg',
      '',
      fakeImage.toString('binary'),
      `--${boundary}--`,
      '',
    ].join('\r\n');

    await app.inject({
      method: 'POST',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.from(body, 'binary'),
    });

    // Get selfie
    const response = await app.inject({
      method: 'GET',
      url: '/user/selfie',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);
    const responseBody = JSON.parse(response.body);
    expect(responseBody.selfie).toBeDefined();
    expect(responseBody.selfie.status).toBe('pending');
  });
});
