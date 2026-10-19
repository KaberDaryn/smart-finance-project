# Running the local project

## Local web demonstration

Python 3.11 or newer is required. The SQLite demonstration has no third-party Python dependencies. Extract the ZIP, open its smart-finance folder, and run START_LOCAL.cmd on Windows, or run:

```sh
python -m backend.server
```

Open http://127.0.0.1:8000 and create an account. The compiled Flutter client is served by the same process. Keep the terminal open while using the application. Stop the process with Ctrl+C.

For fictional sample data, run START_DEMO.cmd, or run `python -m backend.demo` before starting the server. Sign in with username `demo` and password `DemoFinance2026!`. The seed creates only a separate demo account and leaves existing accounts unchanged. Running it again keeps the existing demo data. This published password is only for the fictional local demonstration.

The local database is created in data/finance.db. No existing user database is included in the ZIP. If port 8000 is occupied, set PORT to another free port before starting the server and open that address.

## PostgreSQL with Docker

With Docker Desktop running, execute these commands in the extracted project directory:

```sh
docker compose up --build -d
docker compose exec api python -m backend.demo
```

Open http://127.0.0.1:8000. PostgreSQL data remains in the named volume after a container restart. `docker compose down` stops the services without removing the volume. The database password can be changed in a local .env file based on .env.example. A password change on an existing volume also requires changing the PostgreSQL role password; a new environment value does not reset an existing database.

## Editing the client

The client was built with Flutter 3.44.2 and Dart 3.12.2. From mobile/:

```sh
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
flutter analyze
flutter test
```

The default API address is the current web origin. The explicit address above is needed when the Flutter development server uses another port. An Android emulator uses http://10.0.2.2:8000. Android source is included; a physical-device or release-APK run has not been verified in this version.

`scripts/build_web.ps1` rebuilds the client and copies it into web/. Its fonts and CanvasKit assets are bundled locally. The Python server should then be restarted if its source also changed.
