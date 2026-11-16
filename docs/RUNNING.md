# Running the local project

## Local web demonstration

Python 3.11 or newer is required. The SQLite demonstration has no third-party Python dependencies. Extract the ZIP, open its smart-finance folder, and run START_LOCAL.cmd on Windows, or run:

```sh
python -m backend.server
```

Open http://127.0.0.1:8000 and create an account. The server serves the hand-written frontend from `web/`. Keep the terminal open while using the application. Stop the process with Ctrl+C.

For fictional sample data, run START_DEMO.cmd, or run `python -m backend.demo` before starting the server. Sign in with username `demo` and password `DemoFinance2026!`. The seed creates only a separate demo account and leaves existing accounts unchanged. Running it again keeps the existing demo data. This published password is only for the fictional local demonstration.

The local database is created in data/finance.db. No existing user database is included in the ZIP. If port 8000 is occupied, set PORT to another free port before starting the server and open that address.

## PostgreSQL with Docker

With Docker Desktop running, execute these commands in the extracted project directory:

```sh
docker compose up --build -d
docker compose exec api python -m backend.demo
```

Open http://127.0.0.1:8000. PostgreSQL data remains in the named volume after a container restart. `docker compose down` stops the services without removing the volume. The database password can be changed in a local .env file based on .env.example. A password change on an existing volume also requires changing the PostgreSQL role password; a new environment value does not reset an existing database.

## Android app

The Android app uses a Flutter shell with an embedded WebView, so it opens the same frontend as the browser without Chrome controls. Start the backend in one terminal:

```sh
python -m backend.server
```

In another terminal, run the app from `mobile/`:

```sh
cd mobile
flutter pub get
flutter run -d emulator-5554
```

The app defaults to `http://10.0.2.2:8000`, the Android emulator's address for the host computer. To use a different backend, pass `--dart-define=WEB_APP_URL=http://HOST:PORT` to `flutter run`.

## Editing the frontend

The current frontend is in `web/`: `index.html`, `styles.css`, and `app.js`. Edit those files directly. The Flutter app loads the same frontend from the Python server.
