# ADR-0007: Sensitive Data Handling

Implementation corrections and current limits: see [ADR-0008](0008-interview-readiness-corrections.md). Earlier implementation claims below are historical and are superseded where they conflict.


## Status
Accepted

## Context
The KYC application handles sensitive identity data including personal details (name, date of birth, nationality, phone, address), identity document images, selfie images, authentication credentials, and JWT tokens. This ADR documents how sensitive data is protected across the system to satisfy requirement R9.

## Decisions

### 1. Token Storage (Flutter)
- **Decision**: Use `flutter_secure_storage` for all token persistence.
- **Rationale**: Platform-native secure storage (Keychain on iOS, EncryptedSharedPreferences on Android) provides OS-level encryption at rest.
- **Implementation**: `TokenStorage` class wraps `FlutterSecureStorage` for access and refresh tokens. Tokens are cleared on logout.

### 2. Ownership Isolation (Backend)
- **Decision**: All protected endpoints extract `userId` from the JWT token, never from request body or URL parameters.
- **Rationale**: Client-supplied user IDs cannot be trusted. The JWT is server-signed and tamper-proof.
- **Implementation**:
  - `authenticate` middleware verifies JWT and attaches `userId` to `request.user`.
  - Every MongoDB query includes `{ userId }` filter: `DocumentModel.find({ userId })`, `SelfieModel.findOne({ userId })`, `PersonalDetails.findOne({ userId })`, `SubmissionModel.findOne({ userId })`.
  - Image serving endpoints (`getSelfieImageHandler`, `getDocumentImageHandler`) verify ownership by querying with both `_id` and `userId`.
  - Admin routes use `[authenticate, requireAdmin]` middleware chain.

### 3. Log Redaction (Backend)
- **Decision**: Fastify logger redacts sensitive fields from all log output.
- **Redacted paths**:
  - `req.headers.authorization` — Bearer tokens
  - `req.body.password` — User passwords
  - `req.body.refreshToken` — Refresh tokens
  - `req.body.accessToken` — Access tokens
  - `req.body.token` — Generic tokens
- **Implementation**: `server.ts` configures `logger.redact` with `censor: '[REDACTED]'`.
- **Additional**: All `print()` statements that logged response data (containing tokens) were removed from `auth_repository.dart`. Backend helper functions use silent error handling for best-effort operations.

### 4. Password Protection (Backend)
- **Decision**: Passwords are bcrypt-hashed before storage and excluded from all API responses.
- **Implementation**:
  - `User` model uses `bcrypt.hash()` in a `pre('save')` hook with salt rounds of 10.
  - `toJSON()` method on User schema removes `password` field from serialization.
  - Auth responses manually construct user objects without password field.

### 5. Image/File Access Protection
- **Decision**: Uploaded images are served only through authenticated endpoints that verify ownership.
- **Implementation**:
  - Files stored with UUID filenames (not predictable paths).
  - `getSelfieImageHandler` and `getDocumentImageHandler` require `authenticate` middleware.
  - Document image endpoint queries with `{ _id: id, userId }` to prevent IDOR.
  - `filePath` is excluded from API responses via `.select('-filePath')` on both document and selfie queries.
- **Production**: S3-compatible storage with bucket-level access controls (see ADR-0006).

### 6. Error Response Safety
- **Decision**: Error responses never expose internal implementation details.
- **Implementation**:
  - 5xx errors return generic `"Internal Server Error"` message.
  - 4xx errors return specific validation/auth messages without stack traces.
  - Development mode includes `details` field for debugging; production omits it.

### 7. File Upload Limits
- **Decision**: Server-enforced upload size limit prevents abuse.
- **Implementation**: `@fastify/multipart` configured with `limits: { fileSize: 10 * 1024 * 1024 }` (10MB).

## Retention and Cleanup
- Uploaded files persist for the lifetime of the user's submission.
- When a document is replaced (re-upload), the old file is deleted via `fs.unlinkSync()`.
- No automated cleanup is implemented; retention policy should be defined by legal requirements before production deployment.
- Account deletion is not yet implemented; should include cascading delete of all user data (personal details, documents, selfie, submission).

## Risks and Future Work
- **Token blacklist**: Logout does not invalidate refresh tokens server-side. A Redis-backed blacklist should be added for production.
- **Encryption at rest**: Local filesystem storage does not encrypt images. Production S3 storage should use server-side encryption (SSE-S3 or SSE-KMS).
- **PII in database**: Personal details are stored in plaintext in MongoDB. Production should consider field-level encryption for PII fields.
- **Audit logging**: No audit trail exists for admin actions (approve/reject). Should be added for compliance.
