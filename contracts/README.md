# Contracts

This directory contains API contracts and specifications for the KYC project.

## Structure

```
contracts/
├── api/                    # API contracts
│   ├── README.md          # API documentation
│   └── auth/              # Authentication endpoints
│       ├── register.md    # POST /auth/register
│       ├── login.md       # POST /auth/login
│       ├── refresh.md     # POST /auth/refresh
│       └── logout.md      # POST /auth/logout (TODO)
└── models/                # Data models (TODO)
```

## Purpose

### API Contracts
- Define request/response structures
- Serve as documentation
- Provide mock data for testing
- Enable parallel frontend/backend development

## Usage

### For Developers
1. Read contract before implementing endpoint
2. Use examples for testing
3. Ensure responses match contract structure

### For Frontend
1. Use contracts to build API client
2. Use examples as mock data
3. Implement error handling for documented errors

## Maintenance

- Update contracts when API changes
- Keep examples realistic
- Document all error scenarios
- Version contracts when breaking changes occur
