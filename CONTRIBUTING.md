# Development workflow

Clone https://github.com/KaberDaryn/smart-finance-project and create a task branch from the latest main. Review changes locally, run the relevant checks, and open a pull request using your own GitHub account.

The application and analytics share one API contract, documented in docs/INTEGRATION.md. Changes to request or response fields need matching integration tests. Backend code, client code, and analytical modules are released together.

Use short English commit titles. Keep local databases, passwords, build caches, and personal data outside version control. Demo fixtures are fictional. The shared diploma report and screenshot submissions are maintained separately from the repository.
