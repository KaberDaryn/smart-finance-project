# Analytics integration

The application exposes authenticated GET /analytics and POST /analytics/classify routes. backend/analytics_bridge.py connects these routes to the team's analytics package.

The categorisation module provides `analytics.category_model.default_model().predict(description)`. Its response contains `category` (a string or null) and `confidence` (a numeric score). The client allows the category to be edited before saving.

The insights module provides `analytics.insights.build_insights(transactions)`. Its result contains currency, categories, months, and forecast. Categories use category, amount_minor, and share fields. Monthly entries use month and expense_minor. Forecast responses use status, forecast_month, and forecast_minor when available.

Until these modules are connected, category suggestions return HTTP 503 with a manual-entry message. The application calculates recorded category and monthly totals itself; forecasting returns status unavailable. This keeps account access, transactions, imports, budgets, and goals usable independently of analytics.
