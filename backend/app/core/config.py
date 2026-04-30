from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "super-app-api"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/superapp"
    redis_url: str = "redis://localhost:6379/0"

    secret_key: str = "o-zgartiring"
    access_token_expire_minutes: int = 60

    cors_origins: str = "http://localhost:8080,http://127.0.0.1:8080"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
