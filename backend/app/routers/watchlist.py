from fastapi import APIRouter
from typing import List, Dict, Any
from app.models.schemas import MovieSchema, WatchlistAddRequest, HistorySaveRequest

router = APIRouter(prefix="/api", tags=["Watchlist & History"])

# In-memory watchlist store
WATCHLIST_STORE: List[Dict[str, Any]] = []
HISTORY_STORE: Dict[int, Dict[str, Any]] = {}

@router.get("/watchlist", response_model=List[MovieSchema])
def get_watchlist():
    return [m["movie"] for m in WATCHLIST_STORE if "movie" in m]

@router.post("/watchlist")
def add_to_watchlist(req: WatchlistAddRequest):
    if not any(m.get("movie", {}).get("id") == req.movie.id for m in WATCHLIST_STORE):
        WATCHLIST_STORE.append({"movieId": req.movie.id, "movie": req.movie.model_dump()})
    return {"success": True, "message": "Added to watchlist"}

@router.delete("/watchlist/{movie_id}")
def remove_from_watchlist(movie_id: int):
    global WATCHLIST_STORE
    WATCHLIST_STORE = [m for m in WATCHLIST_STORE if m.get("movieId") != movie_id]
    return {"success": True, "message": "Removed from watchlist"}

@router.post("/history")
def save_history(req: HistorySaveRequest):
    HISTORY_STORE[req.movieId] = {
        "movieId": req.movieId,
        "position": req.position,
        "duration": req.duration
    }
    return {"success": True}
