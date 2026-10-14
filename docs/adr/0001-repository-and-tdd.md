# 0001: One repository, Node.js backend, and TDD
Status: Accepted
Date: 2026-10-14

## Context
R1/R12 require a Flutter app and real backend source/run instructions in the same repository. The user identified Node.js for the server and requested TDD. API, state and resilience changes affect both clients and server.

## Decision
Keep one Git repository, with the intended structure:

```text
app/          Flutter project, platform code and tests
backend/      Node.js server, dependencies and tests
contracts/    API specification and shared synthetic contract fixtures
docs/        Requirements, decisions and AI usage evidence
skills/      AI prompt templates and guides
```

Use `docs/` at the root alongside those directories. The application directories will be created when implementation starts; this record does not claim they exist yet.

Keep independent manifests and lockfiles for Flutter and Node.js. Use language-neutral contracts rather than trying to share Dart/JavaScript business code. Coordinate API changes with both implementations in the same change. Backend framework, language variant and test runner remain open; MongoDB is the selected database (see ADR-0002).

Use red → green → refactor for behavior changes and regression fixes, with actual test execution and meaningful failures. Documentation and tooling setup do not require artificial failing tests. Platform-dependent properties also require device checks.

## Alternatives
Separate repositories allow independent access and release ownership but add coordination and submission overhead for this assignment. A single shared build tool is unnecessary for two independent language ecosystems. Tests written only after implementation provide less evidence that tests detect missing behavior.

## Consequences
One checkout, coordinated changes and shared delivery evidence simplify review. CI can later run app and backend checks independently while both run for shared contract changes. TDD requires a working harness and adds upfront test work; it does not replace integration, device or security review.

## Verification and follow-up
During implementation, verify separate install/run/test instructions and a real app-to-backend flow. Record red/green evidence for behavior slices. No Git repository, app, server, or CI has been initialized by this decision record.
