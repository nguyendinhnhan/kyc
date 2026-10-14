# Architecture decision guide

Use for consequential choices such as backend/storage, state management, auth, protected draft persistence, idempotency, or verification simulation. Routine edits do not require an ADR.

Inspect existing decisions and assignment constraints. Compare realistic alternatives against this project's delivery, privacy, resilience and testability needs. Examples are not accepted decisions, and no reviewers or approvals should be invented.

Store records at `docs/adr/NNNN-short-title.md` when a decision is needed:

```markdown
# NNNN: Decision title
Status: Proposed | Accepted | Superseded by NNNN
Date: actual decision date

## Context
Requirement IDs, constraints and relevant assumptions.

## Decision
Concrete choice and scope. State who actually made it if relevant.

## Alternatives
Plausible options and project-specific trade-offs.

## Consequences
Benefits, costs, risks, and limitations.

## Verification and follow-up
How the implementation will demonstrate the decision's properties;
what remains unverified or deferred.
```

Mark a decision Accepted only when actually selected within the authorized task; do not imply human approval occurred. Link superseding records rather than rewriting history to conceal a change. Avoid unsupported ecosystem rankings, fabricated team experience, or fixed dependency versions copied from examples.
