from datetime import date, datetime, timedelta, timezone

import pytest

from app.tracking import (
    current_and_best_streak,
    meal_would_exceed,
    remaining_budget_g,
    user_local_today,
)


def test_remaining_budget_and_would_exceed() -> None:
    assert remaining_budget_g(15, 0) == 15
    assert remaining_budget_g(15, 10) == 5
    assert remaining_budget_g(15, 40) == -25
    assert meal_would_exceed(12, 15) is False
    assert meal_would_exceed(12, 5) is True
    assert meal_would_exceed(5, 5) is False
    assert meal_would_exceed(5.01, 5) is True


def test_local_date_uses_user_timezone() -> None:
    now = datetime(2026, 1, 1, 3, 30, tzinfo=timezone.utc)
    assert user_local_today("UTC", now) == date(2026, 1, 1)
    assert user_local_today("America/New_York", now) == date(2025, 12, 31)
    assert user_local_today("Asia/Tokyo", now) == date(2026, 1, 1)
    assert user_local_today("Not/AZone", now) == date(2026, 1, 1)


def test_streak_increments_across_consecutive_under_limit_days() -> None:
    today = date(2026, 9, 22)
    totals = {
        today - timedelta(days=3): 4,
        today - timedelta(days=2): 4,
        today - timedelta(days=1): 4,
    }
    current, best = current_and_best_streak(totals, 15, today)
    assert current == 3
    assert best == 3


def test_over_limit_day_breaks_current_streak_and_keeps_best() -> None:
    today = date(2026, 9, 22)
    totals = {
        today - timedelta(days=3): 4,
        today - timedelta(days=2): 4,
        today - timedelta(days=1): 4,
        today: 40,
    }
    current, best = current_and_best_streak(totals, 15, today)
    assert current == 0
    assert best == 3


def test_day_at_the_limit_does_not_count() -> None:
    today = date(2026, 9, 22)
    totals = {
        today - timedelta(days=2): 4,
        today - timedelta(days=1): 15,
    }
    current, best = current_and_best_streak(totals, 15, today)
    assert current == 0
    assert best == 1


def test_gap_breaks_streak_and_old_best_is_preserved() -> None:
    today = date(2026, 9, 22)
    totals = {
        date(2026, 9, 1): 1,
        date(2026, 9, 2): 1,
        date(2026, 9, 3): 1,
        date(2026, 9, 4): 1,
        date(2026, 9, 5): 30,
        date(2026, 9, 19): 1,
        date(2026, 9, 21): 1,
    }
    current, best = current_and_best_streak(totals, 15, today)
    assert current == 1
    assert best == 4


def test_no_meals_has_no_streak() -> None:
    current, best = current_and_best_streak({}, 15, date(2026, 9, 22))
    assert current == 0
    assert best == 0


def test_today_under_limit_extends_the_run() -> None:
    today = date(2026, 9, 22)
    totals = {today - timedelta(days=1): 4, today: 4}
    current, best = current_and_best_streak(totals, 15, today)
    assert current == 2
    assert best == 2


@pytest.mark.parametrize(
    ("amount", "third", "half"),
    [(12, 4, 6), (10, 3.33, 5), (1, 0.33, 0.5), (160, 53.33, 80), (165, 55, 82.5)],
)
def test_fraction_constants_match_budget_scale(amount: float, third: float, half: float) -> None:
    # Portion math is shared by sugar and kcal. The sugar limit still uses sugar only.
    from app.analyze import fraction_kcals, fraction_sugars

    for portions in (fraction_sugars(amount), fraction_kcals(amount)):
        assert portions["1/3"] == pytest.approx(third, abs=0.01)
        assert portions["1/2"] == pytest.approx(half, abs=0.01)
        assert portions["1/3"] == pytest.approx(amount / 3, abs=0.01)
        assert portions["1/2"] == pytest.approx(amount / 2, abs=0.01)
