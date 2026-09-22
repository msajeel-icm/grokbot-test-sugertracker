# Sugar Tracker API (M1)

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
| GET | `/api/v1/me` | Bearer | profile; streaks are `0` |
| PATCH | `/api/v1/me` | Bearer | `{daily_sugar_limit_g?, timezone?}` |

Passwords are hashed with bcrypt. Tokens are HS256 JWTs (`JWT_SECRET`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`).

`DATABASE_URL` defaults to `sqlite:///./sugar.db` (resolved under this directory). A Postgres URL such as `postgresql+psycopg://user:pass@localhost:5432/sugar` uses the same models; install `psycopg` when you switch.

## curl

```bash
curl -s -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"demo@sugar.app","password":"demo1234"}'

curl http://127.0.0.1:8000/api/v1/me -H "Authorization: Bearer TOKEN"
```
