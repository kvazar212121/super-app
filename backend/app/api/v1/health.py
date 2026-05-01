from fastapi import APIRouter

router = APIRouter()


@router.get("/health", summary="Sog‘liq tekshiruvi")
async def health():
    return {"status": "ok", "service": "super-app-api"}


@router.get("/ready", summary="Tayyorlik (DB/Redis keyin ulanadi)")
async def ready():
    return {"ready": True, "db": "not_configured", "redis": "not_configured"}
