import logging
import random
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from jose import jwt, JWTError

from app.core.config import settings
from app.core.redis_client import get_redis
from app.services.sms_service import SmsService
from app.utils.phone import normalize_phone, is_valid_uz_phone

logger = logging.getLogger(__name__)


class OtpService:
    @staticmethod
    def _otp_key(phone: str) -> str:
        return f"otp:{phone}"

    @staticmethod
    def _cooldown_key(phone: str) -> str:
        return f"otp:cooldown:{phone}"

    @staticmethod
    def _attempts_key(phone: str) -> str:
        return f"otp:attempts:{phone}"

    @staticmethod
    async def send_code(phone: str, purpose: str = "auth") -> dict:
        normalized = normalize_phone(phone)
        if not is_valid_uz_phone(normalized):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Telefon raqam noto'g'ri formatda",
            )

        redis = get_redis()
        if redis.exists(OtpService._cooldown_key(normalized)):
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="SMS yuborish uchun biroz kuting (60 soniya)",
            )

        code = "".join(str(random.randint(0, 9)) for _ in range(settings.otp_length))

        await SmsService.send_otp(normalized, code)

        pipe = redis.pipeline()
        pipe.setex(OtpService._otp_key(normalized), settings.otp_expire_seconds, code)
        pipe.setex(OtpService._cooldown_key(normalized), 60, "1")
        pipe.delete(OtpService._attempts_key(normalized))
        pipe.execute()

        result = {
            "message": "Tasdiqlash kodi yuborildi",
            "phone": normalized,
            "expires_in": settings.otp_expire_seconds,
            "purpose": purpose,
        }
        if settings.otp_dev_expose:
            result["dev_code"] = code
        return result

    @staticmethod
    def verify_code(phone: str, code: str) -> str:
        normalized = normalize_phone(phone)
        if not is_valid_uz_phone(normalized):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Telefon raqam noto'g'ri",
            )

        redis = get_redis()
        attempts_key = OtpService._attempts_key(normalized)
        attempts = int(redis.get(attempts_key) or 0)
        if attempts >= settings.otp_max_attempts:
            redis.delete(OtpService._otp_key(normalized))
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Juda ko'p noto'g'ri urinish. Qaytadan kod so'rang",
            )

        stored = redis.get(OtpService._otp_key(normalized))
        if not stored or stored != code.strip():
            redis.incr(attempts_key)
            redis.expire(attempts_key, settings.otp_expire_seconds)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tasdiqlash kodi noto'g'ri",
            )

        redis.delete(OtpService._otp_key(normalized))
        redis.delete(attempts_key)
        return normalized

    @staticmethod
    def create_verification_token(phone: str) -> str:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.otp_verification_token_minutes
        )
        payload = {
            "phone": phone,
            "type": "phone_verification",
            "exp": expire,
            "jti": secrets.token_hex(8),
        }
        return jwt.encode(payload, settings.secret_key, algorithm="HS256")

    @staticmethod
    def consume_verification_token(token: str, phone: str) -> None:
        normalized = normalize_phone(phone)
        try:
            payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Telefon tasdiqlanmagan. Qaytadan kod so'rang",
            )

        if payload.get("type") != "phone_verification":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Noto'g'ri tasdiqlash tokeni",
            )
        if normalize_phone(payload.get("phone", "")) != normalized:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Telefon raqami mos kelmayapti",
            )
