import json
from dataclasses import dataclass
from datetime import date
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, Request, status

from app.analyze import (
    FRACTION_LABELS,
    estimate_food,
    fraction_kcals,
    fraction_sugars,
    low_sugar_alternatives,
)
from app.deps import CurrentUser, DbSession
from app.models import Meal, MealStatus, utcnow
from app.schemas import (
    AlternativeOut,
    AnalyzeOut,
    DashboardOut,
    MealCreate,
    MealOut,
    SuggestionOut,
)
from app.tracking import (
    consumed_kcal_on,
    consumed_on,
    meal_would_exceed,
    meals_for_date,
    remaining_budget_g,
    streak_summary,
    user_local_today,
)

router = APIRouter(prefix="/api/v1")

MAX_IMAGE_BYTES = 8 * 1024 * 1024

_ANALYZE_OPENAPI = {
    "requestBody": {
        "content": {
            "application/json": {
                "schema": {
                    "type": "object",
                    "properties": {
                        "hint": {
                            "type": "string",
                            "description": "Optional food hint, for example 'cookie'.",
                        }
                    },
                }
            },
            "multipart/form-data": {
                "schema": {
                    "type": "object",
                    "properties": {
                        "hint": {"type": "string"},
                        "image": {"type": "string", "format": "binary"},
                    },
                }
            },
        }
    }
}


@dataclass(frozen=True)
class _AnalyzeRequest:
    hint: str | None
    image_bytes: bytes | None


def _clean_hint(value: object) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="hint must be a string")
    text = value.strip()
    if not text:
        return None
    if len(text) > 200:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="hint is too long")
    return text


async def _read_analyze_request(request: Request) -> _AnalyzeRequest:
    content_type = request.headers.get("content-type", "")
    if "multipart/form-data" in content_type:
        form = await request.form()
        hint = _clean_hint(form.get("hint")) if form.get("hint") is not None else None
        upload = form.get("image")
        if upload is None:
            upload = form.get("file")
        image_bytes: bytes | None = None
        if upload is not None and hasattr(upload, "read"):
            image_bytes = await upload.read()
            if len(image_bytes) > MAX_IMAGE_BYTES:
                raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Image is too large")
            if not image_bytes:
                image_bytes = None
        return _AnalyzeRequest(hint=hint, image_bytes=image_bytes)

    body = await request.body()
    if not body:
        return _AnalyzeRequest(hint=None, image_bytes=None)
    if "application/json" not in content_type and "text/json" not in content_type:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Use JSON or multipart form data",
        )
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid JSON") from exc
    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="JSON body must be an object",
        )
    return _AnalyzeRequest(hint=_clean_hint(payload.get("hint")), image_bytes=None)


@router.post(
    "/meals/analyze",
    response_model=AnalyzeOut,
    tags=["meals"],
    openapi_extra=_ANALYZE_OPENAPI,
    summary="Stub-estimate sugar and calories for a meal without logging it",
)
async def analyze_meal(request: Request, current_user: CurrentUser, db: DbSession) -> AnalyzeOut:
    """Estimate sugar and calories from an optional image and/or hint.

    This is a local catalog stub. The same image bytes always pick the same
    food. A matching hint wins over the image hash. Nothing is written until
    `POST /meals`. ``would_exceed`` and ``remaining_budget_g`` use sugar only.
    """
    payload = await _read_analyze_request(request)
    estimate = estimate_food(payload.hint, payload.image_bytes)
    today = user_local_today(current_user.timezone)
    consumed = consumed_on(db, current_user.id, today)
    remaining = remaining_budget_g(current_user.daily_sugar_limit_g, consumed)
    alternatives = [
        AlternativeOut(label=label, sugar_g=sugar, kcal=kcal)
        for label, sugar, kcal in low_sugar_alternatives(estimate.label)
    ]
    return AnalyzeOut(
        sugar_g=estimate.sugar_g,
        kcal=estimate.kcal,
        label=estimate.label,
        confidence=estimate.confidence,
        remaining_budget_g=remaining,
        would_exceed=meal_would_exceed(estimate.sugar_g, remaining),
        suggestion=SuggestionOut(
            fractions=list(FRACTION_LABELS),
            fraction_sugar_g=fraction_sugars(estimate.sugar_g),
            fraction_kcal=fraction_kcals(estimate.kcal),
            alternatives=alternatives,
        ),
    )


@router.post("/meals", response_model=MealOut, status_code=status.HTTP_201_CREATED, tags=["meals"])
def log_meal(body: MealCreate, current_user: CurrentUser, db: DbSession) -> Meal:
    """Confirm a meal. Analyze does not call this."""
    local_date = body.local_date if body.local_date is not None else user_local_today(current_user.timezone)
    meal = Meal(
        user_id=current_user.id,
        photo_path_or_url=body.photo_ref,
        label=body.label,
        sugar_g=body.sugar_g,
        kcal=body.kcal,
        logged_at=utcnow(),
        local_date=local_date,
        status=MealStatus.logged.value,
        notes=body.notes,
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)
    return meal


@router.get("/meals", response_model=list[MealOut], tags=["meals"])
def list_meals(
    current_user: CurrentUser,
    db: DbSession,
    date: Annotated[date, Query(description="Local calendar date, YYYY-MM-DD")],
) -> list[Meal]:
    return meals_for_date(db, current_user.id, date)


@router.get("/dashboard", response_model=DashboardOut, tags=["dashboard"])
def get_dashboard(current_user: CurrentUser, db: DbSession) -> DashboardOut:
    today = user_local_today(current_user.timezone)
    consumed = consumed_on(db, current_user.id, today)
    limit_g = round(float(current_user.daily_sugar_limit_g), 2)
    current_streak, best_streak = streak_summary(db, current_user, today=today)
    return DashboardOut(
        date=today,
        limit_g=limit_g,
        consumed_g=consumed,
        remaining_g=remaining_budget_g(limit_g, consumed),
        consumed_kcal=consumed_kcal_on(db, current_user.id, today),
        meals=[MealOut.model_validate(meal) for meal in meals_for_date(db, current_user.id, today)],
        current_streak=current_streak,
        best_streak=best_streak,
    )
