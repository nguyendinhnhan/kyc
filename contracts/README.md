# API Contracts

Language-neutral API specifications for the KYC onboarding app.

## Purpose

This directory contains API contracts that define the interface between the Flutter mobile app and the Node.js backend. These contracts are:

- **Language-neutral**: Not tied to Dart or TypeScript implementations
- **Single source of truth**: Both client and server implement these contracts
- **Version-controlled**: Changes to contracts require updates to both sides
- **Testable**: Synthetic fixtures can be generated from these specs

## Contents

### Markdown Documentation (Human-Readable)
- `api/` - Human-readable API endpoint documentation
  - `auth/` - Authentication endpoints (register, login, refresh, logout)
  - Each endpoint has detailed request/response examples
  - Multi-language code examples (cURL, JavaScript, Dart)

### OpenAPI Specification (Machine-Readable)
- `openapi.yaml` - OpenAPI 3.0 specification (TODO)
- Defines all endpoints, request/response schemas
- Authentication requirements
- Error codes and messages

### Synthetic Fixtures
- `fixtures/` - Test data for development and testing (TODO)
- Synthetic identity data (no real PII)
- Sample API responses
- Error scenarios

## Usage

### Backend Implementation
The backend implements these contracts:
- Validate requests against schemas
- Return responses matching schemas
- Use error codes as defined

### Mobile Implementation
The mobile app consumes these contracts:
- Generate API client from OpenAPI spec (optional)
- Validate responses match expected schemas
- Handle all defined error codes

### Testing
Use synthetic fixtures for:
- Backend integration tests
- Mobile widget/integration tests
- Contract verification tests

## Modifying Contracts

When changing API contracts:

1. Update `openapi.yaml` (when created)
2. Update markdown documentation in `api/`
3. Update synthetic fixtures if needed
4. Update backend implementation
5. Update mobile implementation
6. Update tests on both sides
7. Commit all changes together

## Tools

### View Markdown Documentation
Simply browse the `api/` directory:
```bash
# View auth endpoints
cat api/auth/register.md
cat api/auth/login.md
```

### View OpenAPI Spec (TODO)
Use Swagger UI or Redoc to view the API:

```bash
# Install Swagger UI
npm install -g swagger-ui-cli

# Serve the spec
swagger-ui serve openapi.yaml
```

Or paste the spec into https://editor.swagger.io/

### Generate Client Code (Optional)
```bash
# Generate Dart client
openapi-generator generate -i openapi.yaml -g dart-dio -o ./generated/dart

# Generate TypeScript client
openapi-generator generate -i openapi.yaml -g typescript-fetch -o ./generated/typescript
```

Note: Client generation is optional. You can also manually implement the API calls.

## Current Status

### ✅ Implemented (Markdown Documentation)
- `/auth/register` - User registration
- `/auth/login` - Authentication with JWT
- `/auth/refresh` - Token refresh/rotation
- `/auth/logout` - Token invalidation

### ⏳ TODO (OpenAPI & Fixtures)
- `openapi.yaml` - OpenAPI 3.0 specification
- `fixtures/` - Synthetic test data
- Code generation setup

## Why Both Markdown and OpenAPI?

**Markdown (api/)**:
- ✅ Human-readable
- ✅ Detailed explanations
- ✅ Multi-language examples
- ✅ Implementation guidance
- ✅ Easy to review in PRs

**OpenAPI (openapi.yaml)**:
- ✅ Machine-readable
- ✅ Auto-generate clients
- ✅ Auto-generate documentation
- ✅ Validate requests/responses
- ✅ Industry standard

**Together**: Best of both worlds! 🌍
