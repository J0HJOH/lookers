# Lookers app (Flutter)

This folder is the whole app. **One codebase** builds the website, the Android app and the iPhone app.

- `lib/` – the app code, shared by all platforms
- `android/`, `ios/`, `web/` – the per-platform wrappers
- `test/` – automated tests (`flutter test`)
- `tool/` – icon and screenshot generators

Run it with your settings (see the root [README](../README.md) and [docs/SETUP.md](../docs/SETUP.md)):

```bash
flutter run --dart-define-from-file=env.json
```
