# POST /user/personal-details

Save or update user's personal details for KYC verification.

## Authentication

**Required**: Bearer token in Authorization header

```
Authorization: Bearer <access_token>
```

## Request

### Headers
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

### Body
```json
{
  "dateOfBirth": "1990-01-15",
  "nationality": "American",
  "phone": "+1234567890",
  "address": {
    "street": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "postalCode": "10001",
    "country": "USA"
  }
}
```

### Validation Rules

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `dateOfBirth` | string (date) | ✅ | Valid date format (YYYY-MM-DD) |
| `nationality` | string | ✅ | Min 2 characters |
| `phone` | string | ✅ | Valid phone format (min 10 digits, can include +, spaces, dashes) |
| `address.street` | string | ✅ | Min 2 characters |
| `address.city` | string | ✅ | Min 2 characters |
| `address.state` | string | ✅ | Min 2 characters |
| `address.postalCode` | string | ✅ | Min 3 characters |
| `address.country` | string | ✅ | Min 2 characters |

## Response

### Success (201 Created) - First Time

```json
{
  "message": "Personal details saved successfully",
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

### Success (200 OK) - Update Existing

```json
{
  "message": "Personal details updated successfully",
  "personalDetails": {
    "userId": "507f1f77bcf86cd799439011",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "nationality": "American",
    "phone": "+1234567890",
    "address": {
      "street": "456 Oak Avenue",
      "city": "Brooklyn",
      "state": "NY",
      "postalCode": "11201",
      "country": "USA"
    },
    "createdAt": "2026-10-15T12:00:00.000Z",
    "updatedAt": "2026-10-15T12:30:00.000Z"
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

#### 400 Bad Request - Validation Error
```json
{
  "error": "body/dateOfBirth must match format \"date\""
}
```

#### 400 Bad Request - Invalid Phone
```json
{
  "error": "body/phone must match pattern \"^\\+?[\\d\\s-]{10,}$\""
}
```

## Examples

### cURL

```bash
curl -X POST http://localhost:3000/user/personal-details \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "dateOfBirth": "1990-01-15",
    "nationality": "American",
    "phone": "+1234567890",
    "address": {
      "street": "123 Main Street",
      "city": "New York",
      "state": "NY",
      "postalCode": "10001",
      "country": "USA"
    }
  }'
```

### JavaScript (Fetch)

```javascript
const response = await fetch('http://localhost:3000/user/personal-details', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  },
  body: JSON.stringify({
    dateOfBirth: '1990-01-15',
    nationality: 'American',
    phone: '+1234567890',
    address: {
      street: '123 Main Street',
      city: 'New York',
      state: 'NY',
      postalCode: '10001',
      country: 'USA',
    },
  }),
});

const data = await response.json();
console.log(data);
```

### Dart (Flutter)

```dart
import 'dart:convert';
import 'package:http/http.dart';

Future<Map<String, dynamic>> savePersonalDetails(String token) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/user/personal-details'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'dateOfBirth': '1990-01-15',
      'nationality': 'American',
      'phone': '+1234567890',
      'address': {
        'street': '123 Main Street',
        'city': 'New York',
        'state': 'NY',
        'postalCode': '10001',
        'country': 'USA',
      },
    }),
  );
  
  return jsonDecode(response.body);
}
```

## Notes

- **One-to-one relationship**: Each user can only have one personal details record
- **Upsert behavior**: If personal details already exist, they will be updated
- **Date format**: Use ISO 8601 date format (YYYY-MM-DD)
- **Phone format**: Must be at least 10 digits, can include +, spaces, dashes
- **Protected endpoint**: Requires valid access token
- **User-specific**: The userId is extracted from the JWT token, not from the request body

## Implementation Status

✅ **Implemented** - Fully functional with validation
