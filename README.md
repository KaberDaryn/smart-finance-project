# Smart Finance

Smart Finance is a team diploma project for personal finance planning and expense analysis in KZT. The application combines a Flutter client, a Python API, and relational storage. The team implementation covers transaction recording, spending analysis, and financial planning.

## Application

Users can create an account, record dated income and expenses, search their history, and view their balance. CSV import checks the complete input before saving records and recognises repeated imports of the same data. Each account has separate transactions, monthly budgets, and savings goals.

The Insights screen displays expense categories and monthly totals. Planning shows budget usage, overspending alerts, and savings progress. The analytics package provides expense category suggestions and a forecast based on three complete months. Suggestions can be edited before saving. The demonstration model uses synthetic English descriptions; its scores are not evidence of real-world accuracy.

## Team

- Daryn Kaber: Flutter client, backend API, database, integration, and deployment.
- Dauren Akhmetov: analytics, expense categorisation, and forecasting.
- Aisultan Nuriman: UX/UI, user research, and quality assurance.
- Supervisor: Bakyt Bakayeva.

## Project materials

- [Running the application](docs/RUNNING.md)
- [API reference](docs/API.md)
- [Storage and migration](docs/DATABASE.md)
- [Account and data handling](docs/SECURITY.md)
- [Analytics integration](docs/INTEGRATION.md)
- [Analytics implementation](analytics/README.md)
- [Interface design](docs/DESIGN.md)
- [User guide](docs/USER_GUIDE.md)
- [Verification](docs/TESTING.md)

The local browser application runs with Python 3.11 or newer. START_LOCAL.cmd starts the server, and START_DEMO.cmd adds a fictional demonstration account. Docker Compose runs the same application with PostgreSQL. The current release is for local demonstration; production hosting and native Android testing remain outside the verified scope.

## Receipt scanning

Sign in and open **Add transaction → Scan receipt**. Accept the external-service notice, take a photo or choose one from the gallery, review the recognized fields, choose a category, and press **Save transaction**. Categories come only from the current user's saved merchant choices. Manual entry works without a recognition key.

Create a free Gemini API key in the [Google key console](https://aistudio.google.com/apikey). Check the [current pricing and quotas](https://ai.google.dev/gemini-api/docs/pricing) and keep the project on the free tier if you do not want paid usage. The default `gemini-3.8-flash` supports image input and free-tier input/output, checked on 2026-10-23. Limits and availability can change.

Copy `.env.example` to `.env` and set `GEMINI_API_KEY`. Docker Compose passes it only to the server. `RECEIPT_PROVIDER=gemini` chooses the provider, and `RECEIPT_MODEL=gemini-3.8-flash` chooses the model. Apply changes with `docker compose up -d --build api`.

For a local Python run, export the variables before starting the server; Python does **not** automatically load `.env`:

```sh
export GEMINI_API_KEY='your-local-key'
export RECEIPT_PROVIDER=gemini
export RECEIPT_MODEL=gemini-3.8-flash
python -m backend.server
```

In PowerShell use `$env:GEMINI_API_KEY = 'your-local-key'` instead of `export`. Never put the key in Dart defines, source, screenshots, or commits.

For client development or rebuilding the supplied browser application:

```sh
cd mobile
flutter pub get
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
cd ..
cp -R mobile/build/web/. web/
```

On Windows, use `scripts/build_web.ps1` for the build and copy step. Flutter 3.44.2 is the version used by this project.

The client corrects orientation, scales the long side to at most 1500 px, removes image metadata, and uploads JPEG at quality 82. JPEG, PNG, and WebP input is supported; export HEIC as JPEG first. The ledger stays in KZT. Foreign receipts require a manually entered KZT equivalent; the original amount and currency are retained in the description. No currency conversion service is used.

The merchant-category migration runs automatically on the first connection after a server restart. Existing transactions are preserved. Scanning does not save an expense or teach a category; confirming and saving does both through the existing transaction path.

Run backend checks with `python -m unittest discover -s tests -v`, `python -m analytics.evaluate`, and `git diff --check`. The tests mock external requests. For PostgreSQL integration, set `TEST_DATABASE_URL` to a disposable database and run `python -m unittest discover -s tests_postgres -v`.

For thesis evaluation, keep images and labels under ignored `data/receipts/`. A fictional ground-truth JSON file has this shape:

```json
[{"file": "example.jpg", "merchant": "Magnum", "date": "2026-10-20", "total": 1500.01}]
```

With the same server environment variables set, run:

```sh
python -m backend.evaluate_receipts data/receipts data/receipts/ground-truth.json --output data/receipt-evaluation.json
```

This sends those images to the recognition service and reports merchant/date/total accuracy, mean/median/p95 response time, and failures. No accuracy results are claimed without a labelled dataset and an actual run. Keep real receipts, labels, keys, and reports out of commits. See [Receipt API, validation, and evaluation details](docs/RECEIPTS.md).
