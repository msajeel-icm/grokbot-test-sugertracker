# Sugar Tracker

Monorepo for a sugar-tracking app. The API covers accounts, JWT auth, meals, a stub food estimate, a daily dashboard, and streaks.

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

# 2. Confirm / log the meal. local_date is stored as sent.
curl -s -X POST http://127.0.0.1:8000/api/v1/meals \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"sugar_g":12,"label":"chocolate chip cookie","local_date":"2026-09-22"}'

# Meals for one local date
curl -s "http://127.0.0.1:8000/api/v1/meals?date=2026-09-22" \
  -H "Authorization: Bearer TOKEN"

# 3. Dashboard for the user's local today
curl -s http://127.0.0.1:8000/api/v1/dashboard \
  -H "Authorization: Bearer TOKEN"
```

Analyze returns `sugar_g`, `label`, `confidence`, `remaining_budget_g` (limit minus today's logged sugar), `would_exceed`, and `suggestion`. `suggestion.fractions` is `["1/3","1/2"]` and `suggestion.fraction_sugar_g` is those portions of `sugar_g`. When the estimate would exceed the remaining budget, `suggestion.alternatives` includes at least two low-sugar foods (grilled chicken, cucumber, and similar).

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

## Layout

```
backend/
  app/           FastAPI package (auth, meals, analyze stub, dashboard, streaks)
  requirements.txt
  .env.example
mobile/          Flutter client
```

## Mobile

The Flutter app lives in [`mobile/`](mobile/README.md).

Out of scope: a real vision model, third-party food APIs, push notifications, social features, and offline sync.
