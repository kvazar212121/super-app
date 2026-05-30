from fastapi import APIRouter, Depends, UploadFile, File

from app.api.dependencies import get_current_user
from app.models.user import User
from app.services.upload_service import UploadService
from app.schemas.common import UrlResponse

router = APIRouter(prefix="/upload", tags=["upload"])


@router.post("/avatar", response_model=UrlResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Foydalanuvchi avatarini yuklash."""
    url = await UploadService.upload_avatar(file)
    return UrlResponse(url=url)


@router.post("/cover", response_model=UrlResponse)
async def upload_cover(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Provayder muqova rasmini yuklash."""
    url = await UploadService.upload_cover(file)
    return UrlResponse(url=url)
