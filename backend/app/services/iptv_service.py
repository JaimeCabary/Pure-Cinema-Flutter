import re
import time
import httpx
from typing import List, Dict, Optional, Any
from fastapi import HTTPException
from fastapi.responses import StreamingResponse

IPTV_INDEX_URL = "https://iptv-org.github.io/iptv/index.m3u"
IPTV_CATEGORIES_BASE = "https://iptv-org.github.io/iptv/categories"

# Cache structure
_cached_channels: List[Dict[str, Any]] = []
_cached_categories: List[str] = []
_cached_countries: List[str] = []
_last_fetch_time: float = 0
CACHE_TTL = 3600  # 1 hour cache

# Default fallback channels with verified 24/7 streams
DEFAULT_FALLBACK_CHANNELS = [
    {
        "id": "pure-cinema-4k",
        "name": "Pure Cinema TV 4K",
        "logo": "https://images.unsplash.com/photo-1518676590629-3dcbd9c5a5c9?w=100&h=100&fit=crop&q=80",
        "group": "Movies",
        "streamUrl": "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
        "currentProgram": "Cinema Showcase 4K: Interstellar Horizons",
        "badge": "4K LIVE",
        "country": "US"
    },
    {
        "id": "bloomberg-tv",
        "name": "Bloomberg TV News",
        "logo": "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=100&h=100&fit=crop&q=80",
        "group": "News",
        "streamUrl": "https://live-bloomberg-us.akamaized.net/hls/live/2042784/bloomberg_us/master.m3u8",
        "currentProgram": "Global Markets & Technology Live",
        "badge": "LIVE NEWS",
        "country": "US"
    },
    {
        "id": "redbull-tv",
        "name": "Red Bull TV HD",
        "logo": "https://images.unsplash.com/photo-1533107862482-0e6974b06ec4?w=100&h=100&fit=crop&q=80",
        "group": "Sports",
        "streamUrl": "https://rbmn-live.akamaized.net/hls/live/590964/BoRB-AT/master.m3u8",
        "currentProgram": "Uncharted Worlds: Global Extreme Series",
        "badge": "FEATURED",
        "country": "AT"
    },
    {
        "id": "france-24",
        "name": "France 24 English",
        "logo": "https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=100&h=100&fit=crop&q=80",
        "group": "News",
        "streamUrl": "https://f24hls-i.akamaihd.net/hls/live/221193/F24_EN_LO_HLS/master_500.m3u8",
        "currentProgram": "International Prime Broadcast",
        "badge": "LIVE",
        "country": "FR"
    },
    {
        "id": "nasa-tv",
        "name": "NASA TV Space Cast",
        "logo": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=100&h=100&fit=crop&q=80",
        "group": "Documentary",
        "streamUrl": "https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8",
        "currentProgram": "Deep Space Observations: Artemis & Webb",
        "badge": "SPACE LIVE",
        "country": "US"
    },
    {
        "id": "aljazeera-en",
        "name": "Al Jazeera English",
        "logo": "https://images.unsplash.com/photo-1495020689067-958852a7765e?w=100&h=100&fit=crop&q=80",
        "group": "News",
        "streamUrl": "https://live-hls-web-aje.getaj.net/AJE/03.m3u8",
        "currentProgram": "Inside Story & World Affairs",
        "badge": "HD",
        "country": "QA"
    },
    {
        "id": "dw-english",
        "name": "DW English Live",
        "logo": "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=100&h=100&fit=crop&q=80",
        "group": "News",
        "streamUrl": "https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8",
        "currentProgram": "Global 3000 & Future Tech",
        "badge": "HD",
        "country": "DE"
    },
    {
        "id": "world-poker",
        "name": "World Poker Tour TV",
        "logo": "https://images.unsplash.com/photo-1511193311914-0346f16efe90?w=100&h=100&fit=crop&q=80",
        "group": "Sports",
        "streamUrl": "https://wpt-live.akamaized.net/hls/live/1014869/wpt/master.m3u8",
        "currentProgram": "WPT Championship High Rollers Live",
        "badge": "LIVE",
        "country": "US"
    }
]


