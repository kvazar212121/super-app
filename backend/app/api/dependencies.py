from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import noload, selectinload

from app.db.session import get_db
from app.core.security import decode_token
from app.core.config import settings
from app.models.user import User

security = HTTPBearer(auto_error=False)

# Auth hot-path: User'ning 16 ta selectin relationshipини yuklamaymiz (har so'rovда ortiqcha).
# Faqat `providers` yuklanadi (to_dict/is_provider uchun) — u ham bolalarisiz (noload).
_AUTH_LOAD_OPTS = (noload("*"), selectinload(User.providers).noload("*"))


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Foydalanuvchini olish — debug mode da bypass."""
    # Development: bypass_auth=True bo'lsa, birinchi adminni qaytarish
    if settings.bypass_auth:
        result = await db.execute(
            select(User).options(*_AUTH_LOAD_OPTS).where(User.is_admin == True).limit(1)
        )
        admin = result.scalar_one_or_none()
        if admin:
            return admin

    # Production: token tekshirish
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token talab qilinadi",
        )

    payload = decode_token(credentials.credentials)
    if not payload or payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yaroqsiz yoki muddati o'tgan token",
        )
    user_id = int(payload["sub"])
    result = await db.execute(
        select(User).options(*_AUTH_LOAD_OPTS).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Foydalanuvchi topilmadi",
        )
    return user