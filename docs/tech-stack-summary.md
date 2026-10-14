# Technology Stack Summary

## All Decisions Confirmed ✅

### Repository Structure ✅
- **Decision**: Single monorepo
- **ADR**: [ADR-0001](docs/adr/0001-repository-and-tdd.md)
- **Structure**:
  ```
  mobile/       Flutter app (iOS + Android)
  backend/      Node.js server
  contracts/    API specifications
  docs/         Documentation and ADRs
  ```

### Backend Runtime ✅
- **Decision**: Node.js
- **ADR**: ADR-0001
- **Rationale**: User preference, JavaScript ecosystem, good for real-time features

### Backend Framework ✅
- **Decision**: Fastify
- **ADR**: [ADR-0003](docs/adr/0003-fastify-typescript-backend.md)
- **Rationale**: 
  - High performance (2-3x faster than Express)
  - Built-in schema validation (Ajv)
  - TypeScript-first with excellent type inference
  - Plugin architecture for clean separation
  - Built-in structured logging

### Backend Language ✅
- **Decision**: TypeScript
- **ADR**: [ADR-0003](docs/adr/0003-fastify-typescript-backend.md)
- **Rationale**:
  - Compile-time type safety
  - Better IDE support (autocomplete, refactoring)
  - Types serve as documentation
  - Industry standard for new Node.js projects
  - Easier to maintain and refactor

### Database ✅
- **Decision**: MongoDB Atlas
- **ADR**: [ADR-0002](docs/adr/0002-mongodb-database.md)
- **Rationale**: 
  - Flexible schema for varying ID document types
  - Document model fits nested KYC data
  - Quick setup with Atlas free tier
  - Natural fit for Node.js ecosystem
  - No local MongoDB installation needed
- **ODM**: Mongoose (recommended)

### Authentication ✅
- **Decision**: JWT with refresh token rotation
- **ADR**: [ADR-0004](docs/adr/0004-jwt-authentication.md)
- **Rationale**:
  - Stateless (scales easily)
  - Mobile-friendly (works with secure storage)
  - Industry standard for mobile apps
  - Short-lived access tokens (15 min) for security
  - Refresh token rotation detects theft
  - Good UX with long-lived refresh tokens

### Flutter State Management ✅
- **Decision**: Riverpod with code generation
- **ADR**: [ADR-0005](docs/adr/0005-riverpod-state-management.md)
- **Rationale**:
  - Compile-time safety (catches errors early)
  - Less boilerplate than BLoC
  - Automatic dependency injection
  - Excellent async operation support
  - Built-in state caching
  - Easy to test (mock providers)
  - Active community and maintenance

### Image Storage ✅
- **Decision**: Local filesystem (dev) + S3-compatible (production)
- **ADR**: [ADR-0006](docs/adr/0006-image-storage-strategy.md)
- **Rationale**:
  - Fast local development without cloud dependencies
  - Production-grade storage with S3 durability
  - Flexible (can switch S3 providers)
  - Cost-effective (free in dev, pay-as-you-go in prod)
  - Standard approach with good tooling
- **Production options**: AWS S3, Cloudflare R2, or MinIO

### Testing Approach ✅
- **Decision**: Test-Driven Development (TDD)
- **ADR**: ADR-0001
- **Approach**: Red → Green → Refactor
- **Requirements**:
  - Write test first for behavior
  - Confirm test fails for intended reason
  - Implement minimum to pass
  - Refactor with tests green
  - Record actual red/green evidence

## Complete Technology Stack

### Backend (Node.js)
```
Runtime:        Node.js
Framework:      Fastify
Language:       TypeScript
Database:       MongoDB Atlas
ODM:            Mongoose
Auth:           JWT + refresh token rotation
Validation:     Fastify built-in (Ajv)
Testing:        Vitest or Jest
File uploads:   @fastify/multipart
CORS:           @fastify/cors
JWT:            @fastify/jwt
```

