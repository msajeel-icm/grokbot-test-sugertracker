import enum
from datetime import date, datetime, timezone

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    TypeDecorator,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class UtcDateTime(TypeDecorator):
    """Store UTC datetimes. SQLite drops tzinfo, so restore it on read."""

    impl = DateTime(timezone=True)
    cache_ok = True

    def process_bind_param(self, value: datetime | None, _dialect) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)

    def process_result_value(self, value: datetime | None, _dialect) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    daily_sugar_limit_g: Mapped[float] = mapped_column(Float, nullable=False, default=15.0)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False, default="UTC")
    created_at: Mapped[datetime] = mapped_column(UtcDateTime(), nullable=False, default=utcnow)


class MealStatus(enum.StrEnum):
    logged = "logged"
    discarded = "discarded"


class Meal(Base):
    __tablename__ = "meals"
    __table_args__ = (
        CheckConstraint(
            "status IN ('logged', 'discarded')",
            name="ck_meals_status",
        ),
        Index("ix_meals_user_local_date", "user_id", "local_date"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    photo_path_or_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    label: Mapped[str] = mapped_column(String(200), nullable=False)
    sugar_g: Mapped[float] = mapped_column(Float, nullable=False)
    kcal: Mapped[float] = mapped_column(Float, nullable=False, default=0.0, server_default="0")
    logged_at: Mapped[datetime] = mapped_column(UtcDateTime(), nullable=False, default=utcnow)
    local_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default=MealStatus.logged.value)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
