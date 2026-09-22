from datetime import date, datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy.orm import Session

from app.models import User
from app.tracking import streak_summary


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    daily_sugar_limit_g: float
    timezone: str
    created_at: datetime
    current_streak: int = 0
    best_streak: int = 0


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserUpdate(BaseModel):
    daily_sugar_limit_g: float | None = Field(default=None, ge=0, le=1000)
    timezone: str | None = None

    @field_validator("timezone")
    @classmethod
    def timezone_must_be_iana(cls, value: str | None) -> str | None:
        if value is None:
            return value
        try:
            ZoneInfo(value)
        except ZoneInfoNotFoundError as exc:
            raise ValueError("Unknown IANA timezone") from exc
        return value


def user_to_out(user: User, db: Session) -> UserOut:
    current_streak, best_streak = streak_summary(db, user)
    return UserOut(
        id=user.id,
        email=user.email,
        daily_sugar_limit_g=user.daily_sugar_limit_g,
        timezone=user.timezone,
        created_at=user.created_at,
        current_streak=current_streak,
        best_streak=best_streak,
    )


class MealCreate(BaseModel):
    sugar_g: float = Field(ge=0, le=1000)
    label: str = Field(min_length=1, max_length=200)
    local_date: date | None = None
    photo_ref: str | None = Field(default=None, max_length=1024)
    notes: str | None = Field(default=None, max_length=2000)

    @field_validator("label", mode="before")
    @classmethod
    def strip_label(cls, value: object) -> object:
        if isinstance(value, str):
            return value.strip()
        return value

    @field_validator("notes", "photo_ref", mode="before")
    @classmethod
    def blank_optional_to_none(cls, value: object) -> object:
        if value is None or not isinstance(value, str):
            return value
        stripped = value.strip()
        return stripped or None


class MealOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    label: str
    sugar_g: float
    logged_at: datetime
    local_date: date
    status: str
    notes: str | None = None
    photo_path_or_url: str | None = None


class AlternativeOut(BaseModel):
    label: str
    sugar_g: float


class SuggestionOut(BaseModel):
    fractions: list[str]
    fraction_sugar_g: dict[str, float]
    alternatives: list[AlternativeOut]


class AnalyzeOut(BaseModel):
    sugar_g: float
    label: str
    confidence: float
    remaining_budget_g: float
    would_exceed: bool
    suggestion: SuggestionOut


class DashboardOut(BaseModel):
    date: date
    limit_g: float
    consumed_g: float
    remaining_g: float
    meals: list[MealOut]
    current_streak: int
    best_streak: int
