"""Application configuration via pydantic-settings."""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./schedsolicit.db"

    # JWT
    SECRET_KEY: str = "CHANGE-ME-IN-PRODUCTION-USE-SECRETS"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    CORS_ORIGINS: List[str] = Field(default=["http://localhost:3000", "http://localhost:5173"])

    # Rate limiting
    RATE_LIMIT_DEFAULT: str = "60/minute"
    RATE_LIMIT_AUTH: str = "10/minute"
    PASSCODE_MAX_ATTEMPTS: int = 10
    PASSCODE_LOCKOUT_MINUTES: int = 15

    # File uploads
    MAX_UPLOAD_SIZE_MB: int = 10

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


settings = Settings()
