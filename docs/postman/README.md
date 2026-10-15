# Postman Collections

This directory contains Postman collections for testing the KYC Backend API.

## Available Collections

### KYC_Auth_API.postman_collection.json

Complete authentication API collection with:
- **Register** - Create new user account
- **Login** - Authenticate and get JWT tokens
- **Refresh Token** - Get new tokens using refresh token
- **Error scenarios** - Test validation and error handling

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

3. **Test the endpoints** in this order:
   - Run **Register** → Creates a new user
   - Run **Login** → Gets tokens (automatically saved)
   - Run **Refresh Token** → Uses saved refresh token
   - Try error scenarios to test validation

## Features

- ✅ **Auto-saves tokens** - After login/refresh, tokens are automatically saved to collection variables
- ✅ **Test scripts** - Each request includes tests to verify responses
- ✅ **Error scenarios** - Pre-configured requests to test validation and error handling
- ✅ **Environment variables** - baseUrl, accessToken, refreshToken, userId are managed automatically

## Collection Variables

The collection automatically manages these variables:
- `baseUrl` - API base URL (default: http://localhost:3000)
- `accessToken` - JWT access token (auto-saved after login)
- `refreshToken` - JWT refresh token (auto-saved after login)
- `userId` - Registered user ID (auto-saved after register)

## Quick Test Flow

1. **Register** → Creates user, saves userId
2. **Login** → Gets tokens, saves accessToken & refreshToken
3. **Refresh Token** → Uses saved refreshToken to get new tokens
4. **Duplicate Email** → Should return 409 Conflict
5. **Wrong Password** → Should return 401 Unauthorized

## Environment-Specific Configuration

To test against different environments:
1. Create a Postman Environment
2. Set `baseUrl` to your target URL (e.g., `https://api.yourdomain.com`)
3. Select the environment before running requests
