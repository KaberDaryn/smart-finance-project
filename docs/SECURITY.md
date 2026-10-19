# Account and data handling

Passwords are hashed using PBKDF2-HMAC-SHA256 with a random 16-byte salt and 310000 iterations. Password hashes and salts remain in the database and are never returned by the API. Password comparison uses a constant-time comparison. Session tokens use cryptographic randomness; the database stores their SHA-256 hashes and an eight-hour expiry, and logout removes the current session.

The Flutter client keeps the bearer token in memory. It is not placed in a URL or committed file. Restarting the browser application requires another login. Authenticated routes scope queries by the current user's ID; a client cannot select another owner. CSV validation completes before insertion and the batch is transactional.

The local server binds to localhost by default. Docker publishes the app and database on 127.0.0.1. This is a local demonstration configuration: it does not include HTTPS termination, password recovery, encrypted backups, security monitoring, a hardened internet gateway, or a security certification. Native Android source allows cleartext only for local emulator addresses. No claim of production readiness is made.

Legacy rows with no owner are not exposed to a newly registered account. Local database files, environment values, credentials, and private financial records are excluded from the archive and Git.
