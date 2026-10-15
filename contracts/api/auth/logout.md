# Logout Endpoint

## Overview
Invalidate user's refresh token and log them out.

## Status
**⏳ TODO** - This endpoint is not yet implemented.

## Endpoint
```
POST /auth/logout
```

## Request

### Headers
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer YOUR_ACCESS_TOKEN"
}
```

### Body
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Validation Rules
- `refreshToken` (required, string)
- Requires valid access token in Authorization header

## Response

### Success (200 OK)
```json
{
  "message": "Logged out successfully"
}
```

### Error Responses

#### 400 Bad Request
```json
{
  "error": "Validation failed"
}
```

#### 401 Unauthorized
```json
{
  "error": "Invalid token"
}
```

## Planned Implementation

### Features
- Invalidate refresh token
- Add token to blacklist (in-memory or database)
- Require authentication
- Clear user session

### Security Considerations
- Refresh token should be blacklisted
- Access token will naturally expire (15 minutes)
- Consider implementing token blacklist with TTL
- May need to invalidate all active sessions for user

## Example Usage (Planned)

### cURL
```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

### Dart (Flutter)
```dart
Future<void> logout() async {
  final accessToken = await secureStorage.read(key: 'accessToken');
  final refreshToken = await secureStorage.read(key: 'refreshToken');
  
  await http.post(
    Uri.parse('http://localhost:3000/auth/logout'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({'refreshToken': refreshToken}),
  );
  
  // Clear stored tokens
  await secureStorage.delete(key: 'accessToken');
  await secureStorage.delete(key: 'refreshToken');
  
  // Redirect to login screen
}
```

## Implementation Priority
**Medium** - Can be deferred since:
- Refresh tokens expire in 7 days
- Access tokens expire in 15 minutes
- No persistent sessions currently
- Can implement later when needed

## Related Endpoints
- POST /auth/login - Get tokens
- POST /auth/refresh - Refresh tokens
- POST /auth/logout - Invalidate tokens (this endpoint)
