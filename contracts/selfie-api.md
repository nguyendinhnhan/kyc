# Selfie API Contract

## Overview
Endpoints for capturing and managing user selfies for KYC verification.

## Authentication
All endpoints require JWT authentication. Include the access token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Upload Selfie

### Endpoint
```
POST /user/selfie
```

### Description
Upload a selfie image for KYC verification. If a selfie already exists, it will be replaced.

### Request
**Content-Type:** `multipart/form-data`

**Body:**
- `file` (required): Image file (JPEG, PNG, or JPG)

### Response

**Success (201 Created)**
```json
{
  "message": "Selfie uploaded successfully",
  "selfie": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "507f191e810c19729de860ea",
    "filePath": "/path/to/uploads/uuid.jpg",
    "fileName": "selfie.jpg",
    "mimeType": "image/jpeg",
    "fileSize": 12345,
    "uploadedAt": "2026-10-15T10:30:00.000Z",
    "status": "pending",
    "createdAt": "2026-10-15T10:30:00.000Z",
    "updatedAt": "2026-10-15T10:30:00.000Z"
  }
}
```

**Error Responses**

400 Bad Request
```json
{
  "error": "No file uploaded"
}
```

```json
{
  "error": "File must be an image (JPEG, PNG, or JPG)"
}
```

401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

500 Internal Server Error
```json
{
  "error": "Failed to upload selfie"
}
```

---

## Get Selfie

### Endpoint
```
GET /user/selfie
```

### Description
Retrieve the user's uploaded selfie information.

### Response

**Success (200 OK)**

With selfie:
```json
{
  "selfie": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "507f191e810c19729de860ea",
    "filePath": "/path/to/uploads/uuid.jpg",
    "fileName": "selfie.jpg",
    "mimeType": "image/jpeg",
    "fileSize": 12345,
    "uploadedAt": "2026-10-15T10:30:00.000Z",
    "status": "pending",
    "createdAt": "2026-10-15T10:30:00.000Z",
    "updatedAt": "2026-10-15T10:30:00.000Z"
  }
}
```

Without selfie:
```json
{
  "selfie": null
}
```

**Error Responses**

401 Unauthorized
```json
{
  "error": "Unauthorized"
}
```

500 Internal Server Error
```json
{
  "error": "Failed to retrieve selfie"
}
```

---

## Data Model

### Selfie Object
| Field | Type | Description |
|-------|------|-------------|
| `_id` | string | Unique identifier for the selfie |
| `userId` | string | ID of the user who uploaded the selfie |
| `filePath` | string | Path to the stored selfie file |
| `fileName` | string | Original filename |
| `mimeType` | string | MIME type (image/jpeg, image/png, image/jpg) |
| `fileSize` | number | File size in bytes |
| `uploadedAt` | string | ISO 8601 timestamp of upload |
| `status` | string | Verification status: `pending`, `approved`, or `rejected` |
| `createdAt` | string | ISO 8601 timestamp of record creation |
| `updatedAt` | string | ISO 8601 timestamp of last update |

---

## Status Values

| Status | Description |
|--------|-------------|
| `pending` | Selfie uploaded, awaiting verification |
| `approved` | Selfie approved by verification system |
| `rejected` | Selfie rejected, needs to be retaken |

---

## Notes

- Only one selfie is allowed per user
- Uploading a new selfie will replace any existing selfie
- Selfies are stored in the `uploads/` directory with UUID filenames
- Supported formats: JPEG, PNG, JPG
- Front camera is recommended for selfie capture
