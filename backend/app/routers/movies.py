from fastapi import APIRouter, Query, HTTPException
from typing import List, Optional, Dict, Any
from app.models.schemas import MovieSchema
from app.services.tmdb_service import TMDBService
from app.services.public_domain_service import PublicDomainService

router = APIRouter(prefix="/api/movies", tags=["Movies"])

@router.get("/trending", response_model=List[MovieSchema])
async def get_trending():
    return await TMDBService.get_trending()

@router.get("/popular", response_model=List[MovieSchema])
async def get_popular():
    return await TMDBService.get_popular()

@router.get("/public-domain")
async def get_public_domain_movies():
    """
    Returns curated public domain films from Internet Archive, WikiFlix,
    Wikimedia Commons, Prelinger Archives & Blender Open Movies.
    """
    return await PublicDomainService.get_curated_public_domain_movies()

@router.get("/archive-search")
async def search_archive(q: str = Query("", alias="query")):
    """
    Direct search into Internet Archive's database for public domain titles.
    """
    return await PublicDomainService.search_internet_archive(q)

@router.get("/search", response_model=List[MovieSchema])
async def search_movies(q: str = Query("", alias="query")):
    return await TMDBService.search_movies(q)

@router.get("/{movie_id}")
async def get_movie(movie_id: int):
    # Check if movie ID is in public domain range
    if movie_id >= 900000:
        pd_movies = await PublicDomainService.get_curated_public_domain_movies()
        for m in pd_movies:
            if m["id"] == movie_id:
                return m
    movie = await TMDBService.get_details(movie_id)
    if not movie:
        raise HTTPException(status_code=404, detail="Movie not found")
    return movie
