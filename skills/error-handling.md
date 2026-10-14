# Error handling guide

Use when adding API, platform, business, or UI failure behavior. Reuse a small existing error model instead of creating a universal hierarchy.

## Contract and mapping
- Define stable machine codes, appropriate HTTP statuses, safe public messages, optional field errors, and a request/correlation ID. Never return stack traces, SQL errors, sensitive values or signed URLs.
- Map transport/platform errors once at the appropriate boundary. Distinguish validation, session expiry, ownership denial, invalid workflow transition, transient outage, and uncertain write completion.
- Show inline validation where useful, preserve user input on recoverable failure, and offer only actions safe for that operation. An uncertain submission should reconcile status before allowing another write.
- Do not claim a lockout duration or retry time unless provided by the server policy. Camera/storage permission errors need an actionable recovery path; cancellation need not be shown as failure.
- Keep unexpected failures observable through sanitized diagnostics. Allowlist log fields such as operation, safe error code and correlation ID; raw exception objects/HTTP bodies may contain secrets. Redact before any remote telemetry; do not add a telemetry vendor merely because a template names one.
- Catch errors at meaningful boundaries without hiding failures as success or empty data. Avoid duplicate logs and retry loops across layers.

## Verification
Test backend-to-client mappings, preserved draft state, safe user actions, unknown errors, and absence of sensitive fixture values from emitted logs/responses. Confirm ownership errors do not disclose another user's data.
