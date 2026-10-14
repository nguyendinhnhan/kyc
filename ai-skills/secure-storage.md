# Sensitive storage and lifecycle guide

Use when persisting tokens, identity fields, documents, selfies, or recovery metadata.

## Design and implementation
- Identify each data item, why it is persisted, location, reader/owner, protection, backup behavior, retention trigger, and deletion path. Minimize copies and use synthetic data for development/demo.
- Store mobile tokens through maintained platform secure-storage facilities. Verify the selected package's actual platform configuration; do not assume one cipher or Android implementation applies to every version.
- Secure storage for tokens does not protect draft databases or image files. Use maintained encryption/storage mechanisms for persisted PII and images with keys protected separately, private files, and appropriate backup exclusion. Handle missing/corrupt storage without silently discarding recoverable state.
- Protect backend records and private objects with access controls and documented encryption/key management. Keep keys/secrets outside code, ciphertext, fixtures, and logs. Use established authenticated encryption if field encryption is justified; never invent crypto.
- Define behavior for logout, account switching, token expiry, successful submission, rejected submissions, abandonment, and temporary capture/upload files. Preserve protected data necessary for resume until the documented cleanup condition is met; token expiry alone need not destroy drafts.
- Decide retention explicitly as a project assumption. Do not assert seven-year retention, annual rotation, or any legal obligation without an applicable established requirement.
- Exclude PII, credentials, tokens, signed URLs and images from logs, exception serialization, crash attachments, and repository artifacts. Hashing an identifier does not automatically anonymize it.

## Verification
Test read/write/delete failures, restart recovery, ownership isolation and cleanup. Inspect real platform backup/storage configuration and backend object access; mocked storage tests alone do not prove encryption or privacy. Document what was verified and what remains a deployment assumption.
