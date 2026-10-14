# Behavior-focused testing guide

Use to verify a feature's acceptance criteria and failure behavior. Inspect the actual testing framework and conventions first.

## TDD loop
- Before adding behavior, choose the smallest observable outcome and write a test at the level that can prove it: unit, widget, or API integration.
- Run the test and inspect the failure. A syntax error, unavailable database, or bad fixture is not evidence of missing product behavior; fix the harness first.
- Implement only enough production behavior to pass. Run relevant existing tests, then refactor without changing behavior and rerun them.
- For a bug, add a test that reproduces it before fixing it. Do not weaken assertions or alter expectations merely to make implementation pass.
- Record the red and green commands/results concisely. If the test unexpectedly passes, check whether the behavior already exists or the test is ineffective; do not fabricate a failing run.
- Documentation, formatting, and initial tooling setup do not need artificial failing tests. Device-only camera, backup, and lifecycle behavior still needs explicit platform verification; test-first unit coverage is insufficient.
- If the environment prevents execution, report TDD as unverified and the blocker explicitly; generated tests are not proof that a red/green cycle occurred.

## Test selection
- Derive scenarios from requirements and contracts, not only from the code being tested. Name the observable behavior and assert meaningful outcomes.
- Unit-test validators, state transitions, retry classification/deadlines, error mapping, and cleanup decisions. Include boundary and failure cases relevant to the feature.
- Fake external boundaries, time and randomness for deterministic unit tests. Do not mock away the invariant under test or write assertions that merely repeat implementation.
- Use integration tests with the real API/database for ownership, transactions, constraints, idempotency and concurrency. Test doubles cannot prove these properties.
- Use widget tests for validation, loading/error/recovery states, edits and duplicate-action prevention. Use device/emulator flow checks for camera permissions, process restart, protected storage and backend connectivity.
- Prioritize cross-user denial, lost submission response, duplicate requests, rejected/resubmitted state, interrupted upload, and logout/account-switch isolation. Use synthetic identity fixtures.
- Coverage is diagnostic, not proof of correctness. Do not impose arbitrary conflicting percentages or claim every security property is established by 100% line coverage.

## Reporting
Run tests and report exact commands/results. Distinguish passed, failed and unrun checks; include environment limitations. Report coverage only if actually measured. Add regression tests for material bugs rather than tests of document wording or implementation structure.
