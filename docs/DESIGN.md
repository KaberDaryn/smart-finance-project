# Interface design and user journeys

## Design approach

The interface supports a short recording task first, then analysis and planning. Material controls provide familiar interaction and keyboard behaviour. Transactions, Insights, and Planning are the three main destinations; login and import are separate tasks.

The palette uses a green seed (#255C48) with a light background (#F7FAF7). Roboto regular, medium, and bold are bundled with their licence. Page padding is 24 logical pixels, field separation is 20, and section separation is generally 32-40. Content is capped at 900 pixels; forms use 460-760 pixels. On narrow screens, long category names, descriptions, and amounts wrap rather than competing in a fixed trailing column.

## Screen specification

| Screen | Main decision | Content and controls |
| --- | --- | --- |
| Account access | Sign in or create an account | Username, obscured password, inline validation, clear connection errors |
| Transactions | Record or find an operation | Balance/income/expense totals, search, type filters, dated list, add action |
| Add transaction | Save a valid financial record | Type, exact KZT amount, date, category, description, optional category suggestion |
| Insights | Understand recorded spending | Category shares, monthly bars, forecast with history requirements, budget observations |
| Planning | Set a limit or track savings | Overall/category monthly budgets, overspending messages, targets and saved amounts |
| CSV import | Bring multiple operations into the diary | Expected headers, multiline input, whole-file validation, import result |

## User journeys

1. New account: create an account, record an income, record an expense, inspect the resulting balance.
2. Category suggestion: write an expense description, request a suggestion, accept or edit it, then save.
3. Budget review: set a monthly overall or category budget, add an expense, inspect the in-app overspending alert.
4. Savings: create a target, enter the total amount saved, and inspect progress. This does not transfer money.
5. Import: paste CSV, submit, inspect the imported records. A repeat of the same CSV adds no duplicate rows.
6. Connection failure: keep form values, show recovery guidance, and allow the user to check the list before retrying an uncertain save.

## Accessibility and review

Controls use Material focus behaviour and labels. Errors and category suggestions use live-region semantics. Expense direction uses signs and icons as well as colour. Charts retain readable amounts and semantic descriptions. Widget tests cover a 320-pixel viewport and long labels. Screen-reader, physical-device, and 200% browser-zoom sessions remain part of the manual review matrix; no completed sessions are claimed.

This is a code-backed design specification. It is not an approved Figma file and does not claim supervisor sign-off.
