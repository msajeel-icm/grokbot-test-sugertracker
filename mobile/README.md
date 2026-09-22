# Sugar Tracker mobile

Flutter client for the sugar tracker API. It signs in, stores the JWT, shows today’s sugar against the daily limit, and logs a meal only after you confirm an estimate.

## Screens

- **Sign in** and **Create account**
- **Daily limit** after registration, and again in **Settings** (12 g, 15 g, or a custom amount). Settings also edits the IANA timezone.
- **Today**: consumed vs limit, remaining, current streak, best streak, today’s meals, and **Log meal**
- **Log meal**: a text hint, a photo, or both. **Estimate sugar** calls analyze and does not log.
- **Review**: sugar, whether the full portion would go over, portion buttons, and lower-sugar ideas
  - **Log full** / **Log 1/3** / **Log 1/2** confirm a meal
  - **Cancel** returns without logging

## Run against the local API

From the repo root, start the API first (Python 3.11+):

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API listens on `http://127.0.0.1:8000`. Then, in another terminal, with Flutter stable on your `PATH`:

```bash
cd mobile
flutter pub get
flutter run
```

### API address

| Where the app runs | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000` (the default) |
| iOS Simulator | `http://127.0.0.1:8000` (the default) |
| Anywhere else | pass it in |

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

The sign-in screen prints the URL it is using. A physical phone cannot use `10.0.2.2` or the phone’s own `127.0.0.1`. Point it at your computer’s LAN address and start the API on all interfaces:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Cleartext HTTP is enabled (Android `usesCleartextTraffic`, iOS arbitrary loads) so this build can talk to a local API.

### Demo account

Created when the API starts.

| Field | Value |
| --- | --- |
| Email | `demo@sugar.app` |
| Password | `demo1234` |
| Daily sugar limit | 15 g |
| Timezone | UTC |

Try a hint such as `cookie`, `apple`, or `cola`. Estimates come from the API’s built-in catalog, not from a vision model. The same photo bytes always map to the same food; a matching hint wins.

## What the app calls

| Action | Request |
| --- | --- |
| Sign in / register | `POST /api/v1/auth/login`, `POST /api/v1/auth/register` |
| Profile and limit | `GET /api/v1/me`, `PATCH /api/v1/me` |
| Estimate | `POST /api/v1/meals/analyze` (JSON `hint`, or multipart `image` plus optional `hint`) |
| Confirm | `POST /api/v1/meals` with `sugar_g` and `label` |
| Today | `GET /api/v1/dashboard` (meals for one date: `GET /api/v1/meals?date=YYYY-MM-DD`) |

The JWT is stored with `flutter_secure_storage` and sent as `Authorization: Bearer`. Log out deletes it. Analyze does not create a meal. Portion buttons send `suggestion.fraction_sugar_g` from the estimate (`1/3` and `1/2`). A chosen photo’s bytes go to analyze; confirm only stores the device path as `photo_ref` when it fits.

## Tests

```bash
cd mobile
flutter analyze
flutter test
```

To exercise the client against a running API:

```bash
SUGAR_LIVE_API=1 flutter test test/live/api_live_test.dart
```

`API_BASE_URL` overrides the default `http://127.0.0.1:8000` for that run. The live test signs in as the demo user, then registers a throwaway account for the write path.

## Limits

- Android emulator networking uses `10.0.2.2`. A device on Wi-Fi needs a LAN URL, and the API must bind to `0.0.0.0`.
- The app expects the meals, analyze, and dashboard routes. Auth alone is not enough for the home screen.
- No real vision or nutrition model, push notifications, or offline sync.
- Android 7 / API 24 or newer. iOS uses the system photo picker.
