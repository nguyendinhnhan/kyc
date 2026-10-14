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
