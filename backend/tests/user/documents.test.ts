import { readFileSync } from 'node:fs';
import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { buildApp } from '../../src/server';
import { User } from '../../src/models/User';
import { DocumentModel } from '../../src/models/Document';
import { database } from '../../src/plugins/database';
import type { FastifyInstance } from 'fastify';
import fs from 'fs';
import path from 'path';

describe('POST /user/documents', () => {
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
    const uploadsDir = process.env.UPLOAD_DIR!;
    if (fs.existsSync(uploadsDir)) {
      const files = fs.readdirSync(uploadsDir);
      for (const file of files) {
        fs.unlinkSync(path.join(uploadsDir, file));
      }
    }
  });

  beforeEach(async () => {
    await User.deleteMany({});
    await DocumentModel.deleteMany({});

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
      method: 'POST',
      url: '/user/documents',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should upload a document', async () => {
    // Create a test file
    const testFilePath = path.join(__dirname, 'test-document.jpg');
    fs.writeFileSync(testFilePath, readFileSync('tests/fixtures/synthetic.jpg').toString('binary'));

    try {
      // Create multipart form data
      const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
      const body = [
        `--${boundary}`,
        'Content-Disposition: form-data; name="type"',
        '',
        'passport',
        `--${boundary}`,
        'Content-Disposition: form-data; name="documentNumber"',
        '',
        'AB123456',
        `--${boundary}`,
        'Content-Disposition: form-data; name="file"; filename="test-document.jpg"',
        'Content-Type: image/jpeg',
        '',
        readFileSync('tests/fixtures/synthetic.jpg').toString('binary'),
        `--${boundary}--`,
      ].join('\r\n');

      const response = await app.inject({
        method: 'POST',
        url: '/user/documents',
        headers: {
          authorization: `Bearer ${accessToken}`,
          'content-type': `multipart/form-data; boundary=${boundary}`,
        },
        payload: Buffer.from(body, 'binary'),
      });

      expect(response.statusCode).toBe(201);

      const responseBody = JSON.parse(response.body);
      expect(responseBody).toHaveProperty('message', 'Document uploaded successfully');
      expect(responseBody).toHaveProperty('document');
      expect(responseBody.document).toHaveProperty('type', 'passport');
      expect(responseBody.document).toHaveProperty('documentNumber', 'AB123456');
      expect(responseBody.document).toHaveProperty('status', 'pending');
    } finally {
      // Clean up test file
      if (fs.existsSync(testFilePath)) {
        fs.unlinkSync(testFilePath);
      }
    }
  });

  it('should validate document type', async () => {
    const testFilePath = path.join(__dirname, 'test-document.jpg');
    fs.writeFileSync(testFilePath, readFileSync('tests/fixtures/synthetic.jpg').toString('binary'));

    try {
      // Create multipart form data with invalid type
      const boundary = '----WebKitFormBoundary' + Math.random().toString(36).substring(2);
      const body = [
        `--${boundary}`,
        'Content-Disposition: form-data; name="type"',
        '',
        'invalid_type',
        `--${boundary}`,
        'Content-Disposition: form-data; name="documentNumber"',
        '',
        'AB123456',
        `--${boundary}`,
        'Content-Disposition: form-data; name="file"; filename="test-document.jpg"',
        'Content-Type: image/jpeg',
        '',
        readFileSync('tests/fixtures/synthetic.jpg').toString('binary'),
        `--${boundary}--`,
      ].join('\r\n');

      const response = await app.inject({
        method: 'POST',
        url: '/user/documents',
        headers: {
          authorization: `Bearer ${accessToken}`,
          'content-type': `multipart/form-data; boundary=${boundary}`,
        },
        payload: Buffer.from(body, 'binary'),
      });

      expect(response.statusCode).toBe(400);
    } finally {
      if (fs.existsSync(testFilePath)) {
        fs.unlinkSync(testFilePath);
      }
    }
  });
});

describe('GET /user/documents', () => {
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
    await DocumentModel.deleteMany({});

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
      url: '/user/documents',
    });

    expect(response.statusCode).toBe(401);
  });

  it('should return empty array if no documents', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/user/documents',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('documents');
    expect(body.documents).toEqual([]);
  });
});
