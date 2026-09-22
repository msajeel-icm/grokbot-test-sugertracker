from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.deps import DbSession
from app.models import User
from app.schemas import AuthResponse, LoginRequest, RegisterRequest, user_to_out
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _auth_response(user: User, db: DbSession) -> AuthResponse:
    return AuthResponse(
        access_token=create_access_token(user.id),
        token_type="bearer",
        user=user_to_out(user, db),
    )


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: DbSession) -> AuthResponse:
    email = body.email.lower()
    existing = db.scalar(select(User).where(User.email == email))
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")
    user = User(email=email, password_hash=hash_password(body.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return _auth_response(user, db)


@router.post("/login", response_model=AuthResponse)
def login(body: LoginRequest, db: DbSession) -> AuthResponse:
    email = body.email.lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    return _auth_response(user, db)
