# API Contracts

This directory contains API contract definitions for the KYC Backend.

## Purpose

API contracts define the expected request/response structure for all endpoints. They serve as:
- **Documentation** - Clear API specification
- **Testing** - Mock data for frontend development
- **Validation** - Ensure backend matches expected structure
- **Communication** - Agreement between frontend and backend teams

## Structure

```
contracts/api/
├── auth/                    # Authentication endpoints
│   ├── register.md         # POST /auth/register
│   ├── login.md            # POST /auth/login
│   ├── refresh.md          # POST /auth/refresh
│   └── logout.md           # POST /auth/logout (TODO)
├── user/                   # User endpoints (TODO)
└── kyc/                    # KYC endpoints (TODO)
```

## How to Use

### For Backend Development
1. Implement endpoints to match contract specifications
2. Use error examples for testing error handling
3. Validate responses match the defined structure

### For Frontend Development
1. Use response examples as mock data
2. Build UI based on request/response structures
3. Test with error scenarios
4. Implement error handling for error responses

## Status Codes

Standard HTTP status codes used:
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid credentials/token)
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

## Authentication

All authenticated endpoints require:
```
Authorization: Bearer <accessToken>
```

## Base URL

- Development: `http://localhost:3000`
- Production: `https://api.yourdomain.com` (TODO)
