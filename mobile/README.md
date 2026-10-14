# KYC Mobile App

Flutter mobile application for KYC onboarding (iOS + Android).

## Setup

See [main README](../README.md) for prerequisites and overall project setup.

## Quick Start

```bash
# Get dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Run the app
flutter run

# Run tests
flutter test
```

## Architecture

- **State Management**: Riverpod with code generation
- **Folder Structure**: Feature-based organization
- **Pattern**: Clean Architecture (presentation/domain/data layers)

## Features

- Authentication (login, logout, session management)
- Personal details collection
- Document capture (camera)
- Selfie capture (camera)
- Review and submission
- Verification status tracking
- Resume capability

## Testing

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test integration_test/
```

## Code Generation

Riverpod uses code generation. Run after adding/changing providers:

```bash
flutter pub run build_runner build
```

Or watch mode for continuous generation:

```bash
flutter pub run build_runner watch
```

## Dependencies

Key dependencies (see `pubspec.yaml` for full list):
- `flutter_riverpod` - State management
- `riverpod_annotation` - Provider annotations
- `dio` - HTTP client
- `flutter_secure_storage` - Secure token storage
- `camera` - Camera access
- `freezed` - Immutable models

## Platform Setup

### iOS
- Requires Xcode 14+
- Minimum iOS version: 12.0
- Configure camera permissions in `ios/Runner/Info.plist`

### Android
- Requires Android Studio
- Minimum SDK version: 21
- Configure camera permissions in `android/app/src/main/AndroidManifest.xml`
