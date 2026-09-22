from datetime import datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models import User


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


def user_to_out(user: User) -> UserOut:
    # Streaks are placeholders until streak logic is implemented.
    return UserOut(
        id=user.id,
        email=user.email,
        daily_sugar_limit_g=user.daily_sugar_limit_g,
        timezone=user.timezone,
        created_at=user.created_at,
        current_streak=0,
        best_streak=0,
    )
