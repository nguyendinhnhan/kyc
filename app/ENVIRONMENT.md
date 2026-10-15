# Environment Configuration

This document describes how to configure environment variables for the Flutter app.

## Overview

The app uses `flutter_dotenv` to manage environment-specific configuration. Environment files are located in the `app/` directory.

## Environment Files

### `.env.development`
- **Purpose**: Local development environment
- **API Base URL**: `http://localhost:3000`
- **Logging**: Enabled
- **Analytics**: Disabled

### `.env.staging`
- **Purpose**: Staging/testing environment
- **API Base URL**: `https://staging-api.kyc-app.com`
- **Logging**: Enabled
- **Analytics**: Disabled

### `.env.production`
- **Purpose**: Production environment
- **API Base URL**: `https://api.kyc-app.com`
- **Logging**: Disabled
- **Analytics**: Enabled

### `.env.example`
- **Purpose**: Template for creating new environment files
- **Usage**: Copy to `.env.[environment]` and customize

## Configuration Variables

### API Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | Base URL for the backend API | `http://localhost:3000` |
| `API_CONNECT_TIMEOUT` | Connection timeout in milliseconds | `10000` |
| `API_RECEIVE_TIMEOUT` | Receive timeout in milliseconds | `10000` |

### App Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_NAME` | Display name of the app | `KYC Onboarding` |
| `APP_ENV` | Environment name (development/staging/production) | `development` |

### Feature Flags

| Variable | Description | Default |
|----------|-------------|---------|
| `ENABLE_LOGGING` | Enable debug logging | `true` |
| `ENABLE_ANALYTICS` | Enable analytics tracking | `false` |

## Usage

### Accessing Configuration in Code

```dart
import 'package:kyc_app/core/config/app_config.dart';

// Get API base URL
final baseUrl = AppConfig.apiBaseUrl;

// Check environment
if (AppConfig.isDevelopment) {
  // Development-specific code
}

// Get feature flags
if (AppConfig.enableLogging) {
  print('Debug: ...');
}
```

### Running with Different Environments

By default, the app loads `.env.development`. To use a different environment:

1. Update `lib/main.dart`:
```dart
await dotenv.load(fileName: '.env.production');
```

2. Or use flavors (recommended for production):
```dart
// main_dev.dart
await dotenv.load(fileName: '.env.development');

// main_prod.dart
await dotenv.load(fileName: '.env.production');
```

## Adding New Variables

1. Add to `.env.example`:
```env
NEW_VARIABLE=value
```

2. Add to each environment file (`.env.development`, `.env.staging`, `.env.production`):
```env
NEW_VARIABLE=environment_specific_value
```

3. Add getter to `lib/core/config/app_config.dart`:
```dart
static String get newVariable => dotenv.env['NEW_VARIABLE'] ?? 'default';
```

4. Use in code:
```dart
final value = AppConfig.newVariable;
```

## Security Note

⚠️ **Important**: Never commit sensitive data (API keys, secrets, passwords) to `.env` files in version control.

For sensitive data:
- Use `.env.local` (gitignored)
- Use secure storage (flutter_secure_storage)
- Use environment-specific build configurations

## Git Rules

The following `.env` files are tracked in git:
- ✅ `.env.development`
- ✅ `.env.staging`
- ✅ `.env.production`
- ✅ `.env.example`

The following are gitignored:
- ❌ `.env`
- ❌ `.env.local`
- ❌ `.env.*.local`

## Example: Adding a New API Endpoint

1. Add to `.env.development`:
```env
API_DOCUMENT_UPLOAD_URL=http://localhost:3000/documents/upload
```

2. Add to `.env.production`:
```env
API_DOCUMENT_UPLOAD_URL=https://api.kyc-app.com/documents/upload
```

3. Add to `app_config.dart`:
```dart
static String get apiDocumentUploadUrl => 
    dotenv.env['API_DOCUMENT_UPLOAD_URL'] ?? '$apiBaseUrl/documents/upload';
```

4. Use in code:
```dart
final uploadUrl = AppConfig.apiDocumentUploadUrl;
```
