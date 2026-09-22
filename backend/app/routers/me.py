from fastapi import APIRouter

from app.deps import CurrentUser, DbSession
from app.schemas import UserOut, UserUpdate, user_to_out

router = APIRouter(prefix="/api/v1", tags=["me"])


@router.get("/me", response_model=UserOut)
def get_me(current_user: CurrentUser, db: DbSession) -> UserOut:
    return user_to_out(current_user, db)


@router.patch("/me", response_model=UserOut)
def update_me(body: UserUpdate, current_user: CurrentUser, db: DbSession) -> UserOut:
    updates = body.model_dump(exclude_unset=True)
    if "daily_sugar_limit_g" in updates and updates["daily_sugar_limit_g"] is not None:
        current_user.daily_sugar_limit_g = updates["daily_sugar_limit_g"]
    if "timezone" in updates and updates["timezone"] is not None:
        current_user.timezone = updates["timezone"]
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return user_to_out(current_user, db)
