# Smart Finance — integrated web frontend

The frontend is the four hand-written files in `web/`: `index.html`, `styles.css`, `app.js`, and `favicon.png`. There is no build step and no framework; the Python backend serves them as-is. The Flutter Android app in `mobile/` opens this same frontend in an embedded WebView. The old Flutter web target and its build-to-`web/` script have been removed so they cannot replace the current frontend.

## Run locally (Windows)
1. Run `START_LOCAL.cmd` (starts `python -m backend.server`).
2. Open http://127.0.0.1:8000 in your browser.
3. Sign in, or select **Create a new account**. `START_DEMO.cmd` instead creates the fictional demonstration account (`demo` / `DemoFinance2026!`) with six months of clearly marked sample data, then starts the server.

Python and the dependencies in `requirements.txt` are required. Configure the database using the project instructions if needed. To change the interface, edit the files in `web/` and refresh the browser.

## Pages and API calls
Authentication uses `POST /auth/register` and `POST /auth/login`; the session token is kept in `localStorage` and sent as a Bearer header, and `POST /auth/logout` revokes it on sign-out. API errors surface as toasts or inline form messages; a 401 sends the user back to the sign-in screen.

- **Overview** — `GET /summary`, `GET /analytics`, `GET /budgets`, `GET /goals`, and `GET /transactions` feed the stat cards, cash-flow chart, budget snapshot, recent transactions, and savings goal previews.
- **Transactions** — `GET /transactions` with client-side search and type/category/month filters; `POST /transactions` to add, `POST /transactions/delete` to remove a row; `POST /transactions/import` for CSV import; Export builds a CSV in the browser from the current records; a receipt scanning entry point is also here.
- **Insights** — `GET /analytics` for the category donut, monthly trend, and observations generated from the user's own records; the forecast follows the analytics module's three-complete-months rule.
- **Planning** — `GET /budgets?month=YYYY-MM` with month navigation, `POST /budgets` and `POST /budgets/delete` for limits; `GET /goals`, `POST /goals`, `POST /goals/update`, and `POST /goals/delete` for savings goals.
- **Category suggestion** — `POST /analytics/classify` with the expense description returns a suggested category that can be accepted or edited before saving.

## Receipt flow
1. Choose **Scan receipt** and pick a JPEG/PNG/WebP photo up to 5 MiB.
2. The photo is sent as raw bytes to `POST /receipts/parse`; it is not stored by this app.
3. Review and, if needed, edit the recognized merchant, date, total, and category.
4. Confirm explicitly; only then is the expense saved through `POST /transactions`. Nothing is saved during recognition.

Recognition requires a configured server-side provider (see `docs/RECEIPTS.md` and `.env.example`). Without it the UI shows the API error and manual entry still works. Non-KZT receipts must be converted to KZT by the user before saving; the original amount and currency are kept in the description.

## CSV import
Headers `date,kind,amount,category[,description]`. The description column is optional; amounts are ordinary decimal KZT (1500.01, not minor units). There is a maximum of 1000 rows per import. The whole file is validated before anything is saved, the batch is applied atomically, and identical CSV content is detected as a duplicate instead of being imported again.

## Data conventions
- This frontend connects to the actual API; it does not use fictional transaction data. The only seeded data is the demo account created by `START_DEMO.cmd`.
- Amounts are submitted as integer minor units to match the API contract (150001 represents 1500.01 KZT); the UI converts between minor units and decimal tenge for display and input.
- Categories match the analytics module. Expenses: Groceries, Transport, Housing, Entertainment, Health, Cafe, Clothing, Other. Income: Salary, Freelance, Bonus, Investment, Gift, Other.

Automated backend tests pass (`python -m unittest discover -s tests`). The browser flow still needs a manual check with a configured receipt provider before pushing.
