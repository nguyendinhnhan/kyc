# Flutter environments

Configuration files contain public build configuration only. Flutter bundles these assets;
`.env.local` and build variables cannot hide a secret inside a mobile application. Keep
backend signing secrets, storage credentials, and real identity data out of every asset.

```bash
flutter run --dart-define=APP_ENV=development
flutter run --dart-define=APP_ENV=staging
flutter run --dart-define=APP_ENV=production
```

`main.dart` validates APP_ENV and loads the matching bundled `.env.<environment>`. The
default is development. APP_ENV inside the selected file should match the build selection.
Staging and production URLs are configuration placeholders until you deploy a real API;
these commands do not establish deployment readiness.

API_BASE_URL is the single API origin. Set it for the chosen device: localhost works on the
iOS simulator; Android emulator normally needs 10.0.2.2; a physical device needs a reachable
laptop address. The backend listens on port 3000. HTTP is for explicitly local development;
use HTTPS for staging/production. Device-specific transport permissions still need a run
check on the actual platform.

Other supported values are APP_NAME, API_CONNECT_TIMEOUT (default 30000 ms),
API_RECEIVE_TIMEOUT (default 60000 ms), ENABLE_LOGGING and ENABLE_ANALYTICS. The flags are
configuration values, not proof of an analytics integration. Do not add per-endpoint origins;
repositories use paths relative to API_BASE_URL.

Start MongoDB and the backend first; see [backend instructions](../backend/README.md).
