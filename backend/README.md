# Sugar Tracker API

FastAPI + SQLAlchemy + SQLite. JWT access tokens. See the [repo README](../README.md) for the full quick start.

## Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Startup creates tables and seeds the demo user if missing. You can also seed without serving:

```bash
python -m app.seed
```

## Demo credentials

- Email: `demo@sugar.app`
- Password: `demo1234`
- `daily_sugar_limit_g`: `15`
- Timezone: `UTC`

## Endpoints

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/health`, `/api/v1/health` | no | `{"status":"ok"}` |
| POST | `/api/v1/auth/register` | no | `{email, password}` → token + user |
| POST | `/api/v1/auth/login` | no | `{email, password}` → token + user |
| GET | `/api/v1/me` | Bearer | profile plus `current_streak` and `best_streak` |
| PATCH | `/api/v1/me` | Bearer | `{daily_sugar_limit_g?, timezone?}` |
| POST | `/api/v1/meals/analyze` | Bearer | JSON `{"hint"?}` or multipart `image` + optional `hint`. Does not log. |
| POST | `/api/v1/meals` | Bearer | Confirm a meal: `{sugar_g, label, local_date?, photo_ref?, notes?}` |
| GET | `/api/v1/meals?date=YYYY-MM-DD` | Bearer | Logged meals for that local date |
| GET | `/api/v1/dashboard` | Bearer | Today's limit, consumed, remaining, meals, streaks |

`POST /meals/analyze` is a local catalog stub. It never calls a vision or nutrition API. `remaining_budget_g` is the daily limit minus today's logged sugar. `would_exceed` is true when the estimate is greater than that remainder. `suggestion.fraction_sugar_g` is about one third and one half of the estimate. A client `local_date` is stored unchanged; otherwise the date comes from the user's timezone. `logged_at` is always UTC.

A streak day is a local date whose logged sugar is strictly under the limit. The current streak is that run ending today, or ending yesterday when today has no meals yet. A day at or over the limit breaks the current streak. `best_streak` keeps the longest run.

Passwords are hashed with bcrypt. Tokens are HS256 JWTs (`JWT_SECRET`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`).

`DATABASE_URL` defaults to `sqlite:///./sugar.db` (resolved under this directory). A Postgres URL such as `postgresql+psycopg://user:pass@localhost:5432/sugar` uses the same models; install `psycopg` when you switch.

## curl

```bash
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@sugar.app","password":"demo1234"}'

curl -s -X POST http://127.0.0.1:8000/api/v1/meals/analyze \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"hint":"chocolate chip cookie"}'

curl -s -X POST http://127.0.0.1:8000/api/v1/meals \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"sugar_g":12,"label":"chocolate chip cookie"}'

curl -s http://127.0.0.1:8000/api/v1/dashboard \
  -H "Authorization: Bearer TOKEN"
```
