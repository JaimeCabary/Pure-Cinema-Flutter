import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PORT: int = 3000
    HOST: str = "0.0.0.0"
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    TMDB_API_KEY: str = os.getenv("TMDB_API_KEY", "119f057993052814896eff7bb55e03db")
    JWT_SECRET: str = os.getenv("JWT_SECRET", "b0c7583e8a07caa3578626c7bbc945799f3866f52e9ccde311cda63c3e06eabb")

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
