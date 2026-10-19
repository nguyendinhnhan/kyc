import { readFileSync, existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import dotenv from 'dotenv';
import { afterAll } from 'vitest';
import mongoose from 'mongoose';

const local = existsSync('.env') ? dotenv.parse(readFileSync(path.resolve('.env'))) : {};
const uri = new URL(local.MONGODB_URI || 'mongodb://127.0.0.1:27017/kyc');
if (!['localhost', '127.0.0.1'].includes(uri.hostname)) {
  throw new Error('Tests require a local MongoDB database');
}
uri.pathname = '/kyc_test_' + process.pid;
process.env.MONGODB_URI = uri.toString();
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'synthetic-test-access-secret';
process.env.JWT_REFRESH_SECRET = 'synthetic-test-refresh-secret';
process.env.UPLOAD_DIR = mkdtempSync(path.join(tmpdir(), 'kyc-tests-'));
const uploadDirectory = process.env.UPLOAD_DIR;
let usedDatabase = false;
mongoose.connection.once('connected', () => {
  usedDatabase = true;
});
afterAll(async () => {
  try {
    if (!usedDatabase) return;
    // The URI is constructed above with a fixed local host and test-only database name.
    const cleanup = await mongoose
      .createConnection(uri.toString(), { serverSelectionTimeoutMS: 5000 })
      .asPromise();
    try {
      await cleanup.dropDatabase();
    } finally {
      await cleanup.close();
    }
  } finally {
    rmSync(uploadDirectory, { recursive: true, force: true });
  }
});
