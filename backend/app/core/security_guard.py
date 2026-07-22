"""Production xavfsizlik guard'i.

`environment=production` bo'lgan\u0434\u0430 xavfli DEFAULT qiymatlar (o'zgartirilmagan
secret_key, ochiq CORS, standart admin paroli, va h.k.) bilan ilova ishga
tushmasligini ta'minlaydi. Development'\u0434\u0430 hech narsa\u0433\u0430 xalaqit bermaydi —
localда o'zgartirishsiz ishlayveradi.

Bu modul DB/tarmoq\u0433\u0430 bog'liq emas — sof funksiya, oson test qilinadi.
"""
from __future__ import annotations

# config.py da e'lon qilingan xavfli default qiymatlar. Production'да
# bulardan biri o'zgarmagan bo'lsa — bu jiddiy xavfsizlik teshigi.
DEFAULT_SECRET_KEY = "super-app-secret-key-change-in-prod"
DEFAULT_ADMIN_PASSWORD = "admin123"


class InsecureProductionConfig(RuntimeError):
    """Production'да xavfli konfiguratsiya aniqlanganда ko'tariladi."""


def check_production_config(settings) -> list[str]:
    """Xavfli sozlamalar ro'yxatini qaytaradi (production uchun).

    Development'да BO'SH ro'yxat qaytadi (tekshiruv o'tkazib yuboriladi).
    Bu funksiya faqat muammolar ro'yxatini tuzadi — xato ko'tarmaydi;
    `enforce_production_config` qaror qabul qiladi.
    """
    env = (getattr(settings, "environment", "development") or "").strip().lower()
    is_prod = env in ("production", "prod")
    if not is_prod:
        return []

    problems: list[str] = []

    if settings.secret_key == DEFAULT_SECRET_KEY or not settings.secret_key:
        problems.append(
            "SECRET_KEY default/bo'sh qiymatда — JWT token'lar soxtalashtirilishi "
            "mumkin. .env да kuchli SECRET_KEY o'rnating."
        )

    if getattr(settings, "cors_allow_all", False):
        problems.append(
            "CORS_ALLOW_ALL=True — istalgan domen API'ga so'rov yubora oladi. "
            "Production'да False qiling va CORS_ORIGINS ro'yxatини bering."
        )

    if getattr(settings, "admin_default_password", "") == DEFAULT_ADMIN_PASSWORD:
        problems.append(
            "ADMIN_DEFAULT_PASSWORD standart 'admin123' — o'zgartiring."
        )

    if getattr(settings, "bypass_auth", False):
        problems.append(
            "BYPASS_AUTH=True — autentifikatsiya o'chirilgan. Production'да False bo'lsin."
        )

    if getattr(settings, "otp_dev_expose", False):
        problems.append(
            "OTP_DEV_EXPOSE=True — SMS kodи API javobида ochiq ko'rinadi. False qiling."
        )

    return problems


def enforce_production_config(settings) -> None:
    """Production'да xavfli sozlama bo'lsa ilovani to'xtatadi (RuntimeError).

    Development'да hech narsa qilmaydi.
    """
    problems = check_production_config(settings)
    if problems:
        bullet = "\n  - ".join(problems)
        raise InsecureProductionConfig(
            "Production konfiguratsiyasi xavfsiz emas, ilova to'xtatildi:\n  - "
            + bullet
        )
