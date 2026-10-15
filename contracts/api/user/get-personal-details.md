# GET /user/personal-details

Retrieve user's personal details for KYC verification.

## Authentication

**Required**: Bearer token in Authorization header

```
Authorization: Bearer <access_token>
```

## Request

### Headers
```
Authorization: Bearer <access_token>
```

### Query Parameters
None

## Response

### Success (200 OK)

```json
{
  "personalDetails": {
    "userId": "507f1f77bcf86cd799439011",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "nationality": "American",
    "phone": "+1234567890",
    "address": {
      "street": "123 Main Street",
      "city": "New York",
      "state": "NY",
      "postalCode": "10001",
      "country": "USA"
    },
    "createdAt": "2026-10-15T12:00:00.000Z",
    "updatedAt": "2026-10-15T12:00:00.000Z"
  }
}
```

### Error Responses

#### 401 Unauthorized
```json
{
  "error": "No authorization header provided"
}
```

#### 404 Not Found
```json
{
  "error": "Personal details not found"
}
```

## Examples

### cURL

```bash
curl -X GET http://localhost:3000/user/personal-details \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### JavaScript (Fetch)

```javascript
const response = await fetch('http://localhost:3000/user/personal-details', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  },
});

const data = await response.json();
console.log(data.personalDetails);
```

### Dart (Flutter)

```dart
import 'dart:convert';
import 'package:http/http.dart';

Future<Map<String, dynamic>> getPersonalDetails(String token) async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/user/personal-details'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  
  return jsonDecode(response.body);
}
```

## Notes

- **Protected endpoint**: Requires valid access token
- **User-specific**: Returns only the personal details for the authenticated user
- **404 if not found**: Returns 404 if user hasn't saved personal details yet
- **Read-only**: This endpoint only retrieves data, use POST to create/update

## Implementation Status

✅ **Implemented** - Fully functional
