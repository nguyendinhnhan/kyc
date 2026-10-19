# 0008: Interview-readiness corrections

Status: Accepted
Date: 2026-10-18

## Context
A follow-up review after submission found build/tooling failures, stateless refresh/logout,
a recursive mobile refresh lock, cached identity state surviving logout, unconditional
submission transitions, and uploads trusting unvalidated content. This record supersedes
implementation claims in ADR-0004/0006/0007 where they conflict with current code.

## Decision
Keep the submitted main branch intact and make corrections on `fix/interview-readiness`.
Keep the feature-oriented Flutter structure and existing backend routes/models; introduce
only used session, workflow, and image-storage services. Configure independent build/test
commands; migrate ESLint to its flat configuration without weakening existing warning rules.

Persist server sessions containing only refresh-token digests, expiry and owner. JWTs bind
to a session. Refresh uses an atomic digest compare-and-swap; logout deletes that session,
revoking access and refresh tokens. Independent logins have independent sessions. Session
TTL cleanup is supplementary: authentication checks expiry even before the TTL monitor runs.

Use one shared Future for mobile refresh, with one protected-request replay and no auth
endpoint retry. Feature providers depend on account identity and discard late responses
after disposal. Secure storage retains a pending submission key across uncertain responses.
Server keys are owner-scoped and return current status on replay, rather than resetting it.
Corrections retain rejected status until explicit resubmission. Admin decisions atomically
require a pending status. See the updated contracts for exact HTTP behavior.

Decode JPEG/PNG inputs with Sharp, limit compressed bytes and decoded pixels, strip metadata,
and store random private files under UPLOAD_DIR. Confirm metadata replacement before old-file
cleanup. Keep an uncertain new file for reconciliation rather than risk deleting a committed
upload. Do not claim an orphan sweeper, S3 adapter, or production field encryption exists.

Run integration tests only on constructed local test databases and temporary directories,
with synthetic valid image fixtures. The health test exercises the delivered app factory.

## Consequences and limits
Previous JWTs require re-login. A lost refresh response can require re-login because the
old token is already consumed; no unsafe automatic refresh retry is added. Replayed
submission responses show current status, including a later review decision.

The standalone local database does not provide multi-document transactional isolation
between an edit racing with submission. Pre-handler edit guards and atomic submission/admin
status writes address ordinary flows and tested races, but do not claim a fully immutable
submission snapshot. Production snapshots/transactions, encryption/key management,
retention/orphan cleanup, and platform capture/process-death evidence remain follow-up work.
