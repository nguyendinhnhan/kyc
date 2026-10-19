# KYC backend

Fastify + TypeScript + Mongoose. Run commands from `backend/`.

```bash
npm ci
# Only create .env if it does not already exist:
cp .env.example .env
# Set local MongoDB credentials and the matching MONGODB_URI with authSource=admin.
docker compose up -d mongodb
docker compose ps mongodb
npm run dev
```

Preserve an existing `.env`; never overwrite it as a routine start step. Docker binds
MongoDB to 127.0.0.1:27017 and retains data in its named volume. `docker compose stop mongodb`
stops it without deleting data. Optional Mongo Express requires the `tools` profile.

```bash
npm run build
npm start
curl http://localhost:3000/health
npm test -- --run
npm run lint
npm run format:check
```

Tests derive local credentials from `.env`, replace the database name with
`kyc_test_<worker-process-id>`, and use temporary upload directories. They refuse remote
MongoDB hosts and clean up their own database after integration tests. Your demo database
and upload directory are not used. MongoDB must be running for the integration suite.

## Implemented endpoints

- POST `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`
- GET/POST `/user/personal-details`
- GET/POST `/user/documents`; GET `/user/documents/:id/image`
- GET/POST `/user/selfie`; GET `/user/selfie/image`
- POST `/user/submit`; GET `/user/submission`
- DELETE `/user/submission`: compatibility alias for explicit resubmission
- GET `/admin/submissions`, `/admin/submissions/:id`, `/admin/stats`
- POST `/admin/submissions/:id/approve`, `/admin/submissions/:id/reject`

All `/user` routes require an active authenticated session. Admin routes also require
an admin role. See [contracts](../contracts/) for request/response details, especially
[session and upload corrections](../contracts/session-and-upload-corrections.md).

## Boundaries and limitations

Routes translate HTTP and access Mongoose models. Shared services handle sessions,
workflow edit checks/rejection updates, and private image storage; this is a small layered
backend, not a generated controller/service/repository framework. Schemas validate auth
and personal details. The TypeScript build uses Node16 module resolution with CommonJS;
UUID generation uses Node crypto rather than an ESM-only dependency.

`STORAGE_TYPE=local` and `UPLOAD_DIR` select private local storage. Other storage types
fail explicitly; S3 is planned, not implemented. Images are decoded/re-encoded as JPEG/PNG,
limited to 10 MiB input and 24 million pixels, and stored with private permissions.

Outside development/test, distinct signing secrets of at least 32 characters are required.
Use TLS at a reverse proxy outside documented laptop development. Existing stateless JWTs
from the submitted version require a fresh login. Refresh-token loss during rotation can
require re-login; invalid credentials are never retried automatically.

The demo does not establish production encryption, retention/abandonment cleanup, or
multi-document transactional isolation between an edit and simultaneous submission.
Use synthetic identity data. See [interview guide](../docs/interview-demo.md).
