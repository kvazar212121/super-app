from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.services.auth_service import AuthService
from app.services.otp_service import OtpService
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    RefreshRequest,
    TokenResponse,
    SendOtpRequest,
    SendOtpResponse,
    VerifyOtpRequest,
    VerifyOtpResponse,
)
from app.models.user import User
from app.core.config import settings
from app.core.limiter import limiter

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/otp/send", response_model=SendOtpResponse)
@limiter.limit("5/minute")
async def send_otp(request: Request, data: SendOtpRequest):
    """Telefon raqamiga SMS tasdiqlash kodi yuborish."""
    return await OtpService.send_code(data.phone, data.purpose)


@router.post("/otp/verify", response_model=VerifyOtpResponse)
@limiter.limit("15/minute")
async def verify_otp(
    request: Request,
    data: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    """SMS kodni tasdiqlash. Mavjud user bo'lsa — login, yo'q bo'lsa — verification_token."""
    return await AuthService.verify_otp_and_login(db, data.phone, data.code)


@router.post("/register", response_model=TokenResponse)
@limiter.limit("10/minute")
async def register(request: Request, data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    return await AuthService.register(db, data)


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
async def login(request: Request, data: LoginRequest, db: AsyncSession = Depends(get_db)):
    # Debug mode: faqat development
    if settings.bypass_auth:
        result = await db.execute(
            select(User).where(User.phone == data.phone).limit(1)
        )
        user = result.scalar_one_or_none()
        if not user:
            user = User(
                name="Admin",
                surname="Test",
                phone=data.phone or "admin",
                hashed_password="debug",
                is_admin=True,
                is_active=True,
            )
            db.add(user)
            await db.flush()
            await db.refresh(user)
        return AuthService._build_token_response(user)

    return await AuthService.login(db, data)


@router.get("/debug-login", response_model=TokenResponse)
async def debug_login(
    phone: str = "admin",
    db: AsyncSession = Depends(get_db),
):
    """Debug login — faqat bypass_auth yoqilganda."""
    if not settings.bypass_auth:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Debug mode o'chiq")

    result = await db.execute(
        select(User).where(User.phone == phone).limit(1)
    )
    user = result.scalar_one_or_none()
    if not user:
        user = User(
            name="Admin",
            surname="Test",
            phone=phone,
            hashed_password="debug",
            is_admin=True,
            is_active=True,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
    return AuthService._build_token_response(user)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    return await AuthService.refresh(db, data.refresh_token)
