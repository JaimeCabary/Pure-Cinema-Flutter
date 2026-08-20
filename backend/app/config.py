import os
import urllib.parse
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
    
    # Google SMTP & Email settings
    SMTP_SERVER: str = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str = os.getenv("SMTP_USER", os.getenv("GMAIL_USER", ""))
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", os.getenv("GMAIL_APP_PASSWORD", ""))

    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:QC/mk_UA-mM5*i_@db.vponyrvkxjwdcwnlydjt.supabase.co:5432/postgres"
    )

    def get_sqlalchemy_database_url(self) -> str:
        """
        Returns a clean database URL for SQLAlchemy.
        Handles special characters in password or falls back gracefully.
        """
        db_url = self.DATABASE_URL.strip() if self.DATABASE_URL else ""
        if not db_url:
            return "sqlite:///./pure_cinema.db"

        if db_url.startswith("postgresql://") or db_url.startswith("postgres://"):
            db_url = db_url.replace("postgres://", "postgresql://", 1)
            # Check if raw URL has unencoded special chars in credentials
            try:
                prefix, rest = db_url.split("://", 1)
                if "@" in rest:
                    user_pass, host_db = rest.rsplit("@", 1)
                    if ":" in user_pass:
                        user, password = user_pass.split(":", 1)
                        encoded_password = urllib.parse.quote_plus(urllib.parse.unquote(password))
                        db_url = f"{prefix}://{user}:{encoded_password}@{host_db}"
            except Exception:
                pass

        return db_url

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
