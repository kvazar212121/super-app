from fastapi import APIRouter, Depends, UploadFile, File
from starlette.requests import Request

from app.api.dependencies import get_current_user
from app.core.limiter import limiter
from app.models.user import User
from app.services.upload_service import UploadService
from app.schemas.common import UrlResponse

router = APIRouter(prefix="/upload", tags=["upload"])


@router.post("/avatar", response_model=UrlResponse)
@limiter.limit("20/minute")
async def upload_avatar(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Foydalanuvchi avatarini yuklash."""
    url = await UploadService.upload_avatar(file)
    return UrlResponse(url=url)


@router.post("/cover", response_model=UrlResponse)
@limiter.limit("20/minute")
async def upload_cover(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Provayder muqova rasmini yuklash."""
    url = await UploadService.upload_cover(file)
    return UrlResponse(url=url)
