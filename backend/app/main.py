from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import auth, movies, watchlist, agent, iptv, payment

app = FastAPI(
    title="Pure Cinema API Backend",
    description="FastAPI UV-based Backend with Google GenAI / ADK Agent Integration",
    version="1.0.0"
)

# Enable CORS for Flutter app (Web, Desktop, Mobile)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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
        "version": "1.0.0"
    }
