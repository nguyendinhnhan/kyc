# KYC Backend

Node.js + Fastify backend for KYC onboarding.

## Setup

See [main README](../README.md) for prerequisites and overall project setup.

## Quick Start

### Option 1: Local MongoDB with Docker (Recommended for Testing)

```bash
# Install dependencies
npm install

# Start MongoDB with Docker
docker-compose up -d

# Create environment file (already configured for local MongoDB)
cp .env.example .env

# Run development server
npm run dev

# Run tests
npm test
```

### Option 2: MongoDB Atlas (Cloud)

```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env and replace MONGODB_URI with your Atlas connection string:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/kyc

# Run development server
npm run dev

# Run tests
npm test
```

### Common Commands

```bash
# Build for production
npm run build

# View logs
docker-compose logs -f mongodb

# Stop MongoDB
docker-compose down

# Stop MongoDB and delete data
docker-compose down -v
```

## Architecture

- **Framework**: Fastify
- **Language**: TypeScript
- **Database**: MongoDB (Local via Docker or MongoDB Atlas)
- **Authentication**: JWT with refresh token rotation
- **Pattern**: Layered architecture (controllers → services → repositories)

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout

### Personal Details
- `GET /api/v1/personal-details` - Get personal details
- `PUT /api/v1/personal-details` - Update personal details

### Document Capture
- `POST /api/v1/documents/upload` - Upload ID document
- `GET /api/v1/documents/:id` - Get document metadata

### Selfie Capture
- `POST /api/v1/selfie/upload` - Upload selfie
- `GET /api/v1/selfie/:id` - Get selfie metadata

### Submission
- `POST /api/v1/submissions` - Submit KYC application
- `GET /api/v1/submissions/:id` - Get submission status

### Verification Status
- `GET /api/v1/verification/status` - Get verification status

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Server
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb+srv://...

# JWT
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Storage (production)
STORAGE_TYPE=local  # or 's3'
S3_BUCKET=your-bucket
S3_REGION=your-region
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
```

## Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# Coverage
npm run test:coverage
```

## Database

MongoDB Atlas is used for persistence. Collections:
- `users` - User accounts
- `refresh_tokens` - Refresh tokens
- `personal_details` - User identity information
- `documents` - ID document metadata
- `selfies` - Selfie metadata
- `submissions` - KYC submissions
- `verification_status` - Verification state

## Image Storage

### Development
Images stored locally in `uploads/` directory.

### Production
S3-compatible storage (AWS S3, Cloudflare R2, or MinIO).

Configure via environment variables:
- `STORAGE_TYPE`: 'local' or 's3'
- `S3_*`: S3 configuration (when using S3)

## Security

- Password hashing with bcrypt
- JWT authentication with refresh token rotation
- Rate limiting on sensitive endpoints
- Input validation on all endpoints
- Ownership checks on all resources
- No PII in logs
- HTTPS required (except local development)

## Build

```bash
# Compile TypeScript to JavaScript
npm run build

# Start production server
npm start
```

## Linting

```bash
# Check code
npm run lint

# Fix code
npm run lint:fix
```
