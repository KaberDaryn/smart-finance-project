# Smart Finance

Smart Finance is a team diploma project for personal finance planning and expense analysis in KZT. The application combines a Python API, relational storage, a hand-written web frontend, and a Flutter Android app that opens the same frontend inside the app.

## Application

Users can create an account, record dated income and expenses, search their history, delete records, and view their balance. CSV import checks the complete input before saving records and recognises repeated imports of the same data, and CSV export downloads the recorded history. Each account has separate transactions, monthly budgets, and savings goals.

The browser client in `web/` is a hand-written dashboard with no build step: sign-in and registration, Overview, Transactions, Insights, and Planning pages, receipt scanning, CSV import and export, light and dark themes, and SVG charts.

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

The local application runs with Python 3.11 or newer. START_LOCAL.cmd starts the server, and START_DEMO.cmd adds a fictional demonstration account. Docker Compose runs the same application with PostgreSQL. The Android app requires the local server and shows the same frontend without opening Chrome.

## Receipt scanning

Sign in and choose **Scan receipt** on the Overview or Transactions page. Accept the external-service notice, choose a JPEG/PNG/WebP photo, review the recognized fields, choose a category, and press **Save transaction**. Categories come only from the current user's saved merchant choices. Manual entry works without a recognition key.

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

The frontend lives in `web/`: `index.html`, `styles.css`, `app.js`, and `favicon.png`. These are plain hand-written files with no build step and no framework. The browser server and Android app both load these same files; there is no separate Flutter web frontend.

To run the Android app, start the backend in one terminal and then run:

```sh
cd mobile
flutter pub get
flutter run -d emulator-5554
```

The emulator URL defaults to `http://10.0.2.2:8000`. Set `WEB_APP_URL` with `--dart-define` to use another server. Flutter 3.44.2 is the version used by this project.

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
