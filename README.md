# Smart Finance

Smart Finance is a team diploma project for personal finance planning and expense analysis in KZT. The application combines a Flutter client, a Python API, and relational storage. The team implementation covers transaction recording, spending analysis, and financial planning.

## Application

Users can create an account, record dated income and expenses, search their history, and view their balance. CSV import checks the complete input before saving records and recognises repeated imports of the same data. Each account has separate transactions, monthly budgets, and savings goals.

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

The local browser application runs with Python 3.11 or newer. START_LOCAL.cmd starts the server, and START_DEMO.cmd adds a fictional demonstration account. Docker Compose runs the same application with PostgreSQL. The current release is for local demonstration; production hosting and native Android testing remain outside the verified scope.
