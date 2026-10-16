# KYC API Testing Guide

This guide explains how to test the KYC backend API using the Postman collection.

## Prerequisites

1. **Backend Running**: Ensure the backend is running on `http://localhost:3000`
2. **MongoDB Connected**: Verify MongoDB connection is active
3. **Postman**: Import `KYC_Auth_API.postman_collection.json` into Postman

## Setup

### 1. Import Collection
- Open Postman
- Click **Import**
- Select `docs/postman/KYC_Auth_API.postman_collection.json`

### 2. Create Admin User
Before testing admin endpoints, you need an admin user:

```bash
cd backend
node scripts/create-admin.js admin@kyc.com Admin123!
```

This creates an admin user with:
- Email: `admin@kyc.com`
- Password: `Admin123!`
- Role: `admin`

### 3. Create Test User
Register a regular user through the Postman collection:
1. Run **Auth → Register** (uses `test@example.com`)
2. Run **Auth → Login**
   - This automatically saves `accessToken`, `refreshToken`, and `userId` to collection variables

## Testing the Complete KYC Flow

### Phase 1: User Application

#### Step 1: Save Personal Details
**Request**: `User → Save Personal Details`
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

#### Step 2: Upload Document
**Request**: `User → Upload Document`
- **type**: `passport`
- **documentNumber**: `AB123456`
- **file**: Select a clear ID document image (JPG/PNG)

#### Step 3: Upload Selfie
**Request**: `User → Upload Selfie`
- **file**: Select a selfie image that matches the ID document

#### Step 4: Submit Application
**Request**: `User → Submit KYC`
- This creates a submission with status `submitted`
- The `submissionId` is automatically saved to collection variables

#### Step 5: Verify Submission Status
**Request**: `User → Get Submission`
- Should show status: `submitted`
- Should have `submittedAt` timestamp

---

### Phase 2: Admin Review

#### Step 1: Login as Admin
**Request**: `Auth → Login`
- Change email to: `admin@kyc.com`
- Password: `Admin123!`
- This saves the admin's `accessToken`

#### Step 2: List All Submissions
**Request**: `Admin → List All Submissions`
- Query parameters:
  - `page`: 1
  - `limit`: 20
  - `status`: (optional) filter by status
- The first submission's ID is automatically saved to `submissionId`

**Expected Response**:
```json
{
  "submissions": [
    {
      "_id": "...",
      "userId": "...",
      "status": "submitted",
      "submittedAt": "...",
      "user": {
        "fullName": "Test User",
        "email": "test@example.com"
      }
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 20,
    "pages": 1
  }
}
```

#### Step 3: Get Submission Details
**Request**: `Admin → Get Submission Details`
- Uses the `submissionId` from previous step
- Returns full details including personal info, documents, and selfie

**Expected Response**:
```json
{
  "submission": {
    "_id": "...",
    "status": "submitted",
    "submittedAt": "..."
  },
  "personalDetails": {
    "fullName": "Test User",
    "dateOfBirth": "1990-01-15",
    "nationality": "American",
    "phone": "+1234567890",
    "address": { ... }
  },
  "documents": [
    {
      "type": "passport",
      "documentNumber": "AB123456",
      "filePath": "/uploads/...",
      "status": "pending"
    }
  ],
  "selfie": {
    "filePath": "/uploads/...",
    "status": "pending"
  }
}
```

#### Step 4A: Approve Submission
**Request**: `Admin → Approve Submission`
```json
{
  "notes": "All documents verified successfully"
}
```

**Expected Response**:
```json
{
  "message": "Submission approved successfully",
  "submission": {
    "status": "approved",
    "reviewedAt": "...",
    "reviewNotes": "All documents verified successfully"
  }
}
```

#### Step 4B: Reject Submission (Structured)
**Request**: `Admin → Reject Submission (Structured)`
```json
{
  "rejectionDetails": {
    "personalDetails": {
      "phone": "Invalid format, must include country code"
    },
    "documents": {
      "imageQuality": "Image is blurry, please retake in better lighting",
      "documentNumber": "Number doesn't match passport format"
    },
    "selfie": {
      "faceMatch": "Selfie doesn't clearly match ID photo"
    },
    "generalNotes": "Please ensure good lighting and clear focus"
  }
}
```

**Expected Response**:
```json
{
  "message": "Submission rejected with feedback",
  "submission": {
    "status": "rejected",
    "reviewedAt": "...",
    "rejectionDetails": {
      "personalDetails": {
        "phone": "Invalid format, must include country code"
      },
      "documents": {
        "imageQuality": "Image is blurry, please retake in better lighting",
        "documentNumber": "Number doesn't match passport format"
      },
      "selfie": {
        "faceMatch": "Selfie doesn't clearly match ID photo"
      },
      "generalNotes": "Please ensure good lighting and clear focus"
    }
  }
}
```

#### Step 5: Get Admin Stats
**Request**: `Admin → Get Admin Stats`

