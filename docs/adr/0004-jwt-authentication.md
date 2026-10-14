# 0004: JWT authentication with refresh token rotation
Status: Accepted
Date: 2026-10-14

## Context
R2 requires login, session handling, and logout. R9 requires secure handling of sensitive data including tokens. The mobile app needs secure token storage (Keychain/Keystore), automatic token refresh, and session management. The backend needs to validate tokens on every request, handle token expiry, and support logout/revocation.

## Decision
Use **JWT (JSON Web Tokens)** with **refresh token rotation** for authentication.

Key implications:
- Short-lived access tokens (15 minutes) for API authorization
- Longer-lived refresh tokens (7-30 days) for obtaining new access tokens
- Refresh token rotation: issue new refresh token on each use, invalidate old one
- Store access token in memory (Flutter) or secure storage
- Store refresh token in platform secure storage (Keychain/Keystore)
- Backend validates JWT signature and expiry on every request
- Logout invalidates refresh token in database
- Use RS256 (RSA + SHA-256) or HS256 (HMAC + SHA-256) for signing

## Token Structure

### Access Token (JWT)
```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "iat": 1697299200,
  "exp": 1697300100,  // 15 minutes
  "iss": "kyc-backend"
}
```

### Refresh Token
- Opaque string (UUID or random token)
- Stored in database with: user_id, token_hash, expires_at, created_at, revoked
- Rotated on each use (new token issued, old one invalidated)

## Alternatives

1. **Session-based authentication** — Server-side sessions
   - Pros: Simpler revocation, no token management on client
   - Cons: Requires server-side state, harder to scale, not ideal for mobile
   
2. **Passkeys/WebAuthn** — Modern, phishing-resistant
   - Pros: Strong security, no passwords
   - Cons: Complex implementation, not all users have compatible devices, overkill for this assignment
   
3. **API keys** — Long-lived tokens
   - Pros: Simple
   - Cons: No expiry, poor security, not suitable for user sessions

## Rationale

### Why JWT?
- **Stateless**: No server-side session storage needed (scales easily)
- **Mobile-friendly**: Works well with secure storage on iOS/Android
- **Standard**: Industry standard for mobile app authentication
- **Self-contained**: Token contains user info (reduces database lookups)
- **Fast**: Signature validation is faster than database session lookup

### Why Refresh Token Rotation?
- **Security**: Compromised refresh token is only valid once
- **Revocation**: Can revoke refresh token on logout or suspicious activity
- **Balance**: Short-lived access tokens reduce window of exposure; refresh tokens provide good UX
- **Detection**: Reuse of old refresh token indicates theft (can trigger alert)

### Why Not Longer Access Tokens?
- 15-minute window limits damage if token is compromised
- Refresh provides seamless UX without frequent logins
- Balance between security and user experience

## Consequences

### Benefits
- Stateless authentication scales well
- Short-lived tokens reduce security risk
- Refresh rotation detects token theft
- Works well with mobile secure storage
- Standard pattern with good tooling support
- Fastify JWT plugin provides good integration

### Costs and Risks
- More complex than session-based (token management, refresh logic)
- Refresh token rotation requires database storage and validation
- Token theft within 15-minute window still possible
- Clock skew can cause token validation issues
- Revocation requires checking token blacklist or using short expiry

### Mitigations
- Use @fastify/jwt for robust JWT handling
- Store refresh tokens hashed in database
- Implement refresh token family tracking (detect reuse)
- Use HTTPS everywhere (except local dev)
- Validate token on every request
- Implement rate limiting on auth endpoints
- Use secure, HTTP-only cookies for web (if needed later)

## Implementation

### Backend
- Use `@fastify/jwt` for JWT signing and verification
- Store refresh tokens in MongoDB with expiry and revocation status
- Implement `/auth/login` endpoint (returns access + refresh tokens)
- Implement `/auth/refresh` endpoint (validates refresh token, issues new pair)
- Implement `/auth/logout` endpoint (revokes refresh token)
- Add authentication middleware/hook for protected routes
- Use RS256 or HS256 (HS256 simpler for single issuer)

### Mobile (Flutter)
- Store access token in memory (Provider state) or secure storage
- Store refresh token in flutter_secure_storage (Keychain/Keystore)
- Implement token refresh interceptor (Dio interceptor)
- Auto-refresh access token before expiry or on 401 response
- Clear tokens on logout
- Handle concurrent refresh requests (prevent race conditions)

### Security
- Never log tokens or include in error messages
- Use HTTPS for all API calls (except local development)
- Validate JWT signature, expiry, and issuer
- Hash refresh tokens in database (bcrypt or similar)
- Implement rate limiting on `/auth/login` and `/auth/refresh`
- Detect refresh token reuse (same token used twice)

## Verification and Follow-up
- Test login flow with valid/invalid credentials
- Test access token expiry and automatic refresh
- Test refresh token rotation (old token invalidated)
- Test logout (refresh token revoked)
- Test concurrent refresh requests (no race conditions)
- Test token theft detection (reuse of old refresh token)
- Verify tokens are not logged or exposed in errors
- Test secure storage on iOS and Android
- Document token lifecycle and security measures

## References
- JWT RFC: https://tools.ietf.org/html/rfc7519
- Refresh token rotation: https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/
- Fastify JWT plugin: https://github.com/fastify/fastify-jwt
