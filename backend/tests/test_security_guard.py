"""Production xavfsizlik guard'i testi (DB'siz, sof)."""
import os
os.environ.setdefault('DATABASE_URL', 'postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL', 'postgresql+psycopg2://u:p@localhost/db')

from app.core.security_guard import (
    check_production_config,
    enforce_production_config,
    InsecureProductionConfig,
    DEFAULT_SECRET_KEY,
    DEFAULT_ADMIN_PASSWORD,
)


class FakeSettings:
    """Test uchun soxta settings (config.py struktrasiga mos)."""
    def __init__(self, **kw):
        self.environment = kw.get("environment", "development")
        self.secret_key = kw.get("secret_key", DEFAULT_SECRET_KEY)
        self.cors_allow_all = kw.get("cors_allow_all", True)
        self.admin_default_password = kw.get("admin_default_password", DEFAULT_ADMIN_PASSWORD)
        self.bypass_auth = kw.get("bypass_auth", False)
        self.otp_dev_expose = kw.get("otp_dev_expose", False)


def main():
    # ===== 1. DEV + default qiymatlar -> muammo YO'Q (localда ishlayveradi) =====
    dev = FakeSettings(environment="development")
    problems = check_production_config(dev)
    assert problems == [], f"FAIL: devда guard ishga tushdi: {problems}"
    enforce_production_config(dev)  # xato ko'tarmasligi kerak
    print("OK 1: development + default -> guard xalaqit bermadi (local ishlaydi)")

    # ===== 2. PROD + default secret_key -> XATO =====
    prod_default = FakeSettings(environment="production")
    problems = check_production_config(prod_default)
    assert any("SECRET_KEY" in p for p in problems), f"FAIL: secret_key aniqlanmadi: {problems}"
    assert any("CORS" in p for p in problems), "FAIL: CORS aniqlanmadi"
    assert any("admin123" in p or "ADMIN" in p for p in problems), "FAIL: admin parol aniqlanmadi"
    print(f"OK 2: production + default -> {len(problems)} ta muammo aniqlandi")

    # enforce xato ko'tarishi kerak
    raised = False
    try:
        enforce_production_config(prod_default)
    except InsecureProductionConfig as e:
        raised = True
        assert "xavfsiz emas" in str(e)
    assert raised, "FAIL: prod+default'да xato ko'tarilmadi!"
    print("OK 3: production + default -> InsecureProductionConfig ko'tarildi (ishga tushmaydi)")

    # ===== 4. PROD + to'g'ri sozlamalar -> muammo YO'Q =====
    prod_ok = FakeSettings(
        environment="production",
        secret_key="a-very-strong-random-64-char-secret-key-generated-properly-xyz",
        cors_allow_all=False,
        admin_default_password="Str0ng!AdminPass#2024",
        bypass_auth=False,
        otp_dev_expose=False,
    )
    problems = check_production_config(prod_ok)
    assert problems == [], f"FAIL: to'g'ri prod configда muammo: {problems}"
    enforce_production_config(prod_ok)  # xato yo'q
    print("OK 4: production + to'g'ri sozlamalar -> guard o'tdi (ishga tushadi)")

    # ===== 5. PROD + bypass_auth/otp_expose alohida aniqlanadi =====
    prod_bypass = FakeSettings(
        environment="production",
        secret_key="strong-secret-here-1234567890-abcdefghij",
        cors_allow_all=False,
        admin_default_password="changed",
        bypass_auth=True,
        otp_dev_expose=True,
    )
    problems = check_production_config(prod_bypass)
    assert any("BYPASS_AUTH" in p for p in problems), "FAIL: bypass_auth aniqlanmadi"
    assert any("OTP_DEV_EXPOSE" in p for p in problems), "FAIL: otp_dev_expose aniqlanmadi"
    print("OK 5: production + bypass_auth/otp_expose -> alohida aniqlandi")

    # ===== 6. "prod" qisqartmasи ham ishlaydi =====
    prod_short = FakeSettings(environment="prod")
    assert len(check_production_config(prod_short)) > 0, "FAIL: 'prod' tan olinmadi"
    print("OK 6: environment='prod' ham production deb qabul qilindi")

    print("\n=== BARCHA GUARD TESTLARI MUVAFFAQIYATLI ===")


if __name__ == "__main__":
    main()
