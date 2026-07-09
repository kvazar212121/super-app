from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.user import User
from app.core.config import settings
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, VerifyOtpResponse
from app.schemas.user import UserOut
from app.services.otp_service import OtpService
from app.utils.phone import normalize_phone


class AuthService:

    @staticmethod
    async def register(db: AsyncSession, data: RegisterRequest) -> TokenResponse:
        phone = normalize_phone(data.phone)
        OtpService.consume_verification_token(data.verification_token, phone)

        existing = await db.execute(select(User).where(User.phone == phone))
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Bu telefon raqam allaqachon ro'yxatdan o'tgan",
            )
        user = User(
            name=data.name,
            surname=data.surname,
            phone=phone,
            hashed_password=hash_password(data.password),
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
        return AuthService._build_token_response(user)

    @staticmethod
    async def login(db: AsyncSession, data: LoginRequest) -> TokenResponse:
        phone = normalize_phone(data.phone)

        # Admin panel uchun maxsus login (admin / telefon emas)
        if phone == settings.admin_default_phone or data.phone == settings.admin_default_phone:
            return await AuthService._admin_password_login(db, data)

        # Foydalanuvchini normalize qilingan yoki xom telefon bo'yicha topamiz
        result = await db.execute(
            select(User).where(User.phone.in_([phone, data.phone]))
        )
        user = result.scalars().first()

        # Admin foydalanuvchilar (panelda yaratilgan) — parol bilan kiradi, OTP shart emas
        if user is not None and user.is_admin:
            if not user.is_active or not verify_password(data.password, user.hashed_password):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Telefon raqam yoki parol noto'g'ri",
                )
            return AuthService._build_token_response(user)

        # Oddiy foydalanuvchilar uchun SMS OTP majburiy bo'lishi mumkin
        if settings.require_otp_auth:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Kirish uchun telefon raqamingizga yuborilgan SMS kodini kiriting",
            )

        if not user or not verify_password(data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Telefon raqam yoki parol noto'g'ri",
            )
        return AuthService._build_token_response(user)

    @staticmethod
    async def _admin_password_login(db: AsyncSession, data: LoginRequest) -> TokenResponse:
        result = await db.execute(
            select(User).where(User.phone == settings.admin_default_phone)
        )
        user = result.scalar_one_or_none()
        if not user or not verify_password(data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Admin login yoki parol noto'g'ri",
            )
        return AuthService._build_token_response(user)

    @staticmethod
    async def verify_otp_and_login(
        db: AsyncSession, phone: str, code: str
    ) -> VerifyOtpResponse:
        normalized = OtpService.verify_code(phone, code)
        result = await db.execute(select(User).where(User.phone == normalized))
        user = result.scalar_one_or_none()

        if user:
            tokens = AuthService._build_token_response(user)
            return VerifyOtpResponse(
                phone=normalized,
                user_exists=True,
                access_token=tokens.access_token,
                refresh_token=tokens.refresh_token,
                user=tokens.user,
            )

        verification_token = OtpService.create_verification_token(normalized)
        return VerifyOtpResponse(
            phone=normalized,
            user_exists=False,
            verification_token=verification_token,
        )

    @staticmethod
    async def refresh(db: AsyncSession, refresh_token: str) -> TokenResponse:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Yaroqsiz refresh token",
            )
        user_id = int(payload["sub"])
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Foydalanuvchi topilmadi",
            )
        return AuthService._build_token_response(user)

    @staticmethod
    def _build_token_response(user: User) -> TokenResponse:
        return TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=create_refresh_token(user.id),
            user=UserOut.from_user(user),
        )
