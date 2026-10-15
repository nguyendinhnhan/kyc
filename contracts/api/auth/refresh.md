# Refresh Token Endpoint

## Overview
Get new access and refresh tokens using a valid refresh token.

## Endpoint
```
POST /auth/refresh
```

## Request

### Headers
```json
{
  "Content-Type": "application/json"
}
```

### Body
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoicmVmcmVzaCIsImlhdCI6MTY5NzM1MDAwMCwiZXhwIjoxNjk3OTU0ODAwfQ.xyz789"
}
```

### Validation Rules
- `refreshToken` (required, string, min 1 character, must be a valid refresh token)

## Response

### Success (200 OK)
```json
{
  "message": "Token refreshed successfully",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJpYXQiOjE2OTczNTAwMDAsImV4cCI6MTY5NzM1MDkwMH0.newToken123",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoicmVmcmVzaCIsImlhdCI6MTY5NzM1MDAwMCwiZXhwIjoxNjk3OTU0ODAwfQ.newRefresh456"
}
```

### Token Rotation
- Both tokens are rotated (new tokens issued)
- Old refresh token is invalidated
- New accessToken expires in 15 minutes
- New refreshToken expires in 7 days

### Error Responses

#### 400 Bad Request (Validation Error)
```json
{
  "error": "Validation failed"
}
```

#### 401 Unauthorized (Invalid Token)
```json
{
  "error": "Invalid refresh token"
}
```

#### 500 Internal Server Error
```json
{
  "error": "Internal server error"
}
```

## Example Usage

### cURL
```bash
curl -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN"
  }'
```

### Dart (Flutter)
```dart
final response = await http.post(
  Uri.parse('http://localhost:3000/auth/refresh'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'refreshToken': storedRefreshToken,
  }),
);

final data = jsonDecode(response.body);

// Update stored tokens
await secureStorage.write(key: 'accessToken', value: data['accessToken']);
await secureStorage.write(key: 'refreshToken', value: data['refreshToken']);
```

## Implementation Flow

### Automatic Token Refresh (Recommended)
```dart
class ApiService {
  Future<void> makeAuthenticatedRequest() async {
    var accessToken = await secureStorage.read(key: 'accessToken');
    
    var response = await http.get(
      Uri.parse('http://localhost:3000/protected-endpoint'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    
    // If token expired (401), refresh and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshTokens();
      if (refreshed) {
        accessToken = await secureStorage.read(key: 'accessToken');
        response = await http.get(
          Uri.parse('http://localhost:3000/protected-endpoint'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      } else {
        // Redirect to login
        await logout();
      }
    }
  }
  
  Future<bool> refreshTokens() async {
    final refreshToken = await secureStorage.read(key: 'refreshToken');
    final response = await http.post(
      Uri.parse('http://localhost:3000/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await secureStorage.write(key: 'accessToken', value: data['accessToken']);
      await secureStorage.write(key: 'refreshToken', value: data['refreshToken']);
      return true;
    }
    return false;
  }
}
```

## Notes
- Implement automatic token refresh when accessToken expires
- Always rotate both tokens for security
- Store new tokens in secure storage
- Handle 401 errors by redirecting to login
- Refresh token includes `type: "refresh"` claim to distinguish from access token
- If refresh fails, user must login again
