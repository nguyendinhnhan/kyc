import dotenv from 'dotenv';

dotenv.config({ quiet: true });

const environment = process.env.NODE_ENV || 'development';
if (!['development', 'test'].includes(environment)) {
  const access = process.env.JWT_SECRET;
  const refresh = process.env.JWT_REFRESH_SECRET;
  if (
    !access ||
    !refresh ||
    access.length < 32 ||
    refresh.length < 32 ||
    access === refresh ||
    access.includes('change-me') ||
    refresh.includes('change-me')
  ) {
    throw new Error(
      'Distinct JWT signing secrets of at least 32 characters are required outside local development'
    );
  }
}
if (process.env.STORAGE_TYPE && process.env.STORAGE_TYPE !== 'local') {
  throw new Error('Only local development image storage is implemented');
}

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/kyc',
  },
  jwt: {
    secret: process.env.JWT_SECRET || 'default-jwt-secret-change-me',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-change-me',
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '2h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  },
  storage: {
    type: process.env.STORAGE_TYPE || 'local',
    uploadDir: process.env.UPLOAD_DIR || './uploads',
  },
  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:3001',
  },
} as const;

export type Config = typeof config;
