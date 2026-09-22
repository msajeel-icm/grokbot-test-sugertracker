import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import SessionLocal
from app.models import User
from app.security import hash_password

logger = logging.getLogger(__name__)


def seed_demo_user(db: Session | None = None) -> None:
    """Create the demo user when it does not already exist."""
    settings = get_settings()
    owns_session = db is None
    if db is None:
        db = SessionLocal()
    try:
        email = settings.demo_email.lower()
        existing = db.scalar(select(User).where(User.email == email))
        if existing is not None:
            return
        user = User(
            email=email,
            password_hash=hash_password(settings.demo_password),
            daily_sugar_limit_g=settings.demo_daily_sugar_limit_g,
            timezone=settings.demo_timezone,
        )
        db.add(user)
        db.commit()
        logger.info("Seeded demo user %s", email)
    finally:
        if owns_session:
            db.close()


def main() -> None:
    from app.database import Base, engine

    Base.metadata.create_all(bind=engine)
    seed_demo_user()


if __name__ == "__main__":
    main()
