# AI usage evidence

No application implementation or validation evidence has been recorded yet.

## Guidance review — 2026-10-14

- Task: review AI workflow, project rules and seven prompt guides against the assignment.
- AI contribution: extracted the two-page PDF; mapped requirements to acceptance evidence; revised shared guidance and task references.
- Corrections: removed missing-guide references, conflicting coverage targets, unsupported performance claims, fictional accepted ADR participants, unconditional login retries and invented retention policy. Added ownership, write deduplication/reconciliation and protected resume guidance.
- Validation: documentation links and required requirement coverage checked. No app/backend tests exist or were run; implementation behavior remains unverified.
- Developer ownership: revised guidance is available for review; no stack or production security claim is established by this edit.

## Entry template

Task and requirement IDs; AI contribution; material correction or rejected suggestion;
developer decision and rationale; exact checks/results; remaining limitations.

## Repository and TDD guidance — 2026-10-14

- Task: align project instructions with one repository, Node.js, and TDD.
- AI contribution: recorded the repository layout/decision and added red → green → refactor to shared rules, workflow and testing guide.
- Validation: inspected revised guidance; no application tests were run. Implementation and Git initialization remain pending.

## MongoDB database selection — 2026-10-14

- Task: confirm database choice for Node.js backend.
- AI contribution: created ADR-0002 documenting MongoDB selection with alternatives (PostgreSQL, SQLite, DynamoDB) and trade-offs. Updated ADR-0001, AGENTS.md, and requirements.md to close the open database decision.
- Developer decision: MongoDB selected by user. Flexible schema suits varying ID document types; document model maps naturally to KYC data; quick local setup.
- Remaining: Node.js framework, auth scheme, state management, and image storage decisions still open.

## Complete technology stack decisions — 2026-10-14

- Task: finalize all remaining technology decisions.
- AI contribution: created ADR-0003 (Fastify + TypeScript), ADR-0004 (JWT authentication), ADR-0005 (Riverpod state management), ADR-0006 (image storage strategy). Updated ADR-0002 to specify MongoDB Atlas. Updated AGENTS.md and tech-stack-summary.md with complete technology stack.
- Developer decisions:
  - Fastify for backend framework (performance + validation)
  - TypeScript for backend language (type safety)
  - JWT with refresh token rotation for authentication (mobile-friendly, secure)
  - Riverpod with code generation for Flutter state management (compile-time safety)
  - Local filesystem for dev + S3-compatible for production image storage (flexible, cost-effective)
  - MongoDB Atlas for database hosting (cloud-hosted, free tier)
- Validation: all ADRs document context, decision, alternatives, consequences, and verification steps. Technology stack is now complete and ready for implementation.
- Remaining: implementation can begin. First vertical slice: authentication flow.

## Project initialization — 2026-10-14

- Task: initialize Git repository and create project structure.
- AI contribution: initialized Git repository, created directory structure (app/, backend/, contracts/, docs/), created .gitignore files for root, app (Flutter), and backend (Node.js), created comprehensive README files for project and each directory, created backend/uploads/.gitkeep for local image storage.
- Developer decision: proceed with project initialization as planned. Later renamed mobile/ to app/ and ai-skills/ to skills/ for better organization and alphabetical ordering.
- Validation: Git repository initialized successfully, initial commit created with 28 files (1982 lines). Project structure matches ADR-0001 specification.
- Files created:
  - Root: .gitignore, README.md
  - app/: .gitignore, README.md (was mobile/)
  - backend/: .gitignore, README.md, uploads/.gitkeep
  - contracts/: README.md
  - skills/: (was ai-skills/)
- Next: set up backend scaffolding (Fastify + TypeScript + MongoDB Atlas connection) and app scaffolding (Flutter + Riverpod).

## 2026-10-18 — Post-submission interview-readiness corrections

Scope: R2/R6/R7/R9/R10/R11, tooling/run documentation for R1/R12, and B1 evidence.
User authorized fixes after review and separately approved restarting unresponsive Docker
Desktop. The submitted commit `a6c6d77` remains on main. Work is local on
`fix/interview-readiness`; no push, deployment, resubmission or fabricated commit is claimed.

AI assisted with code inspection, isolated test setup, regression tests, minimal session/
workflow/storage services, TypeScript/ESLint fixes, mobile refresh/account isolation, and
correcting inaccurate setup/security claims. Existing Flutter feature folders were retained.
Material corrections included an undeclared bcrypt dependency, ESM-only UUID imports in a
CommonJS build (replaced with Node crypto), invalid image fixtures (replaced by a synthetic
valid JPEG), and the health test constructing its own route instead of the delivered server.

