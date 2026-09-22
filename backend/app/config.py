from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Runtime settings. Override with environment variables or backend/.env.

    ``database_url`` is the only change required to point the app at Postgres
    later (for example ``postgresql+psycopg://user:pass@localhost:5432/sugar``).
    """

    model_config = SettingsConfigDict(
        env_file=str(BACKEND_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    database_url: str = "sqlite:///./sugar.db"
    jwt_secret: str = "dev-only-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7

    demo_email: str = "demo@sugar.app"
    demo_password: str = "demo1234"
    demo_daily_sugar_limit_g: float = 15.0
    demo_timezone: str = "UTC"

    @field_validator("database_url")
    @classmethod
    def resolve_sqlite_path(cls, value: str) -> str:
        prefix = "sqlite:///"
        if not value.startswith(prefix):
            return value
        path = value[len(prefix) :]
        if path.startswith(":memory:") or path.startswith("/"):
            return value
        resolved = (BACKEND_DIR / path).resolve()
        return f"sqlite:///{resolved}"


@lru_cache
def get_settings() -> Settings:
    return Settings()
