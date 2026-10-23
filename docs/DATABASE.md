# Storage and migration

PostgreSQL and SQLite use the same logical tables: users, sessions, transactions, budgets, goals, imports, and merchant_categories. Amounts are stored as integer minor units; 150001 represents 1500.01 KZT. Each private record is associated with a user ID. Sessions store only a hash of the bearer token and an expiry timestamp.

Schema setup adds the user_id column to a legacy transaction table without assigning old records to an arbitrary account. Legacy records with no owner are not returned by the authenticated API. Existing SQLite data stays in its original file.

The idempotent receipt migration `backend/migrations/001_merchant_categories.sql` runs during the existing schema setup after a server restart. It creates category memory keyed by `(user_id, merchant_key)`, with a foreign key to `users`. Expense creation and merchant-category updates share one transaction. Receipt images are never stored. See [receipt storage details](RECEIPTS.md).

## Legacy SQLite to PostgreSQL

This importer is for the old, unowned transaction dataset. First create the destination account in the PostgreSQL-backed application, then install the backend requirements locally and set these environment values in PowerShell:

```powershell
python -m pip install -r requirements.txt
$env:SQLITE_PATH = 'C:\path\to\old\finance.db'
$env:DATABASE_URL = 'postgresql://smart_finance:local-dev-only@127.0.0.1:5432/smart_finance'
$env:OWNER_USERNAME = 'your_username'
python -m backend.migrate_sqlite_to_postgres
```

The source is opened read-only. Owned records are excluded. The target assigns new IDs while retaining amounts, categories, descriptions, and timestamps. A snapshot fingerprint prevents the exact same import from running twice. Keep a backup of the source until its counts and totals have been checked.

The local volume and database files are not part of the release archive. The application is configured for a local academic demonstration, not a publicly hosted financial service.
