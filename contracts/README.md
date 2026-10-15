# API Contracts

Human-readable API documentation for the KYC Onboarding App.

## Purpose

This directory contains API contracts that define the interface between the Flutter mobile app and the Node.js backend. These contracts serve as:

- **Documentation** - Clear API specifications with examples
- **Testing** - Mock data for frontend development
- **Reference** - Single source of truth for API structure

## Contents

```
contracts/
├── api/                    # API endpoint documentation
│   ├── README.md          # API overview
│   └── auth/              # Authentication endpoints
│       ├── register.md    # POST /auth/register
│       ├── login.md       # POST /auth/login
│       ├── refresh.md     # POST /auth/refresh
│       └── logout.md      # POST /auth/logout
└── README.md              # This file
```

## Current Implementation

### ✅ Authentication Endpoints
- **POST /auth/register** - User registration with validation
- **POST /auth/login** - Authentication with JWT tokens
- **POST /auth/refresh** - Token refresh/rotation
- **POST /auth/logout** - Protected logout endpoint

Each endpoint includes:
- Request/response examples
- Validation rules
- Error scenarios
- Multi-language examples (cURL, JavaScript, Dart)

## Usage

### For Backend Development
1. Read contract before implementing endpoint
2. Use examples for testing
3. Ensure responses match contract structure

### For Frontend Development
1. Use contracts to build API client
2. Use examples as mock data
3. Implement error handling for documented errors

### Testing
- **Backend tests**: `cd backend && npm test`
- **Postman collection**: `docs/postman/KYC_Auth_API.postman_collection.json`
- **Manual testing**: Follow examples in each endpoint documentation

## Modifying Contracts

When changing API contracts:

1. Update markdown documentation in `api/`
2. Update backend implementation
3. Update backend tests
4. Update Postman collection
5. Update mobile implementation (when built)
6. Commit all changes together

## Testing Tools

### Postman Collection
Import `docs/postman/KYC_Auth_API.postman_collection.json` into Postman for:
- Pre-configured requests for all endpoints
- Automatic token management
- Test scripts for validation
- Error scenario testing

### Backend Tests
Run comprehensive test suite:
```bash
cd backend
npm test              # Run all tests
npm run test:coverage # Run with coverage
```

## Future Enhancements

When time permits, consider adding:

### OpenAPI Specification
- Create `openapi.yaml` with OpenAPI 3.0 specification
- Enables auto-generated documentation (Swagger UI)
- Enables client code generation for multiple languages
- Industry standard for API documentation

**Tools:**
```bash
# View OpenAPI spec
npm install -g swagger-ui-cli
swagger-ui serve openapi.yaml

# Generate Dart client
openapi-generator generate -i openapi.yaml -g dart-dio -o ./generated/dart

# Generate TypeScript client
openapi-generator generate -i openapi.yaml -g typescript-fetch -o ./generated/typescript
```

### Synthetic Fixtures
- Create `fixtures/` directory with test data
- Synthetic identity data (no real PII)
- Sample API responses for all scenarios
- Error response examples

**Benefits:**
- Use in backend integration tests
- Use in mobile widget/integration tests
- Contract verification tests
- Consistent test data across teams

### Code Generation
- Auto-generate Dart API client from OpenAPI spec
- Auto-generate TypeScript types
- Reduce manual implementation errors
- Keep client code in sync with API changes

**Note:** These enhancements are optional and not required for the assignment. The current markdown documentation is sufficient for this project.

## Why Markdown Documentation?

**Pros:**
- ✅ Human-readable and easy to understand
- ✅ Detailed explanations and context
- ✅ Multi-language code examples
- ✅ Implementation guidance
- ✅ Easy to review in pull requests
- ✅ No special tools required

**Cons:**
- ❌ Can't auto-generate clients
- ❌ Can't validate automatically
- ❌ Manual maintenance

**For this assignment:** Markdown is perfect! It's simple, clear, and effective.

## Resources

- **Postman Collection**: `docs/postman/KYC_Auth_API.postman_collection.json`
- **Backend Tests**: `backend/tests/`
- **API Implementation**: `backend/src/routes/auth.ts`
