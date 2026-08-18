import httpx
from typing import List, Dict, Any, Optional
from app.config import settings
from app.models.schemas import MovieSchema, CastMemberSchema

TMDB_BASE_URL = "https://api.themoviedb.org/3"

FALLBACK_MOVIES = [
    MovieSchema(
        id=157336,
        title="Interstellar",
        overview="The adventures of a group of explorers who make use of a newly discovered wormhole to surpass the limitations on human space travel.",
        posterPath="/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        backdropPath="/xJHokMbljvjADYdit5fK5VQsXEG.jpg",
        releaseDate="2014-11-05",
        voteAverage=8.4
    ),
    MovieSchema(
        id=27205,
        title="Inception",
        overview="Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets, is offered a chance to regain his old life.",
        posterPath="/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
        backdropPath="/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg",
        releaseDate="2010-07-15",
        voteAverage=8.4
    ),
    MovieSchema(
        id=550,
        title="Fight Club",
        overview="A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy.",
        posterPath="/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        backdropPath="/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
        releaseDate="1999-10-15",
        voteAverage=8.4
    ),
    MovieSchema(
        id=299534,
        title="Avengers: Endgame",
        overview="After the devastating events of Infinity War, the universe is in ruins. With the help of remaining allies, the Avengers assemble once more.",
        posterPath="/or06FN3Dka5tukK1e9sl16pB3iy.jpg",
        backdropPath="/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg",
        releaseDate="2019-04-24",
        voteAverage=8.3
    ),
    MovieSchema(
        id=603,
        title="The Matrix",
        overview="Set in the 22nd century, The Matrix tells the story of a computer hacker who joins a group of underground insurgents fighting the vast and powerful computers.",
        posterPath="/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
        backdropPath="/easkWjhK5d7E871vE3q2J6oZf6U.jpg",
        releaseDate="1999-03-30",
        voteAverage=8.2
    ),
    MovieSchema(
        id=155,
        title="The Dark Knight",
        overview="Batman raises the stakes in his war on crime. With the help of Lt. Jim Gordon and District Attorney Harvey Dent, Batman sets out to dismantle criminal organizations.",
        posterPath="/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
        backdropPath="/nMKdUUepR0i5zn0y1T4CsSB5chy.jpg",
        releaseDate="2008-07-16",
        voteAverage=8.5
    )
]

def _parse_movie(data: Dict[str, Any]) -> MovieSchema:
    return MovieSchema(
        id=data.get("id", 0),
        title=data.get("title") or data.get("name") or "Untitled",
        overview=data.get("overview", ""),
        posterPath=data.get("poster_path"),
        backdropPath=data.get("backdrop_path"),
        releaseDate=data.get("release_date") or data.get("first_air_date"),
        voteAverage=float(data.get("vote_average", 0.0))
    )

class TMDBService:
    @staticmethod
    async def fetch_endpoint(endpoint: str, params: Optional[Dict[str, str]] = None) -> List[MovieSchema]:
        query_params = {"api_key": settings.TMDB_API_KEY}
        if params:
            query_params.update(params)
        
        url = f"{TMDB_BASE_URL}{endpoint}"
        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                resp = await client.get(url, params=query_params)
                if resp.status_code == 200:
                    data = resp.json()
                    results = data.get("results", [])
                    return [_parse_movie(item) for item in results if item.get("poster_path")]
        except Exception:
            pass
        return FALLBACK_MOVIES

    @classmethod
    async def get_trending(cls) -> List[MovieSchema]:
        return await cls.fetch_endpoint("/trending/movie/week")

    @classmethod
    async def get_popular(cls) -> List[MovieSchema]:
        return await cls.fetch_endpoint("/movie/popular")

    @classmethod
    async def search_movies(cls, query: str) -> List[MovieSchema]:
        if not query.strip():
            return await cls.get_popular()
        return await cls.fetch_endpoint("/search/movie", {"query": query.strip()})

    @classmethod
    async def get_details(cls, movie_id: int) -> Optional[MovieSchema]:
        url = f"{TMDB_BASE_URL}/movie/{movie_id}"
        try:
            async with httpx.AsyncClient(timeout=4.0) as client:
                resp = await client.get(url, params={"api_key": settings.TMDB_API_KEY})
                if resp.status_code == 200:
                    return _parse_movie(resp.json())
        except Exception:
            pass
        for m in FALLBACK_MOVIES:
            if m.id == movie_id:
                return m
        return FALLBACK_MOVIES[0]