**Expected Response**:
```json
{
  "stats": {
    "total": 10,
    "submitted": 3,
    "under_review": 2,
    "approved": 4,
    "rejected": 1
  }
}
```

---

### Phase 3: User Resubmission (After Rejection)

#### Step 1: Login as User Again
**Request**: `Auth → Login`
- Email: `test@example.com`
- Password: `password123`

#### Step 2: Check Submission Status
**Request**: `User → Get Submission`
- Should show status: `rejected`
- Should include `rejectionDetails` with field-specific errors
- Should include `reviewedAt` timestamp

#### Step 3: View Rejection Details in App
In the Flutter app:
1. Open the app and login as the test user
2. Navigate to Review & Submit screen
3. You should see:
   - Status: "Rejected"
   - Categorized rejection reasons with icons
   - General notes from admin
   - "Resubmit Application" button

#### Step 4: Fix Issues and Resubmit
The app will show field-level errors:
- **Personal Details**: Red error text on invalid fields (phone, etc.)
- **Documents**: Red border and error message for image quality, error text for document number
- **Selfie**: Red border and error messages for image quality and face match

After fixing:
1. Update invalid fields
2. Re-upload documents/selfie if needed
3. Click "Resubmit Application" on Review screen
4. This calls `DELETE /user/submission` to reset status to `draft`
5. Then submit again with `POST /user/submit`

#### Step 5: Reset Submission (API)
**Request**: `User → Reset Submission (Resubmit)`
- Only works for rejected submissions
- Resets status to `draft`
- Preserves documents and selfie for editing

**Expected Response**:
```json
{
  "message": "Submission reset to draft. You can now edit and resubmit.",
  "submission": {
    "status": "draft",
    "rejectionDetails": null,
    "reviewedAt": null
  }
}
```

---

## Testing Scenarios

### Scenario 1: Full Approval Flow
1. User completes all steps and submits
2. Admin reviews and approves
3. User sees "Approved" status in app

### Scenario 2: Rejection and Resubmission
1. User submits application
2. Admin rejects with structured feedback
3. User sees detailed rejection reasons in app
4. User fixes issues and resubmits
5. Admin reviews again and approves

### Scenario 3: Partial Field Errors
Test rejecting only specific fields:
```json
{
  "rejectionDetails": {
    "documents": {
      "imageQuality": "Image too dark"
    }
  }
}
```
Only the document upload screen should show errors.

### Scenario 4: Multiple Document Types
1. Upload passport
2. Admin rejects passport document number
3. User switches to driver's license
4. User resubmits

### Scenario 5: Admin Dashboard
1. Create multiple test users
2. Submit applications from each
3. Use admin stats to see distribution
4. Filter by status in list endpoint

---

## Error Cases

### Test Invalid Status Transitions

**Try to approve an already approved submission**:
- Should return 400: "Submission is not in submitted or under_review status"

**Try to reset a non-rejected submission**:
- Should return 400: "Only rejected submissions can be reset"

**Try to access admin endpoints as regular user**:
- Should return 403: "Forbidden"

### Test Missing Data

**Submit without personal details**:
- Should return 400: "Personal details are required"

**Submit without documents**:
- Should return 400: "At least one document is required"

**Submit without selfie**:
- Should return 400: "Selfie is required"

---

## Image Endpoints

### Get Selfie Image
**Request**: `GET /user/selfie/image`
- Returns the selfie image file
- Requires authentication
- Returns 404 if no selfie uploaded

### Get Document Image
**Request**: `GET /user/documents/:id/image`
- Returns the document image file
- Requires authentication
- Returns 404 if document not found
- Validates ownership

---

## Collection Variables

The collection automatically manages these variables:
- `baseUrl`: `http://localhost:3000`
- `accessToken`: Current user's JWT access token
- `refreshToken`: Current user's refresh token
- `userId`: Current user's ID
- `submissionId`: Latest submission ID (set after submit or list)

---

## Troubleshooting

### "Unauthorized" Error
- Check if `accessToken` is set (run Login first)
- Token may have expired (default: 15 minutes)
- Run `Auth → Refresh Token` to get new access token

### "Forbidden" Error on Admin Endpoints
- You're logged in as a regular user
- Login as admin: `admin@kyc.com` / `Admin123!`

### "Submission not found" Error
- Run `User → Submit KYC` first
- Check if `submissionId` is set in collection variables

### "Cannot read properties of undefined" in Admin Endpoints
- Ensure you have submissions in the database
- Run `Admin → List All Submissions` first to populate `submissionId`

### Images Not Loading in App
- Check backend logs for image serving errors
- Verify files exist in `backend/uploads/`
- Check file permissions

---

## API Response Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (duplicate email) |
| 500 | Server Error |

---

## Next Steps

After testing the API:
1. Test the Flutter app UI end-to-end
2. Verify rejection details display correctly in app
3. Test resubmission flow in app
4. Check image display on Review screen
5. Verify status indicators on Home screen
