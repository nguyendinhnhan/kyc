# Login Endpoint

## Overview
Authenticate user and receive JWT tokens.

## Endpoint
```
POST /auth/login
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
  "email": "test@example.com",
  "password": "password123"
}
```

### Validation Rules
- `email` (required, string, valid email format)
- `password` (required, string, min 1 character)

## Response

### Success (200 OK)
```json
{
  "message": "Login successful",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJpYXQiOjE2OTczNTAwMDAsImV4cCI6MTY5NzM1MDkwMH0.abc123",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI1MDdmMWY3N2JjZjg2Y2Q3OTk0MzkwMTEiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoicmVmcmVzaCIsImlhdCI6MTY5NzM1MDAwMCwiZXhwIjoxNjk3OTU0ODAwfQ.xyz789",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "test@example.com",
    "fullName": "Test User",
    "createdAt": "2026-10-15T00:00:00.000Z"
  }
}
```

### Token Details
- **accessToken**: JWT token, expires in 15 minutes
- **refreshToken**: JWT token, expires in 7 days, includes `type: "refresh"` claim

### Error Responses

#### 400 Bad Request (Validation Error)
```json
{
  "error": "Validation failed"
}
```

#### 401 Unauthorized (Invalid Credentials)
```json
{
  "error": "Invalid email or password"
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
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Dart (Flutter)
```dart
final response = await http.post(
  Uri.parse('http://localhost:3000/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'test@example.com',
    'password': 'password123',
  }),
);

final data = jsonDecode(response.body);
final accessToken = data['accessToken'];
final refreshToken = data['refreshToken'];

// Store tokens securely
await secureStorage.write(key: 'accessToken', value: accessToken);
await secureStorage.write(key: 'refreshToken', value: refreshToken);
```

## Notes
- Store `accessToken` in memory (short-lived)
- Store `refreshToken` in secure storage (long-lived)
- Use `accessToken` for authenticated requests
- Use `refreshToken` to get new access tokens
- Password is compared using bcrypt
- Email is normalized to lowercase before lookup
