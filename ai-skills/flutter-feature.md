# Flutter feature guide

Use for one coherent Flutter outcome. Read shared rules and existing feature patterns first. State management and architecture examples are not predetermined choices.

## Implementation
- Identify requirement IDs, screen/state transitions, API contracts, and failure behavior. Use the existing state library; document its selection if starting from scratch.
- Separate UI from persistence/network and business rules with only the layers the feature needs. Do not require a use case, DTO, equality package, or widget split solely for a template or line-count rule.
- Model loading, editable draft, validation, recoverable failure, and completion states. Preserve edits across navigation and process restart using the chosen protected draft mechanism.
- Handle camera permission denial, cancellation, retake, temporary-file lifecycle, and background/foreground changes for capture features.
- Prevent duplicate actions and stale async responses from overwriting newer state. Cancel or safely ignore work when a screen/session is disposed or changes.
- Keep server status authoritative. Explain rejection and allowed resubmission actions. Show useful recovery actions and accessible labels without exposing technical internals.

## Verification
Test validation/state transitions and key UI interactions. Verify resume, capture, and lifecycle behavior on a device/emulator as applicable; report unavailable platforms explicitly. Connect to the real backend for flow evidence.

## Example task
Implement editable personal details for R3/R8. Define validated fields and protected persistence; verify edits survive navigation and process restart, and do not leak between accounts.
