# Sugar Tracker (Flutter)

Sugar-first daily log. Calories are shown next to sugar and do not change the limit.

Run the API from the repo root, then:

```bash
flutter pub get
flutter run --dart-define=API_BASE=http://127.0.0.1:8000
flutter test
```

`API_BASE_URL` is accepted as the same override. With neither set, Android emulators use `http://10.0.2.2:8000` and other targets use `http://127.0.0.1:8000`.

Demo account: `demo@sugar.app` / `demo1234`. Create account registers, then asks for a daily sugar limit. Settings also edits the IANA timezone. See the [repo README](../README.md) for the API fields and screens.

```bash
SUGAR_LIVE_API=1 flutter test test/live/api_live_test.dart
```