Observed regression evidence (commands from their respective app/backend directories):

- `npm test -- --run tests/auth/sessionRegression.test.ts`: initially 2 failed; concurrent
  refresh returned 200/200 and a logged-out refresh still returned 200. After the session
  service correction, both passed against real local MongoDB.
- `npm test -- --run tests/user/workflowRegression.test.ts`: initially 4 failed (approved
  submission reset, changed duplicate timestamp, approved details editable, stale rejection
  metadata). The added admin-race test was run against the original admin handler and
  failed with 200/200 rather than 200/409. All six final workflow regressions passed.
- `flutter test --no-pub test/core/api_client_test.dart`: initially 3 failed (stack overflow,
  auth endpoint refresh, and unbounded retry timeout). All three passed after correction.
- `flutter test --no-pub test/core/session_state_test.dart`: first logout regression failed
  because the previous submission survived. Logout and late-response tests subsequently passed.
- `npm test -- --run tests/uploadValidation.test.ts`: initially both disguised-image tests
  returned 201 rather than 400; both passed after decoding validation was implemented.
- `npm test -- --run tests/config.test.ts`: missing production secrets initially did not
  fail startup; the corrected configuration test passed.
- Additional coverage for protected/private upload replacement, stale submission keys and
  persisted mobile keys was added during implementation; a separate red phase is not claimed
  for every additional assertion. Startup widget expectations were corrected to the current
  Login screen after reproducing its missing environment initialization failure.

Verification after corrections:

- Backend `npm run build`: passed.
- Backend `npm test -- --run`: 15 files / 62 tests passed on isolated local databases; test
  database and temporary upload cleanup is restricted to those constructed test resources.
- Backend `npm run format:check`: passed after formatting existing inconsistent files.
- Backend `npm run lint`: exit 0, with 59 style/type warnings retained under the existing
  rule policy; no lint errors. Migrated to ESLint 9 flat configuration.
- Flutter `flutter test --no-pub`: 7 tests passed. Formatting exposed two informational
  brace lints afterward; those braces were corrected and final analysis is recorded below.
- Flutter `flutter analyze --no-pub`: final result recorded below.
- Built backend started on an ephemeral loopback port; a real HTTP GET /health returned
  200 with database connected using the existing local configuration. Closed that server
  afterward. This smoke check did not modify demo identity records.
- `npm audit --omit=dev --json`: zero reported production vulnerabilities at execution;
  install output still reported four development-tool advisories. No force upgrade was run.
- `git diff --check`: passed before final documentation updates; final result recorded below.

Execution corrections: some initial commands were mistakenly invoked from the repository
root rather than the application directory and failed with missing scripts/pubspec; they
were rerun in the correct directory. Sandbox restrictions blocked SDK cache/CPU information,
package registry and local Docker/database access; authorized escalated reruns were used.
Docker later stopped responding; graceful restart failed, and the user-approved restart
required stopping its stuck backend before relaunching. MongoDB recovered with its named
volume preserved. The database port now binds only to laptop loopback.

Remaining evidence gaps: no iOS/Android build/device-camera recording, full offline/process-
death draft recovery, production encrypted storage/key management, S3 adapter, orphan/
abandonment cleanup, or cross-document transactional edit/submit isolation was established.
No full acceptance-criterion completion or production readiness is claimed. See ADR-0008
and the interview demo guide for behavior, trade-offs, and startup commands.

Final check completion: `flutter analyze --no-pub` reported no issues. The affected
`flutter test --no-pub test/core/api_client_test.dart test/core/submission_repository_test.dart`
rerun passed all 4 tests after brace-only edits (the full 7-test run had already passed).
`git diff --check` passed. `docker compose -f backend/docker-compose.yml ps mongodb`
reported healthy, bound to 127.0.0.1:27017. The built-backend HTTP smoke check exited 0.

## 2026-10-19 — Local commit organization

AI helped group the existing corrections into backend/contracts, Flutter, and shared
documentation commits at the user's request. Staged diffs passed `git diff --cached
--check`; no application behavior was changed or test suite rerun for this task.
Earlier verification above remains historical evidence. No push or deployment was requested.

## 2026-10-19 — System architecture documentation

AI inspected Flutter routing/state/storage and backend handlers, services, models, and
local deployment configuration to document the implemented system for R12. Added
component, session-sequence, and submission-state Mermaid diagrams plus persistence,
ownership, retry, and deployment boundaries. Explicitly distinguished supported
`under_review` from an implemented transition and recorded production/resume gaps.
Documentation-only change; no application tests were rerun. Local link validation and
`git diff --check` results are reported with delivery; diagram rendering is unverified.
