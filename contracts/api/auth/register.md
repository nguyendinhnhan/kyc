# Register Endpoint

## Overview
Register a new user account.

## Endpoint
```
POST /auth/register
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
  "password": "password123",
  "fullName": "Test User"
}
```

### Validation Rules
- `email` (required, string, valid email format)
- `password` (required, string, min 8 characters)
- `fullName` (required, string, min 2 characters)

## Response

### Success (201 Created)
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "test@example.com",
    "fullName": "Test User",
    "createdAt": "2026-10-15T00:00:00.000Z"
  }
}
```

### Error Responses

#### 400 Bad Request (Validation Error)
```json
{
  "error": "Validation failed",
  "details": "body/email must match format \"email\""
}
```

#### 409 Conflict (Duplicate Email)
```json
{
  "error": "Email already registered"
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
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "fullName": "Test User"
  }'
```

### JavaScript (Fetch)
```javascript
const response = await fetch('http://localhost:3000/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'test@example.com',
    password: 'password123',
    fullName: 'Test User',
  }),
});

const data = await response.json();
```

### Dart (Flutter)
```dart
final response = await http.post(
  Uri.parse('http://localhost:3000/auth/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': 'test@example.com',
    'password': 'password123',
    'fullName': 'Test User',
  }),
);

final data = jsonDecode(response.body);
```

## Notes
- Password is hashed before storage (bcrypt)
- Email is normalized to lowercase
- User is automatically created with no KYC data
- Next step: Login to receive JWT tokens
