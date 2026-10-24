# Receipt recognition

## Request and response

`POST /receipts/parse` uses the same `Authorization: Bearer ...` session as `/transactions`. Send raw photo bytes with `Content-Type: image/jpeg`, `image/png`, or `image/webp`, and a `Content-Length` of at most 5 MiB. This endpoint does not use multipart or JSON uploads. Authentication is checked before reading the photo or calling the recognition service.

```json
{
  "merchant": "Magnum",
  "date": "2026-10-20",
  "total": 1500.01,
  "currency": "KZT",
  "category": "Groceries",
  "category_source": "remembered"
}
```

All fields can be null. `category_source` is `remembered` only when a category is found in the current user's merchant memory. The recognition prompt asks for only merchant/date/total/currency; any category returned by the service is ignored. No category classifier is called by this flow.

The server strips optional JSON fences and validates the response object. Missing, uncertain, or invalid fields become null so the client requires review. Dates must be ISO calendar dates within the last 3653 days and no later than today (UTC). Totals must be finite positive numbers, at most 10^10 major units, and exact to two decimal places or fewer. This matches the existing ledger's 10^12 minor-unit limit. Currencies are limited to KZT/RUB/USD/EUR. Merchant names must contain a name and be at most 200 characters.

Bad uploads return 400, missing/expired sessions return 401, and unreadable service responses return 502. Missing keys, unsupported provider configuration, quota exhaustion, and service unavailability return 503. Gemini requests may take up to 120 seconds; the client waits up to 150 seconds for the complete response before showing a timeout message. Provider timeouts return 504. Errors contain a user-readable message, never the key or raw service response. The client offers retry and manual entry.

## Storage

`backend/migrations/001_merchant_categories.sql` adds `merchant_categories` with primary key `(user_id, merchant_key)` and a foreign key to `users`. The existing schema initializer executes this idempotent SQL at connection initialization, for both SQLite and PostgreSQL. Restart the server after deploying the change. There is no separate migration framework.

`POST /transactions` accepts an optional `merchant` for an authenticated expense. The confirmed category is saved with the expense by `store.add` in one database transaction. Updating that merchant's category affects future suggestions, without changing older transactions. Rejected or rolled-back expense saves never change category memory. Other transaction clients keep their existing payloads.

The merchant is kept in the expense description by the confirmation form. No photo or raw recognition response is stored. The ledger schema and its KZT summaries stay unchanged; foreign receipts require manual KZT conversion and retain their original amount/currency in the description.

Normalization removes `№` before Unicode NFKC conversion, applies case folding, tokenizes letters, removes digits, quotes, punctuation, legal-form tokens (ТОО/ИП/АО/ООО/LLC), and common branch/store words, then collapses spaces. Explicit aliases make `Magnum Cash&Carry`, `Magnum Cash and Carry`, and `Магнум` share the key `magnum`. Other brand names retain all meaningful words, avoiding broad prefix matching. This simple MVP can merge names distinguished only by numbers; extend explicit aliases with labelled examples if needed.

## Providers and privacy

`backend/receipt_providers.py` defines the `ReceiptProvider` interface and registry. To add a provider, implement `extract(image, mime_type) -> str`, register its configuration name, and choose that name through `RECEIPT_PROVIDER`. The default Gemini adapter uses the documented `generateContent` REST interface, inline image bytes, and a key read from `GEMINI_API_KEY`. `RECEIPT_MODEL` is server-side configuration. There are no provider credentials or direct provider calls in the client.

The default `gemini-3.8-flash` model's [image input support](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash) and [free-tier pricing](https://ai.google.dev/gemini-api/docs/pricing) were checked on 2026-10-23. API details follow the [image input guide](https://ai.google.dev/gemini-api/docs/image-understanding). Free-tier submissions may be used to improve the external service under its terms. The consent notice is shown before upload; use synthetic or redacted photos for demonstrations. The application keeps uploads in request memory and does not log photo contents or raw service responses.

## Evaluation

`python -m backend.evaluate_receipts IMAGE_FOLDER GROUND_TRUTH_JSON --output data/receipt-evaluation.json` uses the same recognition/validation code as the endpoint, without category lookup. Each ground-truth object has a relative `file` and optional labelled `merchant`, `date`, and `total`. Missing or null labels are excluded from the corresponding field's denominator. Failed requests count as incorrect for every labelled field in that row.

Merchant accuracy compares normalized keys; date accuracy uses exact ISO dates; total accuracy compares exact numeric amounts with `Decimal`. The report includes correct/evaluated counts per field, the configured provider/model, failures, per-image matches, and response time in seconds (mean, median, nearest-rank p95). Timing includes local file reading, the provider request, and parsing. Images must be JPEG/PNG/WebP and at most 5 MiB. The output omits extracted merchant names, totals, and raw responses, but filenames can still identify records: keep the dataset and output private under ignored `data/`.

Compare providers using the same labelled images and normalization rules. Record dataset size, languages, image conditions, model configuration, evaluation date, failures, and latency alongside scores. Use a separate evaluation set rather than selecting only successful receipts. No real dataset or measured recognition scores are included in the repository.
