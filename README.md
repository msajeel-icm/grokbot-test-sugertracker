# Sugar Tracker

Monorepo for a sugar-tracking app. **M1** is the API only: accounts, JWT auth, and a user profile with a daily sugar limit.

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

### curl

```bash
# Health
curl http://127.0.0.1:8000/health

# Register
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"you@example.com","password":"password1"}'

# Login (demo user)
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@sugar.app","password":"demo1234"}'

# Profile (replace TOKEN)
curl http://127.0.0.1:8000/api/v1/me \
  -H "Authorization: Bearer TOKEN"

curl -X PATCH http://127.0.0.1:8000/api/v1/me \
  -H "Authorization: Bearer TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"daily_sugar_limit_g":20,"timezone":"America/Los_Angeles"}'
```

Register and login return `access_token`, `token_type` (`bearer`), and `user`. `GET /api/v1/me` includes `current_streak` and `best_streak` (both `0` until streak tracking exists).

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
  app/           FastAPI package (models, auth, /me)
  requirements.txt
  .env.example
```

Out of scope for M1: meals, analysis, dashboard, streak logic, and the Flutter client.
