# Smart Finance — integrated frontend

The refreshed web interface is served by the existing Python backend and uses its real API for authentication, transactions, summary, analytics, budgets and savings goals.

## Run locally (Windows)
1. Extract this ZIP.
2. Run `START_LOCAL.cmd`.
3. Open http://127.0.0.1:8000 in your browser.
4. Sign in, or select **Create a new account**.

Python and the dependencies in `requirements.txt` are required. Configure the database using the project instructions if needed. The browser frontend is in `web/`; Flutter source remains in `mobile/`.

## Notes
- This frontend connects to the actual API; it does not use fictional transaction data.
- Amounts are submitted as integer minor units to match the API contract.
- Receipt scanning is available in Transactions: choose a JPEG/PNG/WebP photo up to 5 MiB, accept the processing notice, recognize it, review/edit the fields, and explicitly confirm to save the expense. The photo is sent as raw bytes to `POST /receipts/parse`; it is not stored by this app.
- Receipt recognition requires a working server-side provider configuration (see `docs/RECEIPTS.md` and `.env.example`). If it is not configured, the UI shows the API error and you can enter the expense manually.
- Non-KZT receipts must be converted to KZT by the user before saving; the original receipt amount/currency is retained in the description. CSV import is still not exposed in this redesigned UI.
- Automated backend tests pass (`python -m unittest discover -s tests -v`). The browser flow still needs a manual check with a configured receipt provider before pushing.
