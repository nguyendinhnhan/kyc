# Retry and recovery guide

Use for network retries, upload recovery, or reconciliation. Decide whether repeating the operation is safe before deciding which failures are transient.

## Policy
- Reads may be retried when transient. Writes require server-enforced idempotency or another proven repeat-safe contract. Timeouts and connection failures do not prove the server did nothing.
- Do not automatically retry login, invalid credentials, validation/authorization failures, business conflicts, cancelled work, or TLS certificate failures. Token refresh is a separate bounded session policy; prevent concurrent refresh loops.
- Select retryable network failures and server responses for the actual operation. Respect `Retry-After` for throttling/service responses within the total deadline; otherwise defer or surface recovery instead of retrying sooner.
- Define max attempts including the first attempt, per-attempt timeout, total deadline, and cancellation. Retry at one layer to avoid multiplying attempts across wrappers/interceptors.
- Use capped exponential backoff with jitter and an injectable clock/random source. Make units and attempt indexing explicit; do not confuse language XOR with exponentiation.
- Keep an idempotency key stable across attempts/restarts for the same logical write. Before issuing a new submission after uncertain completion, reconcile server state.
- Ensure image request bodies can be replayed safely; persist protected upload metadata needed for resume. Clean up only when completion or abandonment is established.
- Log operation type, safe error code and attempt count; omit payloads, tokens, image paths containing identity details, and signed URLs.

## Verification
Use fake time to test eventual success, exhausted attempts/deadline, cancellation during delay/request, no retry of permanent errors, bounded `Retry-After`, and stable write identity. Use real backend tests for deduplication and timeout-after-commit recovery. Offline UI must preserve the draft and offer a safe next action.
