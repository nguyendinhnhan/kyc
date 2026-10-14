# Backend endpoint guide

Use when changing the real API or persistence. Inspect the chosen stack, API contract, schema, and existing conventions.

## Contract and implementation
- Define method/path, authentication, resource ownership, input/output schema, error codes, state preconditions, and retry/idempotency behavior.
- Validate types, lengths, enums, and business constraints server-side. Accept realistic identity names; do not invent ASCII-only name rules or authentication policies from examples.
- Authorize every resource and image operation by authenticated ownership. Public auth routes are explicit exceptions to authentication, not to input validation or abuse controls.
- Keep HTTP translation separate from business rules and persistence. Use database constraints/transactions to enforce invariants under concurrent requests; a pre-check alone does not prevent duplicates.
- For submission, atomically bind an idempotency key to owner, operation and request identity. Repeated identical requests recover the original result; incompatible reuse fails. Persist enough state to reconcile a committed write whose response was lost.
- Verify upload ownership, actual file content/type, limits, completion and linkage before submission. Private object storage or backend-mediated uploads are design options, not mandatory vendors.
- Guard verification transitions and resubmission rules on the server. Define how verification decisions are produced and distinguish simulation from real verification.
- Return stable, documented error responses. Keep internal failures and sensitive values out of responses/logs. Configure appropriate protection for sensitive auth/write routes.

## Verification
Test the real endpoint and persistence for invalid input, unauthenticated requests, cross-user access, invalid transitions, concurrent/duplicate submission, and lost-response recovery where relevant. Document contract changes and actual run commands.