### Mobile (Flutter)
```
Framework:          Flutter
State management:   Riverpod (with code generation)
Code generation:    build_runner, riverpod_generator
Models:             freezed (recommended)
HTTP client:        Dio (with interceptors for auth)
Secure storage:     flutter_secure_storage
Camera:             camera package
Image handling:     image_cropper, flutter_image_compress
```

### Storage
```
Development:    Local filesystem (backend/uploads/)
Production:     S3-compatible (AWS S3, Cloudflare R2, or MinIO)
Metadata:       MongoDB (image metadata, not actual images)
Encryption:     S3 server-side encryption in production
```

### Development Tools
```
Backend:
  - tsx or ts-node-dev (hot reload)
  - TypeScript strict mode
  - ESLint + Prettier
  - Vitest or Jest (testing)

Mobile:
  - Flutter SDK
  - build_runner (code generation)
  - Flutter DevTools
  - flutter_test (testing)

Database:
  - MongoDB Atlas (cloud)
  - MongoDB Compass (GUI, optional)
```

## Project Structure

```
kyc/
├── app/                      # Flutter app
│   ├── lib/
│   │   ├── core/            # Shared utilities, providers
│   │   ├── features/        # Feature-based organization
│   │   │   ├── auth/
│   │   │   ├── personal_details/
│   │   │   ├── document_capture/
│   │   │   ├── selfie_capture/
│   │   │   ├── review/
│   │   │   └── verification_status/
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
│
├── backend/                  # Node.js + Fastify
│   ├── src/
│   │   ├── controllers/     # Request handlers
│   │   ├── services/        # Business logic
│   │   ├── repositories/    # Database access
│   │   ├── models/          # TypeScript interfaces
│   │   ├── plugins/         # Fastify plugins
│   │   ├── schemas/         # JSON schemas
│   │   ├── middleware/      # Hooks and middleware
│   │   └── utils/           # Shared utilities
│   ├── tests/
│   ├── package.json
│   └── tsconfig.json
│
├── contracts/                # API specifications
│   └── openapi.yaml         # OpenAPI/Swagger spec
│
├── docs/                     # Documentation
│   ├── adr/                 # Architecture Decision Records
│   ├── requirements.md      # Assignment requirements
│   └── ai-usage.md          # AI assistance log
│
├── skills/                   # AI prompt templates
├── AGENTS.md                 # Project rules
├── AI_WORKFLOW.md            # Development workflow
└── README.md                 # Project overview
```

## Next Steps

All major technology decisions are now complete! ✅

### Ready to Start Implementation

1. **Initialize Git repository** (if not already done)
2. **Set up backend scaffolding**
   - Initialize Node.js project with TypeScript
   - Configure Fastify with plugins
   - Set up MongoDB Atlas connection
   - Configure testing framework
3. **Set up mobile scaffolding**
   - Initialize Flutter project
   - Configure Riverpod with code generation
   - Set up project structure
4. **Implement first vertical slice** (Authentication)
   - Backend: `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`
   - Mobile: Login screen, token storage, auto-refresh
   - TDD: Write tests first, then implement

### Implementation Order (Suggested)
1. Authentication flow (login, session, logout)
2. Personal details (draft, validation, resume)
3. Document capture (camera, upload, storage)
4. Selfie capture (camera, upload, storage)
5. Review & submit (idempotent submission)
6. Verification status (status tracking, rejection, resubmission)
7. Lifecycle & network resilience testing

## ADR Index

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-0001](docs/adr/0001-repository-and-tdd.md) | One repository, Node.js, TDD | ✅ Accepted |
| [ADR-0002](docs/adr/0002-mongodb-database.md) | MongoDB Atlas database | ✅ Accepted |
| [ADR-0003](docs/adr/0003-fastify-typescript-backend.md) | Fastify + TypeScript backend | ✅ Accepted |
| [ADR-0004](docs/adr/0004-jwt-authentication.md) | JWT with refresh token rotation | ✅ Accepted |
| [ADR-0005](docs/adr/0005-riverpod-state-management.md) | Riverpod for Flutter state | ✅ Accepted |
| [ADR-0006](docs/adr/0006-image-storage-strategy.md) | Local + S3-compatible image storage | ✅ Accepted |
