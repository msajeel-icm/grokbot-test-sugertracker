"""Daily totals, budget math, and streak rules.

A logged local day counts toward a streak when its sugar total is strictly
under the user's daily limit. Days with no logged meals do not count, so a
gap breaks a run and a brand-new account stays at zero. The current streak is
the run ending today, or ending yesterday when today has no meals yet (the day
is still in progress). A logged day that is not under the limit breaks the
current streak. best_streak is the longest run and is kept after a break.
"""

from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import Meal, MealStatus, User


def grams(value: float) -> float:
    return round(float(value), 2)


def user_local_today(timezone_name: str, now: datetime | None = None) -> date:
    moment = now or datetime.now(timezone.utc)
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=timezone.utc)
    try:
        zone = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError:
        zone = ZoneInfo("UTC")
    return moment.astimezone(zone).date()


def remaining_budget_g(limit_g: float, consumed_g: float) -> float:
    return grams(grams(limit_g) - grams(consumed_g))


def meal_would_exceed(sugar_g: float, remaining_g: float) -> bool:
    return grams(sugar_g) > grams(remaining_g)


def _as_date(value: date | datetime | str) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    return date.fromisoformat(str(value)[:10])


def load_daily_totals(db: Session, user_id: int) -> dict[date, float]:
    """Sum sugar for logged meals only, grouped by the locked local date."""
    rows = db.execute(
        select(Meal.local_date, func.sum(Meal.sugar_g))
        .where(Meal.user_id == user_id, Meal.status == MealStatus.logged.value)
        .group_by(Meal.local_date)
    ).all()
    return {_as_date(local_date): grams(float(total or 0)) for local_date, total in rows}


def consumed_on(db: Session, user_id: int, local_date: date) -> float:
    return load_daily_totals(db, user_id).get(local_date, 0.0)


def meals_for_date(db: Session, user_id: int, local_date: date) -> list[Meal]:
    return list(
        db.scalars(
            select(Meal)
            .where(
                Meal.user_id == user_id,
                Meal.local_date == local_date,
                Meal.status == MealStatus.logged.value,
            )
            .order_by(Meal.logged_at.asc(), Meal.id.asc())
        ).all()
    )


def _is_under(totals: dict[date, float], day: date, limit_g: float) -> bool:
    total = totals.get(day)
    if total is None:
        return False
    return grams(total) < grams(limit_g)


def current_and_best_streak(
    totals: dict[date, float],
    limit_g: float,
    today: date,
) -> tuple[int, int]:
    best = 0
    run = 0
    previous: date | None = None
    for day in sorted(totals):
        if (
            _is_under(totals, day, limit_g)
            and previous is not None
            and (day - previous).days == 1
            and _is_under(totals, previous, limit_g)
        ):
            run += 1
        elif _is_under(totals, day, limit_g):
            run = 1
        else:
            run = 0
        if run > best:
            best = run
        previous = day

    if today in totals and not _is_under(totals, today, limit_g):
        return 0, best

    start = today if today in totals else today - timedelta(days=1)
    current = 0
    day = start
    while _is_under(totals, day, limit_g):
        current += 1
        day -= timedelta(days=1)
    return current, best


def streak_summary(db: Session, user: User, today: date | None = None) -> tuple[int, int]:
    day = today if today is not None else user_local_today(user.timezone)
    totals = load_daily_totals(db, user.id)
    return current_and_best_streak(totals, user.daily_sugar_limit_g, day)
