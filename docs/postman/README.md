# Postman Collections

This directory contains Postman collections for testing the KYC Backend API.

## Available Collections

### KYC_Auth_API.postman_collection.json

Complete API collection with:
- **Auth** - Register, Login, Refresh Token, Logout
- **User** - Personal Details, Documents, Selfie, Submission
- **Admin** - List Submissions, Get Details, Approve, Reject, Stats
- **Health** - Server health check
- **Error scenarios** - Test validation and error handling

## Documentation

- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Comprehensive guide for testing the complete KYC flow including rejection and resubmission

## How to Use

1. **Import the collection**:
   - Open Postman
   - Click "Import" button
   - Select `KYC_Auth_API.postman_collection.json`
   - Click "Import"

2. **Start the backend server**:
   ```bash
   cd backend
   npm run dev
   ```

3. **Create an admin user** (for testing admin endpoints):
   ```bash
   cd backend
   node scripts/create-admin.js admin@kyc.com Admin123!
   ```

4. **Test the endpoints** in this order:
   - Run **Auth → Register** → Creates a new user
   - Run **Auth → Login** → Gets tokens (automatically saved)
   - Run **User → Save Personal Details** → Save user information
   - Run **User → Upload Document** → Upload ID document
   - Run **User → Upload Selfie** → Upload selfie
   - Run **User → Submit KYC** → Submit for review
   - Login as admin and use **Admin** endpoints to review

## Features

- ✅ **Auto-saves tokens** - After login/refresh, tokens are automatically saved to collection variables
- ✅ **Test scripts** - Each request includes tests to verify responses
- ✅ **Error scenarios** - Pre-configured requests to test validation and error handling
- ✅ **Environment variables** - baseUrl, accessToken, refreshToken, userId, submissionId are managed automatically
- ✅ **Admin endpoints** - Full admin workflow for reviewing submissions
- ✅ **Structured rejection** - Field-level rejection details for precise feedback

## Collection Variables

The collection automatically manages these variables:
- `baseUrl` - API base URL (default: http://localhost:3000)
- `accessToken` - JWT access token (auto-saved after login)
- `refreshToken` - JWT refresh token (auto-saved after login)
- `userId` - Registered user ID (auto-saved after register)
- `submissionId` - Latest submission ID (auto-saved after submit or list)

## Quick Test Flow

### User Flow
1. **Register** → Creates user, saves userId
2. **Login** → Gets tokens, saves accessToken & refreshToken
3. **Save Personal Details** → Save user information
4. **Upload Document** → Upload ID document (select image file)
5. **Upload Selfie** → Upload selfie (select image file)
6. **Submit KYC** → Submit for review, saves submissionId
7. **Get Submission** → Check submission status

### Admin Flow
1. **Login as Admin** → Use admin credentials
2. **List All Submissions** → View all submissions, saves first submissionId
3. **Get Submission Details** → View full submission with user data
4. **Approve Submission** → Approve with notes
5. **Reject Submission** → Reject with structured field-level feedback
6. **Get Stats** → View dashboard statistics

### Resubmission Flow
1. **Get Submission** → User sees rejection details
2. **Fix issues** → Update invalid fields
3. **Reset Submission** → Reset to draft status
4. **Submit KYC** → Resubmit application

## Environment-Specific Configuration

To test against different environments:
1. Create a Postman Environment
2. Set `baseUrl` to your target URL (e.g., `https://api.yourdomain.com`)
3. Select the environment before running requests

## Error Cases to Test

- Register with duplicate email → 409 Conflict
- Login with wrong password → 401 Unauthorized
- Access user endpoints without token → 401 Unauthorized
- Access admin endpoints as regular user → 403 Forbidden
- Submit without required data → 400 Bad Request
- Reset non-rejected submission → 400 Bad Request
- Approve already approved submission → 400 Bad Request
