from fastapi.testclient import TestClient


def test_health(client: TestClient) -> None:
    for path in ("/health", "/api/v1/health"):
        response = client.get(path)
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


def test_demo_user_can_log_in(client: TestClient) -> None:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "demo@sugar.app", "password": "demo1234"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"]
    assert body["user"]["email"] == "demo@sugar.app"
    assert body["user"]["daily_sugar_limit_g"] == 15.0
    assert body["user"]["timezone"] == "UTC"
    assert body["user"]["current_streak"] == 0
    assert body["user"]["best_streak"] == 0


def test_register_and_login(client: TestClient) -> None:
    registered = client.post(
        "/api/v1/auth/register",
        json={"email": "new@sugar.app", "password": "password1"},
    )
    assert registered.status_code == 201
    created = registered.json()
    assert created["user"]["email"] == "new@sugar.app"
    assert created["user"]["daily_sugar_limit_g"] == 15.0
    assert created["access_token"]

    duplicate = client.post(
        "/api/v1/auth/register",
        json={"email": "New@sugar.app", "password": "password1"},
    )
    assert duplicate.status_code == 409

    logged_in = client.post(
        "/api/v1/auth/login",
        json={"email": "new@sugar.app", "password": "password1"},
    )
    assert logged_in.status_code == 200
    assert logged_in.json()["user"]["id"] == created["user"]["id"]

    wrong = client.post(
        "/api/v1/auth/login",
        json={"email": "new@sugar.app", "password": "not-the-password"},
    )
    assert wrong.status_code == 401


def test_me_requires_token_and_updates_profile(client: TestClient) -> None:
    missing = client.get("/api/v1/me")
    assert missing.status_code == 401

    invalid = client.get("/api/v1/me", headers={"Authorization": "Bearer not-a-token"})
    assert invalid.status_code == 401

    registered = client.post(
        "/api/v1/auth/register",
        json={"email": "profile@sugar.app", "password": "password1"},
    )
    token = registered.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    me = client.get("/api/v1/me", headers=headers)
    assert me.status_code == 200
    assert me.json()["email"] == "profile@sugar.app"
    assert me.json()["current_streak"] == 0
    assert me.json()["best_streak"] == 0

    updated = client.patch(
        "/api/v1/me",
        headers=headers,
        json={"daily_sugar_limit_g": 25, "timezone": "America/New_York"},
    )
    assert updated.status_code == 200
    body = updated.json()
    assert body["daily_sugar_limit_g"] == 25.0
    assert body["timezone"] == "America/New_York"

    again = client.get("/api/v1/me", headers=headers)
    assert again.json()["daily_sugar_limit_g"] == 25.0
    assert again.json()["timezone"] == "America/New_York"

    bad_tz = client.patch("/api/v1/me", headers=headers, json={"timezone": "Not/AZone"})
    assert bad_tz.status_code == 422

    negative = client.patch("/api/v1/me", headers=headers, json={"daily_sugar_limit_g": -1})
    assert negative.status_code == 422
