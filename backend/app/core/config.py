from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    app_name: str = "super-app-api"
    debug: bool = True  # Development
    # "development" | "production". Production'да xavfli default qiymatlar
    # (secret_key, cors_allow_all, admin paroli) ishlatib bo'lmaydi — startup
    # guard ilovani ishga tushirmaydi. Localда o'zgartirishsiz ishlayveradi.
    environment: str = "development"
    bypass_auth: bool = False  # Production: faqat OTP orqali kirish
    require_otp_auth: bool = True  # Login/register uchun SMS OTP majburiy
    api_v1_prefix: str = "/api/v1"

    database_url: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5434/superapp"
    )
    database_sync_url: str = (
        "postgresql://postgres:postgres@localhost:5434/superapp"
    )
    redis_url: str = "redis://localhost:6379/0"

    secret_key: str = "super-app-secret-key-change-in-prod"
    access_token_expire_minutes: int = 10080  # 7 kun (mobil ilova uchun)
    refresh_token_expire_days: int = 365  # 1 yil

    cors_origins: str = "*"  # comma-separated: "http://localhost:3000,http://localhost:8080"
    cors_allow_all: bool = True  # Set False in production, use cors_origins list

    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60  # seconds

    # File upload
    max_upload_size_mb: int = 10
    upload_dir: str = "uploads"

    # Admin
    admin_default_phone: str = "admin"
    admin_default_password: str = "admin123"

    # SMS OTP
    otp_length: int = 6
    otp_expire_seconds: int = 300
    otp_max_attempts: int = 5
    otp_verification_token_minutes: int = 10
    otp_dev_expose: bool = False  # Production: kodni API javobida ko'rsatmaslik
    sms_provider: str = "console"  # console | devsms | eskiz
    devsms_base_url: str = "https://devsms.uz/api"
    devsms_token: str = ""
    devsms_sender: str = "4546"
    devsms_callback_url: str = ""
    sms_otp_template: str = "PROWORKER mobil ilovasidan ro'yxatdan o'tish uchun tasdiqlash kodi: {code}"
    eskiz_email: str = ""
    eskiz_password: str = ""
    eskiz_sender: str = "4546"

    # Coturn TURN/STUN Server
    turn_server_url: str = "turn:hubservis.uz:3478"
    turn_server_username: str = "superapp"
    turn_server_password: str = ""
    stun_server_url: str = "stun:hubservis.uz:3478"

    # Groq AI API (kalit faqat serverda saqlanadi)
    groq_api_key: str = ""
    groq_model: str = "llama3-70b-8192"
    groq_max_tokens: int = 1024
    groq_vision_model: str = "meta-llama/llama-4-scout-17b-16e-instruct"
    groq_translate_model: str = "llama-3.3-70b-versatile"

    # OpenAI API (aqlliroq vision — taom rasmidan kaloriya hisoblash uchun)
    # vision_provider = "openai" bo'lsa, kaloriya tahlili OpenAI orqali ishlaydi.
    openai_api_key: str = ""
    openai_vision_model: str = "gpt-4o"
    openai_translate_model: str = "gpt-4o-mini"
    openai_chat_model: str = "gpt-4o-mini"

    # DeepSeek (OpenAI-mos API) — matn/chat/tarjima uchun. Vision yo'q.
    deepseek_api_key: str = ""
    deepseek_chat_model: str = "deepseek-chat"

    # Google Gemini (OpenAI-mos API) — BEPUL vision (rasm/kaloriya) uchun.
    gemini_api_key: str = ""
    gemini_vision_model: str = "gemini-flash-latest"
    vision_provider: str = "groq"  # "groq" yoki "openai"
    translate_provider: str = "groq"  # "groq" yoki "openai" (mashq tarjimasi uchun)
    chat_provider: str = "groq"  # "groq" yoki "openai" (AI chat/agent uchun)

    # Fon schedulerlari (eslatma/checkin/scraper) — ko'p worker ishlatilganда
    # faqat BITTA protsessда True bo'lishi kerak (aks holda takroriy ishlaydi).
    run_schedulers: bool = True

    # DB bog'lanish puli — har WORKER uchun. Umumiy = (pool_size+max_overflow) × worker soni,
    # bu Postgres max_connections'дан oshmasligi kerak. 2 yadро/3 worker uchun 10+5=15 → 45 < 100.
    db_pool_size: int = 10
    db_max_overflow: int = 5

    # Fitnes mashqlari GIF manbasi (ExerciseDB CDN, faqat hotlink)
    exercise_gif_base: str = "https://static.exercisedb.dev/media"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()