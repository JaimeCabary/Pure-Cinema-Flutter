from fastapi import APIRouter, Query, HTTPException
from typing import List, Optional
from app.models.schemas import MovieSchema
from app.services.tmdb_service import TMDBService

router = APIRouter(prefix="/api/movies", tags=["Movies"])

@router.get("/trending", response_model=List[MovieSchema])
async def get_trending():
    return await TMDBService.get_trending()

@router.get("/popular", response_model=List[MovieSchema])
async def get_popular():
    return await TMDBService.get_popular()

@router.get("/search", response_model=List[MovieSchema])
async def search_movies(q: str = Query("", alias="query")):
    return await TMDBService.search_movies(q)

@router.get("/{movie_id}", response_model=MovieSchema)
async def get_movie(movie_id: int):
    movie = await TMDBService.get_details(movie_id)
    if not movie:
        raise HTTPException(status_code=404, detail="Movie not found")
    return movie
