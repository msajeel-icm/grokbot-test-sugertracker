from pathlib import Path

from sqlalchemy import create_engine, text

from app.database import ensure_meal_kcal_column


def test_legacy_sqlite_gains_a_kcal_column(tmp_path: Path) -> None:
    legacy = create_engine(f"sqlite:///{tmp_path / 'legacy.db'}")
    with legacy.begin() as connection:
        connection.execute(text("CREATE TABLE meals (id INTEGER PRIMARY KEY, sugar_g FLOAT NOT NULL)"))

    ensure_meal_kcal_column(legacy)
    ensure_meal_kcal_column(legacy)

    with legacy.connect() as connection:
        names = {row[1] for row in connection.execute(text("PRAGMA table_info(meals)"))}
    assert "kcal" in names
