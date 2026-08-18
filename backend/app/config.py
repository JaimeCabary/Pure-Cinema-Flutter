import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PORT: int = 3000
    HOST: str = "0.0.0.0"
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    TMDB_API_KEY: str = os.getenv("TMDB_API_KEY", "")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "")

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
