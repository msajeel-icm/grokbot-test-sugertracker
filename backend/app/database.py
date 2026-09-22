from collections.abc import Generator

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


def _engine_options(url: str) -> dict:
    # SQLite needs this flag so FastAPI can use the connection across threads.
    # Other drivers (Postgres) take no extra connect args.
    if url.startswith("sqlite"):
        return {"connect_args": {"check_same_thread": False}}
    return {}


settings = get_settings()
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    **_engine_options(settings.database_url),
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def ensure_meal_kcal_column(bind=None) -> None:
    """Add meals.kcal on databases created before calories were stored.

    ``create_all`` does not alter existing tables. Sugar budget columns are unchanged.
    """
    target = engine if bind is None else bind
    inspector = inspect(target)
    if not inspector.has_table("meals"):
        return
    names = {column["name"] for column in inspector.get_columns("meals")}
    if "kcal" in names:
        return
    with target.begin() as connection:
        connection.execute(text("ALTER TABLE meals ADD COLUMN kcal FLOAT NOT NULL DEFAULT 0"))


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
