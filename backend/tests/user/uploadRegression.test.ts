import { beforeAll, afterAll, describe, it, expect } from 'vitest';
import { buildApp } from '../../src/server';
import { database } from '../../src/plugins/database';
import { User } from '../../src/models/User';
import { SelfieModel } from '../../src/models/Selfie';
import { DocumentModel } from '../../src/models/Document';
import { readFile, stat, access } from 'node:fs/promises';
import sharp from 'sharp';
import type { FastifyInstance } from 'fastify';

describe('private validated uploads', () => {
  let app: FastifyInstance, token: string;
  beforeAll(async () => {
    app = await buildApp();
    await User.deleteMany({});
    await app.inject({
      method: 'POST',
      url: '/auth/register',
      payload: {
        email: 'upload@example.com',
        password: 'synthetic-password',
        fullName: 'Synthetic User',
      },
    });
    token = (
      await app.inject({
        method: 'POST',
        url: '/auth/login',
        payload: { email: 'upload@example.com', password: 'synthetic-password' },
      })
    ).json().accessToken;
  });
  afterAll(async () => {
    await app?.close();
    await database.disconnect();
  });
  async function upload(url: string, image: Buffer) {
    const boundary = 'synthetic-boundary';
    const fields = url.endsWith('documents')
      ? `--${boundary}\r\nContent-Disposition: form-data; name="type"\r\n\r\npassport\r\n--${boundary}\r\nContent-Disposition: form-data; name="documentNumber"\r\n\r\nSYNTHETIC\r\n`
      : '';
    return app.inject({
      method: 'POST',
      url,
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': `multipart/form-data; boundary=${boundary}`,
      },
      payload: Buffer.concat([
        Buffer.from(
          fields +
            `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="synthetic.png"\r\nContent-Type: image/png\r\n\r\n`
        ),
        image,
        Buffer.from(`\r\n--${boundary}--\r\n`),
      ]),
    });
  }
  for (const url of ['/user/selfie', '/user/documents']) {
    it(`rejects nonimages disguised as PNG at ${url}`, async () => {
      expect((await upload(url, Buffer.from('not an image'))).statusCode).toBe(400);
    });
    it(`accepts decoded synthetic PNG and omits private paths at ${url}`, async () => {
      const image = await sharp({
        create: { width: 2, height: 2, channels: 3, background: 'white' },
      })
        .png()
        .toBuffer();
      const response = await upload(url, image);
      expect(response.statusCode).toBe(201);
      const result = response.json()[url.endsWith('selfie') ? 'selfie' : 'document'];
      expect(result.filePath).toBeUndefined();
      const record = url.endsWith('selfie')
        ? await SelfieModel.findById(result._id)
        : await DocumentModel.findById(result._id);
      expect(record!.filePath.startsWith(process.env.UPLOAD_DIR!)).toBe(true);
      expect((await stat(record!.filePath)).mode & 0o777).toBe(0o600);
      expect((await readFile(record!.filePath)).length).toBeGreaterThan(0);
      if (url.endsWith('selfie')) {
        const oldPath = record!.filePath;
        expect((await upload(url, image)).statusCode).toBe(201);
        await expect(access(oldPath)).rejects.toThrow();
      }
    });
  }
});
