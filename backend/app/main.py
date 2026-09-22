from contextlib import asynccontextmanager

from fastapi import FastAPI

from app import __version__
from app.database import Base, engine
from app.routers import auth, me, meals
from app.seed import seed_demo_user


@asynccontextmanager
async def lifespan(_app: FastAPI):
    Base.metadata.create_all(bind=engine)
    seed_demo_user()
    yield


app = FastAPI(
    title="Sugar Tracker API",
    version=__version__,
    description="Accounts, meals, stub food analysis, dashboard, and streaks.",
    lifespan=lifespan,
)
app.include_router(auth.router)
app.include_router(me.router)
app.include_router(meals.router)


def health() -> dict[str, str]:
    return {"status": "ok"}


app.add_api_route("/health", health, methods=["GET"], tags=["health"])
app.add_api_route("/api/v1/health", health, methods=["GET"], tags=["health"])
