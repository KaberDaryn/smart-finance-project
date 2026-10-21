# Verification of the integrated team version

## Automated checks on 20 October 2026

Thirty Python tests passed against temporary SQLite databases and local HTTP servers. They cover account access, session revocation, account data isolation, exact amounts, date validation, transaction storage, budgets, goals, atomic CSV import, duplicate import detection, category suggestions, forecast history, CORS, and static-path traversal.

The integration checks confirm that the published backend delegates to the team's classifier and insights modules. A dated six-month transaction history was saved through the authenticated HTTP API, and GET /analytics returned a populated forecast, category totals, monthly totals, and recommendations. A separate check verifies graceful behaviour when analytics is absent.

Flutter analysis found no issues, and all thirteen unit/widget tests passed. These checks cover amount/currency formatting, account flow, planning, CSV feedback, empty/error states, uncertain saves, editable category suggestions, search, and a narrow layout. The client also passed a release web build. Browser review found two malformed chart separators. The UX contribution replaces them with ASCII separators in mobile/lib/main.dart and includes the corresponding rebuilt web assets. The existing published repository is unchanged until the team merges that contribution.

python -m analytics.evaluate reproduced the synthetic-data classification and forecast metrics in docs/analytics-results.json. The evaluation is a software demonstration, not evidence of real-user predictive accuracy.

Docker Compose built and started the integrated application with PostgreSQL 17 on isolated local ports. The PostgreSQL integration test passed against the container database. Browser review confirmed demo login, loaded account totals, an expense saved as exactly 150001 minor units, automatic Groceries classification, populated category and monthly charts, a forecast, a budget-exceeded message, and creation of a savings goal. After removing and recreating both test containers without deleting the named volume, all 38 transactions, both goals, budgets, account login, and forecast matched the pre-restart snapshot. These are local checks, not a claim that future pull requests have already passed remote CI.

## Reproduction

From the repository root, run python -m unittest discover -s tests -v and python -m analytics.evaluate. From mobile/, run flutter pub get, flutter analyze, flutter test, and flutter build web --no-web-resources-cdn.

For PostgreSQL, install requirements.txt, set TEST_DATABASE_URL to a disposable test database, and run python -m unittest discover -s tests_postgres -v. The test uses its own temporary schema.

After adding the analytics files, an existing container needs a rebuild: docker compose up -d --build. Open http://127.0.0.1:8000 and check account access, transactions, category suggestions, Insights, and Planning. The demo data contains a multi-month history; a new empty account correctly shows insufficient forecast history.

## Remaining manual checks

| Scenario | Evidence status |
| --- | --- |
| Recreate application/PostgreSQL containers and confirm persistent account data | Passed locally |
| Android emulator and physical device | Pending device run |
| Keyboard, screen reader, and 200% browser zoom | Pending manual session |
| Real-user task study and observations | Pending participant sessions |
| Integrated browser walkthrough before handoff | Passed locally for the scenarios described above |
| Confirm the final merged GitHub version matches the tested source | Pending team merge |

Record actual observations and screenshots after running these checks. Keep the shared diploma report and screenshot PDFs outside the repository.
