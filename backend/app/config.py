import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PORT: int = 3000
    HOST: str = "0.0.0.0"
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    TMDB_API_KEY: str = os.getenv("TMDB_API_KEY", "")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "pure_cinema_secret_jwt_key_2026")
    PAYSTACK_SECRET_KEY: str = os.getenv("PAYSTACK_SECRET_KEY", "")
    PAYSTACK_PUBLIC_KEY: str = os.getenv("PAYSTACK_PUBLIC_KEY", "")
    RESEND_API_KEY: str = os.getenv("RESEND_API_KEY", "")
    RESEND_FROM_EMAIL: str = os.getenv("RESEND_FROM_EMAIL", "onboarding@resend.dev")

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
