# Laptop interview guide

The submitted commit is `a6c6d77` on `main`. Corrections are on `fix/interview-readiness`.
The fixes are local working-tree changes until explicitly committed; do not switch branches
with them present and assume the working tree becomes the submitted version. No changes
have been pushed or resubmitted by this work.

## Start the demo

From the repository root, with Docker Desktop running:

```bash
docker compose -f backend/docker-compose.yml up -d mongodb
docker compose -f backend/docker-compose.yml ps mongodb
```

In a backend terminal:

```bash
cd backend
npm ci
npm run build
npm start
```

Check `http://localhost:3000/health`. Preserve the existing backend `.env`; do not overwrite
it. MongoDB uses a persistent named volume. Do not use database-cleaning scripts or
`docker compose down -v` to prepare the interview.

In a mobile terminal:

```bash
cd app
flutter pub get
flutter run --dart-define=APP_ENV=development
```

Set the public API_BASE_URL in `.env.development` for the actual device before running.
Use localhost for iOS simulator, normally 10.0.2.2 for Android emulator, or the laptop's
reachable network address for a physical device. A simulator with synthetic fixtures avoids
relying on the company network. MongoDB is bound only to laptop loopback; the app connects
to the backend, never directly to MongoDB.

Log in again after this update: old stateless JWTs intentionally have no valid server
session. Rehearse with synthetic data: login, save details, upload document, upload selfie,
review, submit, inspect status, reject via admin API, correct, explicitly resubmit, logout,
and log in as another account. No real identity verification vendor is integrated; admin
review is the real backend's decision mechanism.

## Checks

From `backend/`:

```bash
npm run build
npm test -- --run
npm run lint
npm run format:check
```

From `app/`:

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Tests use synthetic valid JPEG fixtures and isolated local MongoDB databases/temporary
uploads. They never clean the demo database. See [AI usage](ai-usage.md) for actual test
results and failing regression evidence. Passing unit/API tests does not establish a
successful iOS/Android device build or camera flow.

## Explain the changes

- Shared refresh Future and bounded replay replace the recursive lock; invalid login is
  never refreshed. Account-specific providers discard old data and late responses.
- Server sessions enable atomic refresh rotation and logout revocation; only digests are stored.
- Submission keys persist through uncertain responses; server status guards prevent an
  approved application being reset, and competing admin decisions have one winner.
- Rejected edits refresh server status and do not automatically submit.
- Images are decoded/re-encoded, limited, privately stored, and replaced before old-file cleanup.
- TypeScript/ESLint setup and the real-server health test are corrected.

## Remaining limits

Device camera permissions, retakes, backgrounding and process-death recovery need a real
run before claiming R1/R4/R5/R8/R10 complete. Unsaved local drafts/capture files are not yet
fully protected for durable offline resume. Filesystem permissions are not encryption.
Production S3, field encryption/key management, abandonment/orphan retention cleanup,
immutable submission snapshots and transactional edit/submit isolation remain follow-up
work. Local HTTP is exclusively a laptop-development assumption. Backend lint retains
existing style/type warnings. Do not claim production readiness or a new submitted version.

## Recorded verification on this laptop

Backend build, formatting check, and all 62 tests passed. Flutter's full 7-test suite passed;
final analysis reported no issues, and the 4 tests touching the final brace-only edits passed
again. Backend lint exited 0 with 59 warnings. A built-backend HTTP health smoke check passed
against the configured local MongoDB, and the MongoDB container was healthy afterward.
The checks ran with Node v23.3.0; dependency installation reported tooling engine warnings
and four development-tool advisories. Production-only npm audit reported zero advisories.
Native iOS/Android builds and the device demo remain unverified by this work.
