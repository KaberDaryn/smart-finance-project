# User guide

Create an account using a username and a password of at least ten characters. Sign in to open your personal diary. A refresh of the browser ends the in-memory login state, so sign in again when needed. Signing out revokes the current server session when the server is reachable.

The Transactions tab shows all recorded income and expenses. Add transaction opens a form with type, amount, date, category, and an optional description. Amounts use KZT with up to two decimal places. The date cannot be in the future. The list can be searched by category or description and filtered by income or expenses.

For an expense, Suggest category uses its English description to fill a category when possible. The suggestion is optional and can be changed. A successful save returns to the list and shows a confirmation. If the save cannot be confirmed, check the list before trying again.

The Import CSV action accepts copied CSV text with date,kind,amount,category headers and an optional description column. Amounts in CSV are ordinary KZT values, for example 1500.01. An invalid row prevents the entire import. Repeating the same CSV text does not create duplicate records.

Insights shows categories and monthly expense totals. Its estimate uses the previous three complete months, so a new account may not have enough history. Unrecorded months count as zero. A spending observation may identify the largest category or an exceeded budget; these messages do not move money.

Planning holds this month's overall or category budgets. Category names must match those used in transactions. Setting another budget for the same category and month updates its limit. Savings goals track a target and an entered saved amount; they are separate from the financial transaction balance.

All demonstration records are fictional. The sample demo account is described in RUNNING.md. A local demonstration does not provide bank synchronisation, password recovery, or mobile push notifications.
