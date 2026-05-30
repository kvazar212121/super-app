from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    app_name: str = "super-app-api"
    debug: bool = True  # Development: parolsiz kirish uchun True
    bypass_auth: bool = True  # Development: auth bypass
    api_v1_prefix: str = "/api/v1"

    database_url: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5434/superapp"
    )
    database_sync_url: str = (
        "postgresql://postgres:postgres@localhost:5434/superapp"
    )
    redis_url: str = "redis://localhost:6379/0"

    secret_key: str = "super-app-secret-key-change-in-prod"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 7

    cors_origins: str = "*"  # comma-separated: "http://localhost:3000,http://localhost:8080"
    cors_allow_all: bool = True  # Set False in production, use cors_origins list

    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60  # seconds

    # File upload
    max_upload_size_mb: int = 10
    upload_dir: str = "uploads"

    # Cashback
    cashback_rate: float = 1.0  # percent

    # Admin
    admin_default_phone: str = "admin"
    admin_default_password: str = "admin123"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()