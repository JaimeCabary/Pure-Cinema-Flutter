from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import init_db
from app.routers import auth, movies, watchlist, agent, iptv, payment

app = FastAPI(
    title="Pure Cinema API Backend",
    description="FastAPI Backend with Google Gemini AI CineBot Rotator & Cinema Streaming Engine",
    version="1.0.0"
)

# Robust CORS for Flutter Web, iOS, Android, and Desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Initialize PostgreSQL / SQLite Database Tables on Startup
@app.on_event("startup")
def on_startup():
    try:
        init_db()
    except Exception as e:
        print(f"Warning on startup database init: {e}")

# Include Routers
app.include_router(auth.router)
app.include_router(movies.router)
app.include_router(watchlist.router)
app.include_router(agent.router)
app.include_router(iptv.router)
app.include_router(payment.router)

@app.get("/")
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "Pure Cinema FastAPI Backend",
        "adk_agent_enabled": bool(settings.GEMINI_API_KEY),
        "database": "postgresql_or_sqlite_ready",
        "version": "1.0.0"
    }