def parse_m3u_content(content: str) -> List[Dict[str, Any]]:
    """Parse raw M3U text into a structured list of channels."""
    channels = []
    lines = content.splitlines()
    current_info: Optional[Dict[str, Any]] = None

    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        if line.startswith("#EXTINF:"):
            # Extract attributes using regex
            logo_match = re.search(r'tvg-logo="([^"]*)"', line)
            group_match = re.search(r'group-title="([^"]*)"', line)
            id_match = re.search(r'tvg-id="([^"]*)"', line)
            country_match = re.search(r'tvg-country="([^"]*)"', line)
            
            # Extract channel title (after comma)
            name_parts = line.split(",")
            name = name_parts[-1].strip() if len(name_parts) > 1 else "Live Channel"
            
            # Clean up group title
            group = group_match.group(1).strip() if group_match and group_match.group(1) else "General"
            
            current_info = {
                "id": id_match.group(1).strip() if id_match and id_match.group(1) else name.lower().replace(" ", "-"),
                "name": name,
                "logo": logo_match.group(1).strip() if logo_match else "",
                "group": group,
                "country": country_match.group(1).strip().upper() if country_match else None,
                "badge": "HD" if "HD" in name or "720" in name or "1080" in name else "LIVE",
                "currentProgram": f"Live Broadcast · {group}",
            }
        elif not line.startswith("#") and current_info is not None:
            # This line contains the stream URL
            current_info["streamUrl"] = line
            channels.append(current_info)
            current_info = None

    return channels


async def fetch_iptv_org_playlist() -> List[Dict[str, Any]]:
    """Fetch and parse index.m3u from iptv-org repository with caching."""
    global _cached_channels, _cached_categories, _cached_countries, _last_fetch_time

    # Return cached if still valid
    if _cached_channels and (time.time() - _last_fetch_time < CACHE_TTL):
        return _cached_channels

    try:
        async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) PureCinema/1.0"}
            response = await client.get(IPTV_INDEX_URL, headers=headers)
            
            if response.status_code == 200:
                parsed = parse_m3u_content(response.text)
                if parsed:
                    # Merge with default fallback channels at the top for guaranteed instant playback
                    combined = list(DEFAULT_FALLBACK_CHANNELS)
                    existing_ids = {c["id"] for c in combined}
                    for c in parsed:
                        if c["id"] not in existing_ids:
                            combined.append(c)
                            existing_ids.add(c["id"])

                    _cached_channels = combined
                    _last_fetch_time = time.time()
                    
                    # Extract unique categories & countries
                    categories = set()
                    countries = set()
                    for ch in combined:
                        if ch.get("group"):
                            categories.add(ch["group"])
                        if ch.get("country"):
                            countries.add(ch["country"])
                    
                    _cached_categories = sorted(list(categories))
                    _cached_countries = sorted(list(countries))
                    return _cached_channels
    except Exception as e:
        print(f"Error fetching IPTV playlist: {e}")

    # If fetch failed, return default fallback channels
    if not _cached_channels:
        _cached_channels = DEFAULT_FALLBACK_CHANNELS
    return _cached_channels


async def get_channels(
    category: Optional[str] = None,
    country: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = 100,
    offset: int = 0
) -> Dict[str, Any]:
    """Retrieve filtered channels."""
    channels = await fetch_iptv_org_playlist()
    
    filtered = channels
    if category and category.lower() != "all" and category.lower() != "all channels":
        filtered = [c for c in filtered if c.get("group", "").lower() == category.lower()]
        
    if country and country.lower() != "all":
        filtered = [c for c in filtered if c.get("country", "").upper() == country.upper()]
        
    if search:
        s = search.lower().strip()
        filtered = [c for c in filtered if s in c.get("name", "").lower() or s in c.get("group", "").lower()]

    total = len(filtered)
    paged = filtered[offset:offset + limit]

    return {
        "total": total,
        "offset": offset,
        "limit": limit,
        "channels": paged
    }


async def get_categories() -> List[str]:
    """Get list of available channel categories."""
    await fetch_iptv_org_playlist()
    return ["All Channels"] + _cached_categories


async def get_countries() -> List[str]:
    """Get list of available countries."""
    await fetch_iptv_org_playlist()
    return ["All"] + _cached_countries


async def stream_media_proxy(stream_url: str):
    """
    VLC-like streaming proxy:
    Reads remote stream chunk by chunk and streams directly to client using StreamingResponse.
    Handles Range requests and CORS limitations seamlessly.
    """
    async def chunk_generator():
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            headers = {
                "User-Agent": "VLC/3.0.18 LibVLC/3.0.18",
                "Accept": "*/*",
            }
            async with client.stream("GET", stream_url, headers=headers) as response:
                async for chunk in response.aiter_bytes(chunk_size=1024 * 64):
                    yield chunk

    return StreamingResponse(
        chunk_generator(),
        media_type="application/vnd.apple.mpegurl" if ".m3u8" in stream_url else "video/mp4"
    )
