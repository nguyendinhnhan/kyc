# KYC Onboarding App

A Flutter mobile app (iOS + Android) with a Node.js backend for identity verification (KYC) onboarding.

## Overview

This project implements a complete KYC onboarding flow:
- User authentication (login, session handling, logout)
- Personal details collection and validation
- ID document capture (passport, national ID, driver's licence)
- Selfie capture
- Review and submission
- Verification status tracking with rejection/resubmission
- Resume capability for interrupted flows

### Demo

[Watch demo video](docs/demo.mov)

## Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Fastify
- **Language**: TypeScript
- **Database**: MongoDB (Local via Docker or MongoDB Atlas)
- **Authentication**: JWT with refresh token rotation
- **Validation**: Fastify built-in (Ajv)

### Mobile
- **Framework**: Flutter (iOS + Android)
- **State Management**: Riverpod with code generation
- **HTTP Client**: Dio with auth interceptors
- **Secure Storage**: flutter_secure_storage

### Storage
- **Development**: Local filesystem
- **Production**: S3-compatible (AWS S3, Cloudflare R2, or MinIO)

### Testing
- **Approach**: Test-Driven Development (TDD)
- **Backend**: Vitest or Jest
- **Mobile**: flutter_test

## Project Structure

```
kyc/
├── app/                   # Flutter mobile app
├── backend/             # Node.js + Fastify backend
├── contracts/           # API specifications (OpenAPI)
├── docs/                # Documentation
│   ├── adr/            # Architecture Decision Records
│   ├── requirements.md # Assignment requirements
│   └── ai-usage.md     # AI assistance log
├── skills/               # AI prompt templates
├── AGENTS.md            # Project rules
├── AI_WORKFLOW.md       # Development workflow
└── README.md            # This file
```

## Getting Started

### Prerequisites

- **Node.js** 18+ and npm/yarn
- **Flutter** 3.16+ with iOS/Android setup
- **Docker** (for local MongoDB) OR **MongoDB Atlas** account (free tier)
- **Xcode** (for iOS development)
- **Android Studio** (for Android development)

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create `.env` file:
   ```bash
   cp .env.example .env
   ```

4. Configure environment variables:
   - `MONGODB_URI`: Your MongoDB Atlas connection string
   - `JWT_SECRET`: Secret key for JWT signing
   - `JWT_REFRESH_SECRET`: Secret key for refresh tokens
   - `PORT`: Server port (default: 3000)

5. Run development server:
   ```bash
   npm run dev
   ```

6. Run tests:
   ```bash
   npm test
   ```

### Mobile Setup

1. Navigate to app directory:
   ```bash
   cd app
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation:
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

5. Run tests:
   ```bash
   flutter test
   ```

## Architecture Decisions

All major architectural decisions are documented in [Architecture Decision Records (ADRs)](docs/adr/):

- [ADR-0001](docs/adr/0001-repository-and-tdd.md): One repository, Node.js, TDD
- [ADR-0002](docs/adr/0002-mongodb-database.md): MongoDB Atlas database
- [ADR-0003](docs/adr/0003-fastify-typescript-backend.md): Fastify + TypeScript backend
- [ADR-0004](docs/adr/0004-jwt-authentication.md): JWT with refresh token rotation
- [ADR-0005](docs/adr/0005-riverpod-state-management.md): Riverpod for Flutter state
- [ADR-0006](docs/adr/0006-image-storage-strategy.md): Local + S3-compatible image storage
- [ADR-0007](docs/adr/0007-sensitive-data-handling.md): Sensitive data handling (R9)

See [tech-stack-summary.md](docs/tech-stack-summary.md) for a complete overview.

## Security Considerations

### Sensitive Data
- PII (personally identifiable information) is encrypted at rest
- Tokens are stored in platform secure storage (Keychain/Keystore)
- Images are encrypted in production (S3 server-side encryption)
- No sensitive data in logs, commits, or error messages

### Authentication
- Short-lived access tokens (2 hours)
- Long-lived refresh tokens (30 days) with separate signing secret
- Refresh token rotation detects token theft
- HTTPS required (except local development)

### Image Handling
- Images validated for type and size
- Ownership checks on all image operations
- Pre-signed URLs with short expiry
- Audit logging for image access

## Testing Strategy

Following TDD principles:
- **Unit tests**: Business logic, validators, state transitions
- **Integration tests**: API endpoints, database operations
- **Widget tests**: UI components, form validation
- **Device tests**: Camera capture, secure storage, lifecycle

Run all tests:
```bash
# Backend
cd backend && npm test

# Mobile
cd app && flutter test
```

## AI-Assisted Development

This project uses a structured AI development workflow. See [AI_WORKFLOW.md](AI_WORKFLOW.md) for details.

AI usage is documented in [docs/ai-usage.md](docs/ai-usage.md), including:
- Where AI helped
- What was corrected
- How output was validated
- Developer decisions and rationale

## Development Workflow

1. **Analyze**: Identify requirements and inspect existing code
2. **Plan**: Define smallest end-to-end slice
3. **Implement with TDD**: Write test → confirm failure → implement → refactor
4. **Validate**: Run tests, linting, integration checks
5. **Review**: Inspect diff against acceptance criteria
6. **Document**: Update docs, record AI usage
7. **Deliver**: Verify setup, record evidence

## API Documentation

API specifications will be available in [contracts/](contracts/) once implemented:
- OpenAPI/Swagger specification
- Request/response schemas
- Authentication flows
- Error codes and messages

## Status

### Completed
- [x] Backend (Fastify + TypeScript + MongoDB)
- [x] Mobile app (Flutter + Riverpod)
- [x] Authentication flow with JWT (separate access/refresh secrets)
- [x] Personal details capture with validation
- [x] Document capture (camera + gallery)
- [x] Selfie capture (camera + gallery)
- [x] Review and submission
- [x] Admin API (approve/reject with field-level rejection)
- [x] Verification status tracking with rejection/resubmission
- [x] Sensitive data handling (log redaction, ownership isolation, secure storage)
- [x] Resume capability for interrupted flows

## License

This project is part of a take-home assignment and is not licensed for external use.

## Contact

For questions about this project, please refer to the assignment specification in `Senior_Fullstack_Assignment.pdf`.
