# Sugar Tracker

Monorepo for a sugar-tracking app. The API covers accounts, JWT auth, meals, a stub food estimate, a daily dashboard, and streaks. The Flutter client in `mobile/` is a sugar-first daily log: a budget ring, meal rows, and light/dark neutrals. Calories are shown beside sugar and never change the limit.

## Demo account

Created automatically when the API starts (and by `python -m app.seed`).

| Field | Value |
| --- | --- |
| Email | `demo@sugar.app` |
| Password | `demo1234` |
| Daily sugar limit | `15` grams |
| Timezone | `UTC` |

## Run the API

Requires Python 3.11+.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The server listens on `http://127.0.0.1:8000`. Interactive docs: `http://127.0.0.1:8000/docs`.

SQLite file: `backend/sugar.db` (created on startup). Tables are created with SQLAlchemy `create_all`. Copy `backend/.env.example` to `backend/.env` to override `DATABASE_URL` or `JWT_SECRET`.

No vision or nutrition API key is required. `POST /api/v1/meals/analyze` picks from a built-in food catalog.

### curl

```bash
# Health
curl http://127.0.0.1:8000/health

# Login (demo user). Copy access_token into TOKEN below.
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@sugar.app","password":"demo1234"}'

# Profile
curl http://127.0.0.1:8000/api/v1/me \
  -H "Authorization: Bearer TOKEN"

# 1. Analyze. Does not log a meal.
curl -s -X POST http://127.0.0.1:8000/api/v1/meals/analyze \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"hint":"chocolate chip cookie"}'

# The same image bytes always map to the same catalog food. A matching hint wins.
curl -s -X POST http://127.0.0.1:8000/api/v1/meals/analyze \
  -H "Authorization: Bearer TOKEN" \
  -F "image=@meal.jpg" \
  -F "hint=cookie"

# 2. Confirm / log the meal. local_date is stored as sent. kcal is optional and defaults to 0.
curl -s -X POST http://127.0.0.1:8000/api/v1/meals \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"sugar_g":12,"kcal":160,"label":"chocolate chip cookie","local_date":"2026-09-22"}'

# Meals for one local date
curl -s "http://127.0.0.1:8000/api/v1/meals?date=2026-09-22" \
  -H "Authorization: Bearer TOKEN"

# 3. Dashboard for the user's local today
curl -s http://127.0.0.1:8000/api/v1/dashboard \
  -H "Authorization: Bearer TOKEN"
```

Analyze returns `sugar_g`, `kcal`, `label`, `confidence`, `remaining_budget_g` (limit minus today's logged sugar), `would_exceed`, and `suggestion`. `suggestion.fractions` is `["1/3","1/2"]`. `suggestion.fraction_sugar_g` and `suggestion.fraction_kcal` are those portions of the estimate. Alternatives include `sugar_g` and `kcal`. `would_exceed` and `remaining_budget_g` use sugar only: a 0 g / 165 kcal food such as grilled chicken does not exceed the budget, and a high-sugar food still does even when its calories are low.

`POST /api/v1/meals` stores optional `kcal` (default `0`). `GET /api/v1/meals` returns `kcal` on each meal. `GET /api/v1/dashboard` adds `consumed_kcal` for the day and `kcal` on each meal. Streaks still count a day only when logged sugar is strictly under the limit.

`GET /api/v1/me` and `GET /api/v1/dashboard` both include `current_streak` and `best_streak`. A local day counts when the sum of meals with `status=logged` is strictly under `daily_sugar_limit_g`. Consecutive under-limit days build the current streak. If today has no meals yet, the streak runs through yesterday. A logged day that meets or exceeds the limit sets `current_streak` to 0 and leaves `best_streak` at the longest run. Days with no logged meals are gaps.

## Tests

```bash
cd backend
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
```

## Postgres later

Set `DATABASE_URL` to a SQLAlchemy URL and install a driver. No model changes are required.

```bash
pip install "psycopg[binary]"
export DATABASE_URL=postgresql+psycopg://user:pass@localhost:5432/sugar
uvicorn app.main:app --reload
```

Change `JWT_SECRET` before any shared deployment. The default is for local development only.

## Flutter

Requires the Flutter SDK (stable). The app talks to the API above. Demo sign-in is `demo@sugar.app` / `demo1234` (seeded limit 15 g, timezone UTC).

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE=http://127.0.0.1:8000
```

Android allows cleartext HTTP so a local API works. Point `API_BASE` at an HTTPS host before any shared deploy. On a device or emulator, use the machine's LAN address instead of `127.0.0.1`.

```bash
cd mobile
flutter test
```

Screens:

- **Sign in.** Email and password. "Use demo account" fills the seeded credentials and still requires Sign in.
- **Home.** Sugar ring (consumed vs daily limit), remaining sugar, kcal today as a smaller line, current and best streaks, today's meals (sugar primary, kcal under it), and Log meal.
- **Log meal.** Hint and optional photo, then an estimate of sugar and kcal. If the full portion would exceed the sugar budget, a flat warning appears. Log full, 1/3, or 1/2 sends the scaled sugar and kcal. Cancel logs nothing.
- **Settings.** Sugar-limit presets (10, 15, 25, 36, 50 g) and System / Light / Dark. Empty days and failed loads have their own copy and a retry.

Visuals are near-black and off-white surfaces, 1 px borders, Inter, and one flat accent: teal under the sugar budget, amber at the limit, red over. There is no gradient or glow. Screenshots of light home, dark home, and the over-budget log step are attached on the pull request.

## Layout

```
backend/
  app/           FastAPI package (auth, meals, analyze stub, dashboard, streaks)
  requirements.txt
  .env.example
mobile/          Flutter client (sugar ring, log flow, settings)
```

Out of scope: a real vision model, third-party food APIs, push notifications, social features, and offline sync.
