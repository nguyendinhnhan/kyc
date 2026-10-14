# 0002: MongoDB for backend persistence
Status: Accepted
Date: 2026-10-14

## Context
R1/R12 require a real backend. ADR-0001 established Node.js as the runtime and left the database open. The KYC flow stores user accounts, identity drafts, captured images, verification status, and submission state. The data model includes nested documents (identity fields, verification history), variable document types (passport/national ID/driver's licence), and image metadata.

## Decision
Use **MongoDB** as the primary database for the Node.js backend, with support for both:
- **Local MongoDB** (via Docker) for development and testing (default)
- **MongoDB Atlas** (cloud-hosted) for production or preference

Key implications:
- Default to local MongoDB via Docker Compose for easy interviewer testing
- Support MongoDB Atlas via environment variable configuration
- Use Mongoose (or similar ODM) for schema validation and middleware
- Store identity drafts as documents with flexible field sets per document type
- Store image metadata in MongoDB; image files in filesystem or object storage with references
- Use MongoDB transactions for atomic operations where consistency matters (e.g., submission with idempotency key binding)
- Use unique indexes for email uniqueness and idempotency keys

## Alternatives
1. **PostgreSQL** — Strong relational model, ACID transactions by default, JSON support. More rigid schema fits structured KYC data well. Requires schema migrations. Slightly heavier setup for a solo project.
2. **SQLite** — Simple, embedded, zero-config. Limited concurrency, no built-in replication. Suitable for local development but not production-grade for this use case.
3. **DynamoDB** — Managed NoSQL, good scaling. Vendor lock-in, different query patterns, more complex local development setup.

## Rationale
- **Flexible deployment**: Local MongoDB (Docker) for easy testing, Atlas for production
- **Interviewer-friendly**: No account creation needed; just run `docker-compose up`
- **No internet required**: Local MongoDB works offline
- **Faster development**: No network latency with local database
- Flexible schema accommodates different ID document types and evolving identity fields without migrations
- Document model maps naturally to KYC data (user → drafts → captures → verification)
- Familiar to Node.js ecosystem
- Change streams and aggregation pipeline useful for status tracking

## Consequences
### Benefits
- Schema flexibility for varying document types and identity fields
- Natural document model for nested KYC data
- Quick local development setup
- Good Node.js ecosystem support

### Costs and risks
- No relational constraints by default — must enforce data integrity through schema validation and application logic
- Transactions require replica set (even local) — configure correctly
- Less mature migration tooling compared to SQL — plan schema evolution carefully
- Image storage still needs separate solution (filesystem or object store)

## Verification and follow-up
- Configure MongoDB connection with authentication
- Define Mongoose schemas with validation for all models
- Use transactions for submission and idempotency operations
- Test concurrent access and duplicate prevention
- Document backup and retention approach
- Record image storage decision separately if needed
