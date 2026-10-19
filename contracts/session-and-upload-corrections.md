# Session and upload corrections

## Sessions
Login creates an independent server session. Access and refresh JWTs bind to that session.
Refresh atomically consumes the stored SHA-256 digest and replaces it with the next digest;
only one concurrent consumer succeeds. Raw refresh tokens are never persisted. Logout
requires matching owner/session claims and revokes the entire current session. Other
logins remain valid. Session expiry is checked on every access, with a TTL index for cleanup.
Existing JWTs without a server session require a fresh login after this update.

Flutter never refreshes login/register/logout requests. Protected requests can refresh
once, share a single in-flight refresh, and stop on another 401. Account changes invalidate
cached KYC state and stale responses. Logout waits for an outstanding refresh before
clearing tokens to prevent a late refresh restoring them.

## Image uploads
Protected document/selfie endpoints accept JPEG or PNG image content, including multipart
clients using application/octet-stream. The server decodes content, rejects unsupported,
malformed or oversized images, strips metadata by re-encoding, and derives its MIME type
from the decoded format. Limits: 10 MiB input and 24 million decoded pixels. Invalid images
return 400; input size overflow returns 413. Multipart text fields work before or after the
file part. Paths never appear in metadata responses. Files use random server names under
the configured private local upload directory (0700 directory, 0600 files).

Replacement commits the new metadata before deleting the old file; a failed database
write retains the old file. An uncertain database write may leave an orphan, which must
be reconciled before cleanup. Local storage is for the laptop demo; S3 and production
storage encryption/key management are not implemented by these corrections.
