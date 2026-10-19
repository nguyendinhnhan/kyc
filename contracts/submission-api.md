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

## Interview-readiness corrections (2026-10-18)

The server owns transitions: drafts and rejected applications can be explicitly submitted;
submitted/under-review requests return the current record without changing its timestamp;
approved applications reject a new submission (409). Editing submitted, under-review,
or approved data returns 409. Correcting a rejected section clears only that section's
feedback and leaves status rejected until the user explicitly resubmits. Admin decisions
atomically require submitted/under_review; competing decisions return 409.

`Idempotency-Key` is optional for compatibility with the submitted client, and recommended
for every submission. Keys contain 8–128 letters, digits, underscores or hyphens. A key is
scoped to the authenticated owner and empty submission operation. Successful keys persist
with the submission; replay returns its current representation without another transition,
even if a reviewer has since changed the status. GET /user/submission reconciles a lost
response. A new logical resubmission uses a new key. Flutter persists an outstanding key
in secure storage until a successful response or logout. DELETE /user/submission remains
as a compatibility alias for explicit submission, using the same rules.

Image writes do not automatically retry timeouts. Reconcile metadata through the protected
GET endpoints before replacing an uncertain upload. Only a 401 received before the handler
runs is eligible for one authenticated replay.
