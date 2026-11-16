# Android app

The Flutter Android app opens the current Smart Finance frontend from `../web/` in an embedded WebView. The retired Flutter web target has been removed, so `flutter run` on Android launches the same frontend as the browser app.

Start the backend from the repository root with `python -m backend.server`, then run from this directory:

```sh
flutter pub get
flutter run -d emulator-5554
```

The default URL is `http://10.0.2.2:8000`. Override it with `--dart-define=WEB_APP_URL=http://HOST:PORT` when using another server.
