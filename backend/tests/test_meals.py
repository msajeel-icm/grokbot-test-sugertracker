from datetime import timedelta
from uuid import uuid4

from fastapi.testclient import TestClient

from app.database import SessionLocal
from app.models import Meal, MealStatus, utcnow
from app.tracking import user_local_today


def _headers(client: TestClient) -> dict[str, str]:
    email = f"u-{uuid4().hex}@sugar.app"
    response = client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password1"},
    )
    assert response.status_code == 201, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _log(client: TestClient, headers: dict[str, str], **payload: object) -> dict:
    response = client.post("/api/v1/meals", headers=headers, json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_meal_routes_require_auth(client: TestClient) -> None:
    assert client.post("/api/v1/meals/analyze", json={"hint": "cookie"}).status_code == 401
    assert client.post("/api/v1/meals", json={"sugar_g": 1, "label": "apple"}).status_code == 401
    assert client.get("/api/v1/meals", params={"date": "2026-09-22"}).status_code == 401
    assert client.get("/api/v1/dashboard").status_code == 401


def test_budget_math_ignores_discarded_meals(client: TestClient) -> None:
    headers = _headers(client)
    me = client.get("/api/v1/me", headers=headers).json()
    today = user_local_today("UTC")

    db = SessionLocal()
    try:
        db.add(
            Meal(
                user_id=me["id"],
                label="cake slice",
                sugar_g=100,
                logged_at=utcnow(),
                local_date=today,
                status=MealStatus.discarded.value,
            )
        )
        db.commit()
    finally:
        db.close()

    under = client.post("/api/v1/meals/analyze", headers=headers, json={"hint": "cookie"})
    assert under.status_code == 200, under.text
    body = under.json()
    assert body["label"] == "chocolate chip cookie"
    assert body["sugar_g"] == 12
    assert body["remaining_budget_g"] == 15
    assert body["would_exceed"] is False
    assert body["suggestion"]["fractions"] == ["1/3", "1/2"]
    assert len(body["suggestion"]["alternatives"]) >= 2

    _log(client, headers, sugar_g=10, label="yogurt", local_date=today.isoformat())

    over = client.post("/api/v1/meals/analyze", headers=headers, json={"hint": "cookie"})
    assert over.status_code == 200, over.text
    over_body = over.json()
    assert over_body["remaining_budget_g"] == 5
    assert over_body["would_exceed"] is True
    labels = [item["label"] for item in over_body["suggestion"]["alternatives"]]
    assert "grilled chicken" in labels
    assert "cucumber" in labels

    dashboard = client.get("/api/v1/dashboard", headers=headers).json()
    assert dashboard["consumed_g"] == 10
    assert dashboard["remaining_g"] == 5
    assert dashboard["limit_g"] == 15


def test_fraction_sugar_on_analyze(client: TestClient) -> None:
    headers = _headers(client)
    response = client.post("/api/v1/meals/analyze", headers=headers, json={"hint": "cookie"})
    body = response.json()
    sugar = body["sugar_g"]
    portions = body["suggestion"]["fraction_sugar_g"]
    assert body["suggestion"]["fractions"] == ["1/3", "1/2"]
    assert portions["1/3"] == round(sugar / 3, 2)
    assert portions["1/2"] == round(sugar / 2, 2)
    assert portions["1/3"] == 4
    assert portions["1/2"] == 6

    meals = client.get("/api/v1/meals", headers=headers, params={"date": user_local_today("UTC").isoformat()})
    assert meals.json() == []


def test_logging_updates_consumed_and_locks_local_date(client: TestClient) -> None:
    headers = _headers(client)
    today = user_local_today("UTC")
    other = "2024-02-29"

    first = _log(client, headers, sugar_g=6, label="oatmeal", notes="breakfast")
    assert first["local_date"] == today.isoformat()
    assert first["status"] == "logged"
    assert first["notes"] == "breakfast"
    assert first["logged_at"].endswith("Z")

    second = _log(client, headers, sugar_g=2.5, label="berries")
    assert second["local_date"] == today.isoformat()

    locked = _log(
        client,
        headers,
        sugar_g=3,
        label="apple",
        local_date=other,
        photo_ref="photos/apple.jpg",
        notes="small",
    )
    assert locked["local_date"] == other
    assert locked["photo_path_or_url"] == "photos/apple.jpg"
    assert locked["notes"] == "small"

    dashboard = client.get("/api/v1/dashboard", headers=headers).json()
    assert dashboard["date"] == today.isoformat()
    assert dashboard["consumed_g"] == 8.5
    assert dashboard["remaining_g"] == 6.5
    assert [meal["label"] for meal in dashboard["meals"]] == ["oatmeal", "berries"]

    listed = client.get("/api/v1/meals", headers=headers, params={"date": today.isoformat()}).json()
    assert [meal["id"] for meal in listed] == [first["id"], second["id"]]

    past = client.get("/api/v1/meals", headers=headers, params={"date": other}).json()
    assert len(past) == 1
    assert past[0]["local_date"] == other
    assert past[0]["sugar_g"] == 3

    me = client.get("/api/v1/me", headers=headers).json()
    assert me["current_streak"] == 1
    assert me["best_streak"] == 1


def test_analyze_image_is_deterministic_and_hint_wins(client: TestClient) -> None:
    headers = _headers(client)
    files = {"image": ("plate.jpg", b"same-bytes", "image/jpeg")}
    first = client.post("/api/v1/meals/analyze", headers=headers, files=files)
    second = client.post("/api/v1/meals/analyze", headers=headers, files=files)
    assert first.status_code == 200, first.text
    assert first.json()["label"] == second.json()["label"]
    assert first.json()["sugar_g"] == second.json()["sugar_g"]
    assert 0 <= first.json()["confidence"] <= 1

    hinted = client.post(
        "/api/v1/meals/analyze",
        headers=headers,
        files={"image": ("plate.jpg", b"same-bytes", "image/jpeg")},
        data={"hint": "cucumber"},
    )
    assert hinted.json()["label"] == "cucumber"
    assert hinted.json()["sugar_g"] == 1.7
    assert hinted.json()["would_exceed"] is False


def test_streak_increment_break_and_best_preserved(client: TestClient) -> None:
    headers = _headers(client)
    other = _headers(client)
    today = user_local_today("UTC")

    for days_ago, expected in ((1, 1), (2, 2), (3, 3)):
        day = today - timedelta(days=days_ago)
        _log(client, headers, sugar_g=4, label="yogurt", local_date=day.isoformat())
        me = client.get("/api/v1/me", headers=headers).json()
        dashboard = client.get("/api/v1/dashboard", headers=headers).json()
        assert me["current_streak"] == expected
        assert me["best_streak"] == expected
        assert dashboard["current_streak"] == expected
        assert dashboard["best_streak"] == expected
        assert dashboard["consumed_g"] == 0

    _log(client, headers, sugar_g=40, label="cola", local_date=today.isoformat())
    me = client.get("/api/v1/me", headers=headers).json()
    dashboard = client.get("/api/v1/dashboard", headers=headers).json()
    assert me["current_streak"] == 0
    assert me["best_streak"] == 3
    assert dashboard["current_streak"] == 0
    assert dashboard["best_streak"] == 3
    assert dashboard["consumed_g"] == 40
    assert dashboard["remaining_g"] == -25
    assert len(dashboard["meals"]) == 1

    untouched = client.get("/api/v1/me", headers=other).json()
    assert untouched["current_streak"] == 0
    assert untouched["best_streak"] == 0


def test_meals_are_scoped_to_the_current_user(client: TestClient) -> None:
    owner = _headers(client)
    other = _headers(client)
    today = user_local_today("UTC")
    _log(client, owner, sugar_g=4, label="apple", local_date=today.isoformat())
    listed = client.get("/api/v1/meals", headers=other, params={"date": today.isoformat()})
    assert listed.json() == []
    assert client.get("/api/v1/dashboard", headers=other).json()["consumed_g"] == 0


def test_invalid_meal_date_is_rejected(client: TestClient) -> None:
    headers = _headers(client)
    missing = client.get("/api/v1/meals", headers=headers)
    assert missing.status_code == 422
    bad = client.get("/api/v1/meals", headers=headers, params={"date": "2026-13-40"})
    assert bad.status_code == 422
    negative = client.post("/api/v1/meals", headers=headers, json={"sugar_g": -1, "label": "nope"})
    assert negative.status_code == 422
