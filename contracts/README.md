# API Contracts

Language-neutral API specifications for the KYC onboarding app.

## Purpose

This directory contains API contracts that define the interface between the Flutter mobile app and the Node.js backend. These contracts are:

- **Language-neutral**: Not tied to Dart or TypeScript implementations
- **Single source of truth**: Both client and server implement these contracts
- **Version-controlled**: Changes to contracts require updates to both sides
- **Testable**: Synthetic fixtures can be generated from these specs

## Contents

### OpenAPI Specification
- `openapi.yaml` - OpenAPI 3.0 specification
- Defines all endpoints, request/response schemas
- Authentication requirements
- Error codes and messages

### Synthetic Fixtures
- `fixtures/` - Test data for development and testing
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

1. Update `openapi.yaml`
2. Update synthetic fixtures if needed
3. Update backend implementation
4. Update mobile implementation
5. Update tests on both sides
6. Commit all changes together

## Tools

### View OpenAPI Spec
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

## Status

⏳ **Pending** - API contracts will be defined during implementation.

The first step is to implement the authentication flow, which will define:
- `/api/v1/auth/register`
- `/api/v1/auth/login`
- `/api/v1/auth/refresh`
- `/api/v1/auth/logout`
