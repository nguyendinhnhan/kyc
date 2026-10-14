# AI-assisted KYC development workflow

This is the planned workflow. Record actual usage and verification separately; this document does not claim completed implementation, reviews, security certification, or measured speed improvements.

## Instruction structure

`AGENTS.md` holds shared project rules; `.cursorrules` points Cursor to them. `docs/requirements.md` maps the PDF to acceptance criteria. `skills/` contains optional task-specific prompt guides. Read only what the current task needs.

## Repeatable development loop

1. **Analyze:** identify the requirement IDs and observable outcome. Inspect existing code and record material ambiguities as assumptions. Ask only when missing information blocks a meaningful choice; the assignment allows documented assumptions.
2. **Plan:** define the smallest end-to-end slice, API/state contract, affected files, failure cases, and verification. Use an ADR for consequential choices, distinguishing proposals from accepted decisions.
3. **Implement with TDD:** write one test of the next required behavior and run it. Confirm it fails because the behavior is absent, rather than because of a broken test setup. Implement the minimum to pass; refactor while keeping relevant tests green. Repeat for the slice. Keep Flutter and Node.js contracts aligned, with test doubles limited to tests.
4. **Validate:** run formatting, static analysis, targeted tests, and integration/device checks appropriate to the slice. Capture commands/results and unverified environments. Exercise ownership, retry, process restart, and sensitive-data behavior where relevant.
5. **Review:** inspect the diff against acceptance criteria. Check lost responses, duplicate writes, cross-user access, sensitive logging/storage, cleanup, and unintended scope. Fix material findings and rerun affected checks. Human review focuses on understanding and defending decisions; it is not a mandatory approval pause for every edit.
6. **Document:** update actual setup, API behavior, trade-offs and ADRs. Record where AI helped, what was corrected, and the evidence used. Do not invent retrospective successes.
7. **Deliver:** verify setup from a clean environment when available, check deliverables R12, and record the synthetic-data demo. State limitations explicitly. Deployment is optional and requires authorization for external actions.

## Task prompt

```text
Implement [observable outcome] for requirement IDs [IDs].
Inspect AGENTS.md, relevant code/tests, requirements, and only applicable guides.
Record necessary assumptions and consequential decisions.
Define API/state contracts and failure behavior before changing both sides.
Use red → green → refactor for each behavior; record actual red/green results.
Implement the smallest complete slice, run appropriate checks, review the diff,
and report changed files, actual results, and remaining limitations.
```

## Suggested slice order

Runnable app/backend skeleton → authentication/session isolation → personal-details draft and resume → document/selfie capture and protected upload → review and idempotent submission → status/rejection/resubmission → lifecycle/network verification and delivery evidence.

Adjust order to dependencies. Avoid generating the entire application from a single template.

## Verification commands

Once Flutter exists, use its configured formatter, `flutter analyze`, and relevant `flutter test` suites. Select backend commands from its manifest and document them in the application README. Add platform/device and real-backend checks for capture and full-flow behavior; unit tests alone cannot establish them. Do not invent runnable commands before the backend framework and test tooling are selected.

## Evidence record

Use `docs/ai-usage.md` for concise entries: task/requirement IDs, AI contribution, material correction, checks/results, developer decision, and remaining limits. Record metrics only when actually measured.
