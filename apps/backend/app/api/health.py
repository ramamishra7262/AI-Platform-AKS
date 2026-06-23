from datetime import datetime
from fastapi import APIRouter
from app.core.config import get_settings
from app.models.schemas import HealthStatus

router = APIRouter(tags=["health"])
settings = get_settings()


@router.get("/healthz", response_model=HealthStatus)
def health():
    return HealthStatus(status="ok", version=settings.app_version, environment=settings.environment,
                        checks={"api": "ok"})


@router.get("/readyz")
def ready():
    return {"status": "ready"}
