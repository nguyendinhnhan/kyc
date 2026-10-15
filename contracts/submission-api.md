# Submission API Contract

## Overview
Endpoints for submitting KYC applications and tracking submission status.

## Authentication
All endpoints require JWT authentication. Include the access token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Submit KYC

### Endpoint
```
POST /user/submit
```

### Description
Submit the KYC application for verification. This endpoint validates that all required information has been provided before allowing submission.

### Requirements
Before submission, the following must be completed:
1. **Personal Details** - User must have saved their personal information
2. **Document Upload** - User must have uploaded at least one identity document
3. **Selfie Capture** - User must have captured and uploaded a selfie

### Response

**Success (200 OK)**
```json
{
  "message": "KYC submitted successfully",
  "submission": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "507f191e810c19729de860ea",
    "status": "submitted",
    "submittedAt": "2026-10-15T10:30:00.000Z",
    "createdAt": "2026-10-15T10:30:00.000Z",
    "updatedAt": "2026-10-15T10:30:00.000Z"
  }
}
```

**Error Responses**

400 Bad Request - Missing Personal Details
```json
{
  "error": "Personal details are required before submission"
}
```

400 Bad Request - Missing Documents
```json
{
  "error": "At least one document is required before submission"
}
```

400 Bad Request - Missing Selfie
```json
{
  "error": "Selfie is required before submission"
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
  "error": "Failed to submit KYC"
}
```

---

## Get Submission

### Endpoint
```
GET /user/submission
```

### Description
Retrieve the user's KYC submission status and information.

### Response

**Success (200 OK)**

With submission:
```json
{
  "submission": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "507f191e810c19729de860ea",
    "status": "submitted",
    "submittedAt": "2026-10-15T10:30:00.000Z",
    "reviewedAt": null,
    "notes": null,
    "createdAt": "2026-10-15T10:30:00.000Z",
    "updatedAt": "2026-10-15T10:30:00.000Z"
  }
}
```

Without submission:
```json
{
  "submission": null
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
  "error": "Failed to retrieve submission"
}
```

---

## Data Model

### Submission Object
| Field | Type | Description |
|-------|------|-------------|
| `_id` | string | Unique identifier for the submission |
| `userId` | string | ID of the user who submitted |
| `status` | string | Submission status (see below) |
| `submittedAt` | string \| null | ISO 8601 timestamp of submission |
| `reviewedAt` | string \| null | ISO 8601 timestamp of review |
| `reviewedBy` | string \| null | ID of the reviewer |
| `notes` | string \| null | Additional notes from reviewer |
| `createdAt` | string | ISO 8601 timestamp of record creation |
| `updatedAt` | string | ISO 8601 timestamp of last update |

---

## Status Values

| Status | Description |
|--------|-------------|
| `draft` | Submission started but not yet submitted |
| `submitted` | Submission completed and awaiting review |
| `under_review` | Submission is being reviewed by staff |
| `approved` | Submission approved - KYC complete |
| `rejected` | Submission rejected - needs corrections |

---

## Workflow

1. **User completes all requirements:**
   - Personal details
   - Document upload (at least one)
   - Selfie capture

2. **User submits KYC:**
   - System validates all requirements are met
   - Creates submission record with status `submitted`
   - Records submission timestamp

3. **Review process:**
   - Status changes to `under_review` when review begins
   - Status changes to `approved` or `rejected` after review
   - Reviewer can add notes

4. **User checks status:**
   - User can retrieve submission to check current status
   - User sees "already submitted" view if submission exists

---

## Notes

- Only one submission is allowed per user
- Re-submitting will update the existing submission record
- All requirements must be met before submission is allowed
- Submission is a one-way process (cannot be undone by user)
- Reviewer can change status and add notes through admin interface
