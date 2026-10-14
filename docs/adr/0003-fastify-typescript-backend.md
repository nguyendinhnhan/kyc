# 0003: Fastify with TypeScript for backend
Status: Accepted
Date: 2026-10-14

## Context
ADR-0001 established Node.js as the backend runtime and ADR-0002 selected MongoDB for persistence. The backend framework and language variant remained open. The KYC backend needs:
- High performance for image uploads and verification workflows
- Schema-based validation for identity data and API contracts
- Strong typing for complex business logic (state machines, ownership checks)
- Good TypeScript support for type safety
- Fast local development setup

## Decision
Use **Fastify** as the Node.js framework with **TypeScript** as the language.

Key implications:
- Use Fastify's schema-based validation (Ajv) for request/response validation
- Leverage TypeScript for type safety across business logic and API contracts
- Use Fastify plugins for modular architecture (auth, database, storage)
- Configure TypeScript with strict mode for maximum safety
- Use ts-node or tsx for development, compile to JavaScript for production
- Use Fastify's built-in logging with sanitization for sensitive data

## Alternatives

### Backend Framework
1. **Express** — Most popular, flexible, huge ecosystem
   - Pros: Maximum flexibility, tons of middleware, well-documented
   - Cons: No built-in validation, more manual setup, slower than Fastify
   
2. **NestJS** — Angular-like architecture, built-in TypeScript
   - Pros: Strong structure, dependency injection, good for large teams
   - Cons: More boilerplate, heavier, overkill for solo project
   
3. **Koa** — Minimal, modern, from Express team
   - Pros: Clean API, middleware-based
   - Cons: Smaller ecosystem, less community support

### Language
1. **JavaScript** — Simpler setup, no compilation
   - Pros: Faster initial setup, no build step
   - Cons: No type safety, runtime errors, worse IDE support

## Rationale

### Why Fastify?
- **Performance**: 2-3x faster than Express for JSON payloads (critical for image uploads)
- **Schema validation**: Built-in Ajv validation reduces boilerplate and errors
- **TypeScript-first**: Excellent TypeScript support with type inference
- **Plugin architecture**: Clean separation of concerns (auth, DB, storage)
- **Logging**: Built-in structured logging with customization
- **Modern**: Async/await native, modern JavaScript features

### Why TypeScript?
- **Type safety**: Catches errors at compile time (critical for state machines, ownership)
- **Better IDE**: Autocomplete, refactoring, navigation
- **Documentation**: Types serve as inline documentation
- **Maintainability**: Easier to refactor with confidence
- **Industry standard**: Expected for new Node.js projects

## Consequences

### Benefits
- High performance for image uploads and API calls
- Compile-time type safety reduces runtime errors
- Built-in validation reduces boilerplate
- Better developer experience with IDE support
- Cleaner code with TypeScript interfaces
- Fast local development with hot reload

### Costs and Risks
- TypeScript requires compilation step (adds build complexity)
- Fastify has smaller ecosystem than Express (fewer middleware options)
- TypeScript learning curve if team is unfamiliar
- Type definitions for some packages may be incomplete
- Build step adds time to CI/CD

### Mitigations
- Use tsx or ts-node-dev for fast development with hot reload
- Fastify plugin ecosystem is sufficient for our needs
- TypeScript strict mode catches most issues
- Use DefinitelyTyped for type definitions
- Incremental compilation speeds up builds

## Implementation

### Backend Structure
```
backend/
├── src/
│   ├── controllers/      # Request handlers
│   ├── services/         # Business logic
│   ├── repositories/     # Database access
│   ├── models/           # TypeScript interfaces/types
│   ├── plugins/          # Fastify plugins (auth, db, storage)
│   ├── schemas/          # JSON schemas for validation
│   ├── middleware/       # Fastify hooks and middleware
│   └── utils/            # Shared utilities
├── tests/                # Test files
├── package.json
├── tsconfig.json
└── fastify.config.ts
```

### Key Dependencies
- `fastify` — Web framework
- `@fastify/cors` — CORS support
- `@fastify/jwt` — JWT authentication
- `@fastify/multipart` — File uploads
- `mongoose` — MongoDB ODM
- `zod` or `ajv` — Schema validation (Fastify uses Ajv by default)
- `typescript` — Type safety
- `tsx` or `ts-node-dev` — Development with hot reload
- `vitest` or `jest` — Testing framework

### TypeScript Configuration
- Strict mode enabled
- ES2022+ target
- Path aliases for clean imports
- Source maps for debugging
- Declaration files for library builds

## Verification and Follow-up
- Verify Fastify performance with image upload benchmarks
- Test TypeScript compilation and type safety
- Validate schema-based validation for all endpoints
- Ensure hot reload works in development
- Document Fastify plugin patterns
- Record any middleware gaps and solutions

## References
- Fastify documentation: https://www.fastify.io/docs/latest/
- TypeScript Node.js starter: https://www.typescriptlang.org/docs/handbook/nodejs.html
