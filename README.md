# KYC Onboarding App

A Flutter mobile app (iOS + Android) with a Node.js backend for identity verification (KYC) onboarding.

## Overview

This project contains a KYC onboarding flow. Automated checks and device verification have different scopes; see the [interview guide](docs/interview-demo.md) for evidence and remaining limits:
- User authentication (login, session handling, logout)
- Personal details collection and validation
- ID document capture (passport, national ID, driver's licence)
- Selfie capture
- Review and submission
- Verification status tracking with rejection/resubmission
- Resume capability for interrupted flows

### Demo

[Watch demo video](https://drive.google.com/file/d/1GXdK6VZFOFLEklQAMgkYy3pr-3bw4B_4/view?usp=sharing)

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
- **State Management**: Riverpod StateNotifier providers
- **HTTP Client**: Dio with auth interceptors
- **Secure Storage**: flutter_secure_storage

### Storage
- **Development**: Local filesystem
- **Production**: S3-compatible storage is planned; only local storage is implemented

### Testing
- **Approach**: Test-Driven Development (TDD)
- **Backend**: Vitest
- **Mobile**: flutter_test

## Project Structure

```
kyc/
├── app/                   # Flutter mobile app
├── backend/             # Node.js + Fastify backend
├── contracts/           # API contracts (Markdown)
├── docs/                # Documentation
│   ├── adr/            # Architecture Decision Records
│   ├── requirements.md # Assignment requirements
│   └── ai-usage.md     # AI assistance log
├── skills/               # AI prompt templates
├── AGENTS.md            # Project rules
├── AI_WORKFLOW.md       # Development workflow
└── README.md            # This file
```

## Interview-readiness fixes

The submitted commit remains on `main`; fixes are on `fix/interview-readiness`. See
[the demo guide](docs/interview-demo.md) for current start/check commands and
[ADR-0008](docs/adr/0008-interview-readiness-corrections.md) for corrections and trade-offs.

## Getting Started

### Prerequisites

- **Node.js** compatible with the installed dependency engines, and npm
- **Flutter** with Dart 3.10.7 or newer and iOS/Android setup
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
- MongoDB identity fields and local images are not application-encrypted; use synthetic demo data
- Tokens are stored in platform secure storage (Keychain/Keystore)
- Production storage encryption and key management remain planned
- Request errors log allowlisted codes; auth headers and credential fields are redacted

### Authentication
- Short-lived access tokens (2 hours)
- Long-lived refresh tokens (30 days) with separate signing secret
- Atomic refresh-token rotation rejects reuse; logout revokes its server session
- HTTPS required (except local development)

### Image Handling
- Images validated for type and size
- Ownership checks on all image operations
- Private local files and authenticated image reads; signed URLs and access audit trails remain planned

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

API specifications are available in [contracts/](contracts/):
- Request/response schemas for all endpoints
- Authentication flows (register, login, refresh, logout)
- Admin API (list, approve, reject submissions)
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
- [ ] Full process-death/offline resume evidence (saved backend data can be reloaded; unsaved local edits are not durably protected)

### Upcoming Features
- [ ] Pre-signed upload URLs — direct image upload to S3, bypassing the backend for large files
- [ ] Admin UI — web dashboard for reviewing submissions, approving/rejecting, and viewing stats
- [ ] Submission history — full audit trail of status changes and admin actions
- [x] Server session revocation on logout (MongoDB; no Redis dependency)
- [ ] Field-level encryption for PII in MongoDB
- [ ] OCR integration for automatic document data extraction
- [ ] Biometric face matching against ID photo
- [ ] Push notifications for status changes
- [ ] Multi-language support (i18n)
- [ ] Offline mode with sync queue
- [ ] CI/CD pipeline for automated testing and deployment

## License

This project is part of a take-home assignment and is not licensed for external use.

## Contact

For questions about this project, please refer to the assignment specification in `Senior_Fullstack_Assignment.pdf`.
