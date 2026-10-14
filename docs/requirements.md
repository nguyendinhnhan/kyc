# Assignment requirements and acceptance criteria

Source: `Senior_Fullstack_Assignment.pdf`, pages 1–2. This is a working interpretation; the PDF remains the assignment source. The checks below are proposed evidence, not completed results.

| ID | Assignment requirement | Acceptance evidence |
|---|---|---|
| R1 | Flutter on iOS and Android; real backend, any stack | Documented local setup; app calls actual backend; build/run evidence states platforms verified |
| R2 | Login, session handling, logout | Login success/failure, expired session, logout and account switching tested; credentials and tokens absent from logs |
| R3 | Collect and validate identity information | Client feedback and server validation agree; required fields and boundaries documented |
| R4 | Camera capture of an accepted ID type | Camera permission denial, cancellation, retake, and valid document capture demonstrated |
| R5 | Face/selfie capture | Permission, cancellation, retake, and successful capture demonstrated |
| R6 | Review, edit, upload, submit | Edits survive navigation; missing/invalid uploads cannot submit; duplicate submission and lost responses handled |
| R7 | Status, rejection, resubmission | Server-authoritative status; rejection shown with useful feedback; permitted edits and resubmission tested |
| R8 | Resume interrupted onboarding | Draft and progress recover after process restart; interrupted upload/submit reconciles without duplicates |
| R9 | Sensitive data handling | Token storage, draft/image protection, ownership isolation, redacted errors/logs, retention and cleanup verified |
| R10 | Network and lifecycle resilience | Offline, timeout, backgrounding, restart, and cancellation scenarios preserve recoverable state |
| R11 | Tested where it matters | Business/state rules, API authorization, submission deduplication, and critical UI/flow evidence |
| R12 | Delivery | Git history; README with run steps, architecture, security, trade-offs, future work; backend source/run instructions; full-flow recording using synthetic documents |
| B1 | Optional AI workflow bonus | Repeatable workflow artifacts plus honest examples of AI help, validation, corrections, and developer ownership |

## Decisions and assumptions to record before affected implementation

User-selected conventions: one repository for Flutter and Node.js, with TDD for behavior changes, and MongoDB for persistence; see `docs/adr/0001-repository-and-tdd.md` and `docs/adr/0002-mongodb-database.md`. These are project decisions, not additional PDF requirements.

Choose and justify the Node.js framework, state management, and authentication. Define identity fields and supported document types, image limits, status machine, rejection reasons, draft authority and conflict handling, retention/cleanup, and local development setup.

A real verification vendor, OCR, biometric matching, registration, email verification, production hosting, chunked uploads, telemetry providers, and CI deployment are not explicitly required. Add only if justified within scope. If using simulated verification decisions, run them in the real backend, document the mechanism, and do not claim real identity verification. The app must still call a real API and persist real workflow state.

Track implementation and evidence by ID in task notes or PRs. Mark missing evidence explicitly; do not mark a requirement complete because code was generated.
