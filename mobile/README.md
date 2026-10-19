# Flutter client

The client supports account access, dated income and expense records, CSV import, balance totals, search, filters, category and monthly charts, budgets, and savings goals. It handles loading, empty data, invalid input, connection failures, and uncertain save results.

The analytical interface accepts category suggestions and expense forecasts when the team's analytics module is connected. Without it, manual category entry and recorded spending charts remain available.

Development and build commands are in docs/RUNNING.md. The included unit tests check exact amount parsing and currency formatting. Android source is included, but the verified runnable build targets the web browser.
