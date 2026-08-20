import httpx
from typing import List, Dict, Any, Optional

# Curated Classic Public Domain Films & Blender Open Movies
CURATED_PUBLIC_DOMAIN_MOVIES = [
    {
        "id": 900001,
        "title": "Big Buck Bunny (Blender Open Movie)",
        "overview": "A large and lovable rabbit deals with bullying forest creatures in this iconic open-source 4K animation masterpiece.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.bip.png",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/c/c5/Big_buck_bunny_poster_big.bip.png",
        "releaseDate": "2008-04-10",
        "voteAverage": 8.5,
        "source": "Blender Open Movies",
        "streamUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    },
    {
        "id": 900002,
        "title": "Tears of Steel (Blender Sci-Fi Open Film)",
        "overview": "Set in a dystopian future Rotterdam, a group of warriors and scientists attempt to save the world from robotic destruction.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/0/0c/Tears_of_Steel_poster.jpg",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/0/0c/Tears_of_Steel_poster.jpg",
        "releaseDate": "2012-09-26",
        "voteAverage": 8.1,
        "source": "Blender Open Movies",
        "streamUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
    },
    {
        "id": 900003,
        "title": "Sintel (Blender Fantasy Open Film)",
        "overview": "A lonely young woman named Sintel searches the world for her stolen dragon companion Scales.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/5/52/Sintel_poster.jpg",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/5/52/Sintel_poster.jpg",
        "releaseDate": "2010-09-27",
        "voteAverage": 8.2,
        "source": "Blender Open Movies",
        "streamUrl": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
    },
    {
        "id": 900004,
        "title": "Night of the Living Dead (1968)",
        "overview": "George A. Romero's seminal public domain horror classic that birthed the modern zombie genre.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/0/00/Night_of_the_Living_Dead_%281968%29_poster.jpg",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/0/00/Night_of_the_Living_Dead_%281968%29_poster.jpg",
        "releaseDate": "1968-10-01",
        "voteAverage": 8.0,
        "source": "Internet Archive / WikiFlix",
        "streamUrl": "https://archive.org/download/night_of_the_living_dead/night_of_the_living_dead_512kb.mp4"
    },
    {
        "id": 900005,
        "title": "Charade (1963 - Cary Grant & Audrey Hepburn)",
        "overview": "A romance and suspense thriller in Paris starring Audrey Hepburn and Cary Grant, released into the public domain.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/e/e0/Charade_poster.jpg",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/e/e0/Charade_poster.jpg",
        "releaseDate": "1963-12-05",
        "voteAverage": 8.3,
        "source": "Internet Archive / WikiFlix",
        "streamUrl": "https://archive.org/download/Charade1963/Charade1963.mp4"
    },
    {
        "id": 900006,
        "title": "The General (1926 - Buster Keaton)",
        "overview": "Buster Keaton's comedy masterpiece about a Western & Atlantic Railroad train engineer during the Civil War.",
        "posterPath": "https://upload.wikimedia.org/wikipedia/commons/6/6f/The_General_%281926_film%29_poster.jpg",
        "backdropPath": "https://upload.wikimedia.org/wikipedia/commons/6/6f/The_General_%281926_film%29_poster.jpg",
        "releaseDate": "1926-12-25",
        "voteAverage": 8.4,
        "source": "Wikimedia Commons / WikiFlix",
        "streamUrl": "https://archive.org/download/TheGeneralBusterKeaton1926/TheGeneralBusterKeaton1926.mp4"
    },
    {
        "id": 900007,
        "title": "Prelinger Industrial & Space Archive: Destination Earth",
        "overview": "A classic 1950s animated industrial and space exploration film from the famous Prelinger Archives collection.",
        "posterPath": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&h=400&fit=crop&q=80",
        "backdropPath": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&h=400&fit=crop&q=80",
        "releaseDate": "1956-01-01",
        "voteAverage": 7.8,
        "source": "Prelinger Archives",
        "streamUrl": "https://archive.org/download/DestinationEarth1956/DestinationEarth1956_512kb.mp4"
    }
]

class PublicDomainService:
    @staticmethod
    async def get_curated_public_domain_movies() -> List[Dict[str, Any]]:
        """Returns curated list of verified Public Domain and Open Source films."""
        return CURATED_PUBLIC_DOMAIN_MOVIES

    @staticmethod
    async def search_internet_archive(query: str, limit: int = 15) -> List[Dict[str, Any]]:
        """
        Queries Internet Archive Advanced Search API dynamically for public domain video titles.
        """
        if not query.strip():
            return CURATED_PUBLIC_DOMAIN_MOVIES

        url = "https://archive.org/advancedsearch.php"
        params = {
            "q": f'({query}) AND mediatype:(movies) AND (collection:(classic_tv_movies) OR collection:(prelinger) OR collection:(feature_films))',
            "fl[]": ["identifier", "title", "description", "year", "downloads"],
            "sort[]": "downloads desc",
            "rows": str(limit),
            "page": "1",
            "output": "json"
        }

        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                resp = await client.get(url, params=params)
                if resp.status_code == 200:
                    data = resp.json()
                    docs = data.get("response", {}).get("docs", [])
                    results = []
                    for idx, doc in enumerate(docs):
                        ident = doc.get("identifier", "")
                        title = doc.get("title", f"Archive Film {ident}")
                        desc = doc.get("description", "Public domain archive film.")
                        year = doc.get("year", "Classic")
                        
                        results.append({
                            "id": 950000 + idx,
                            "title": f"{title} ({year})",
                            "overview": desc[:250] + "..." if len(desc) > 250 else desc,
                            "posterPath": f"https://archive.org/services/img/{ident}",
                            "backdropPath": f"https://archive.org/services/img/{ident}",
                            "releaseDate": f"{year}-01-01" if str(year).isdigit() else "1950-01-01",
                            "voteAverage": 7.5,
                            "source": "Internet Archive",
                            "streamUrl": f"https://archive.org/download/{ident}/{ident}_512kb.mp4"
                        })
                    return results if results else CURATED_PUBLIC_DOMAIN_MOVIES
        except Exception as e:
            print(f"Internet Archive search fallback: {e}")

        return CURATED_PUBLIC_DOMAIN_MOVIES
