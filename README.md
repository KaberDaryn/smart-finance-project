# Smart Finance

Smart Finance is a team diploma project for personal finance planning and expense analysis in KZT. The application combines a Flutter client, a Python API, and relational storage. The current version contains the application and backend work by Daryn Kaber.

## Application

Users can create an account, record dated income and expenses, search their history, and view their balance. CSV import checks the complete input before saving records and recognises repeated imports of the same data. Each account has separate transactions, monthly budgets, and savings goals.

The Insights screen displays expense categories and monthly totals. Planning shows budget usage, overspending alerts, and savings progress. Category suggestions and forecasting use an optional analytics interface. The application continues to work while that module is not connected.

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

The local browser application runs with Python 3.11 or newer. START_LOCAL.cmd starts the server, and START_DEMO.cmd adds a fictional demonstration account. Docker Compose runs the same application with PostgreSQL. The current release is for local demonstration; production hosting and native Android testing remain outside the verified scope.
