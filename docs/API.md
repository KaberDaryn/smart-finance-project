# API reference

The local browser client and API share http://127.0.0.1:8000. JSON responses use UTF-8. Private routes require `Authorization: Bearer <session token>`. Public routes are /health, the static web client, registration, and login. Amount fields ending in _minor are integers; 150001 represents 1500.01 KZT. JSON request bodies are bounded to 16 KiB, except CSV imports, which allow 128 KiB. Receipt uploads accept raw image bytes up to 5 MiB.

| Method | Route | Request or result |
| --- | --- | --- |
| GET | /health | Health status |
| POST | /auth/register | username (3-40 ASCII letters/digits/underscores), password (10-128 characters); returns token/user/expiry |
| POST | /auth/login | username/password; returns token/user/expiry |
| GET | /auth/me | Current account ID and username |
| POST | /auth/logout | Empty object; revokes the current token |
| GET | /transactions | Current account's records, descending date and ID |
| POST | /transactions | kind, amount_minor, category, optional description and date (YYYY-MM-DD); optional merchant on authenticated expenses updates category memory |
| POST | /receipts/parse | Raw JPEG/PNG/WebP photo; returns merchant, date, total, currency, category, category_source; does not save an expense |
| POST | /transactions/import | csv string; returns imported count and duplicate flag |
| GET | /summary | Income, expense, balance totals, and currency |
| GET | /analytics | Category shares, up to 12 recorded month totals, forecast, current budgets, and spending observations |
| POST | /analytics/classify | description; returns a category or null, an uncalibrated confidence score, and a model note |
| GET | /budgets?month=YYYY-MM | Budget limits and spending for that month; defaults to the current UTC month |
| POST | /budgets | month, category (or * for all expenses), amount_minor; inserts or updates a limit |
| GET | /goals | Current account's goals |
| POST | /goals | name, target_minor, optional saved_minor |
| POST | /goals/update | id, saved_minor; owner-only progress update |

Transactions and goals return 201 on creation. Login, logout, classification, imports, budget saves, and goal progress updates return 200. Registration returns 201. Invalid input returns 400, missing/expired credentials 401, duplicate usernames 409, and too many authentication attempts 429. Unexpected storage failures return 500 with no database details.

Receipt parsing returns 200, or 502 for unreadable service responses, 503 for missing configuration, quota limits, or service unavailability, and 504 for provider timeouts. See [receipt validation, category memory, and evaluation](RECEIPTS.md).

An example transaction body is:

```json
{"kind":"expense","amount_minor":150001,"category":"Groceries","description":"Food shopping","date":"2025-01-15"}
```

CSV uses `date,kind,amount,category,description` headers. The description column is optional; amount is an ordinary KZT decimal. There is a maximum of 1000 rows and 120000 bytes of CSV text. The batch is atomic. Duplicate detection applies to identical CSV content, not to semantically similar files edited afterwards.

Unavailable analytics modules return 503 for category suggestions. Forecast responses can use status unavailable.

Category matching for budgets uses exact category names. Savings updates do not create financial transactions. Forecasts use completed calendar months in UTC; missing history after the first recorded expense counts as zero.
