import logging

import httpx
from fastapi import HTTPException, status

from app.core.config import settings

logger = logging.getLogger(__name__)


class SmsService:
    @staticmethod
    def _phone_digits(phone: str) -> str:
        return phone.lstrip("+")

    @staticmethod
    async def send_otp(phone: str, code: str) -> None:
        message = settings.sms_otp_template.format(code=code)

        if settings.sms_provider == "devsms" and settings.devsms_token:
            await SmsService._send_devsms(phone, message)
            return

        if settings.sms_provider == "eskiz" and settings.eskiz_email and settings.eskiz_password:
            await SmsService._send_eskiz(phone, message)
            return

        logger.info("SMS OTP [%s]: %s", phone, code)

    @staticmethod
    async def _send_devsms(phone: str, message: str) -> None:
        """devsms.uz REST API — https://devsms.uz/api/send_sms.php"""
        url = f"{settings.devsms_base_url.rstrip('/')}/send_sms.php"
        payload: dict = {
            "phone": SmsService._phone_digits(phone),
            "message": message,
            "from": settings.devsms_sender,
        }
        if settings.devsms_callback_url:
            payload["callback_url"] = settings.devsms_callback_url

        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.post(
                url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {settings.devsms_token}",
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )

        try:
            data = resp.json()
        except Exception:
            logger.error("devsms javob JSON emas: status=%s body=%s", resp.status_code, resp.text[:500])
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="SMS xizmati vaqtincha ishlamayapti",
            )

        if resp.status_code >= 400 or not data.get("success"):
            err = data.get("message") or data.get("error") or "SMS yuborib bo'lmadi"
            logger.error("devsms xato: %s", data)
            if "модерацию" in err or "moderatsiya" in err.lower():
                err = (
                    "SMS matni moderatsiyadan o'tmagan. devsms.uz kabinetida "
                    "shu matnni shablon sifatida yuboring: "
                    f"«{settings.sms_otp_template}»"
                )
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=err,
            )

        logger.info(
            "devsms yuborildi phone=%s sms_id=%s balance=%s",
            phone,
            (data.get("data") or {}).get("sms_id"),
            (data.get("data") or {}).get("balance"),
        )

    @staticmethod
    async def _send_eskiz(phone: str, message: str) -> None:
        """Eskiz.uz SMS API (token kerak)."""
        async with httpx.AsyncClient(timeout=15) as client:
            token_resp = await client.post(
                "https://notify.eskiz.uz/api/auth/login",
                data={
                    "email": settings.eskiz_email,
                    "password": settings.eskiz_password,
                },
            )
            token_resp.raise_for_status()
            token = token_resp.json().get("data", {}).get("token")
            if not token:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail="SMS xizmati sozlanmagan",
                )

            send_resp = await client.post(
                "https://notify.eskiz.uz/api/message/sms/send",
                headers={"Authorization": f"Bearer {token}"},
                data={
                    "mobile_phone": SmsService._phone_digits(phone),
                    "message": message,
                    "from": settings.eskiz_sender or "4546",
                },
            )
            send_resp.raise_for_status()
