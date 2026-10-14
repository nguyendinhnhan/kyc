# Task-specific AI prompt guides

These files are project references loaded on demand. They are not installed or automatically discovered Codex skills; `AGENTS.md` is the shared entry point. Each guide supports implementation, but does not authorize external actions or establish architecture choices.

| Guide | Load when |
|---|---|
| [flutter-feature.md](flutter-feature.md) | Adding or changing a Flutter flow, form, state, or capture UI |
| [backend-endpoint.md](backend-endpoint.md) | Adding or changing an API, persistence, ownership, or state transition |
| [retry-logic.md](retry-logic.md) | Adding retries, upload recovery, or write reconciliation |
| [secure-storage.md](secure-storage.md) | Persisting tokens, drafts, identity data, or images; changing cleanup |
| [error-handling.md](error-handling.md) | Mapping backend/network/platform failures to safe responses and UI |
| [unit-test.md](unit-test.md) | Testing business rules or failure behavior; choosing integration coverage |
| [adr.md](adr.md) | Documenting a consequential architectural decision |

Supply the outcome, relevant requirement IDs, code paths, and acceptance criteria. The agent should inspect missing context instead of filling placeholders with invented facts. If reusable installed skills are later needed, package a focused guide as `<name>/SKILL.md` with `name` and `description` frontmatter in the chosen tool's skill location. Keep shared rules in one place.
