from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from pydantic import BaseModel
from app.services import iptv_service

router = APIRouter(prefix="/api/iptv", tags=["IPTV & Live Channels"])

class CustomM3URequest(BaseModel):
    m3u_url: Optional[str] = None
    raw_content: Optional[str] = None

@router.get("/channels")
async def get_channels(
    category: Optional[str] = Query(None, description="Filter by channel group/category"),
    country: Optional[str] = Query(None, description="Filter by country code (e.g. US, UK)"),
    search: Optional[str] = Query(None, description="Search term for channel title"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0)
):
    """Retrieve worldwide live IPTV channels from https://iptv-org.github.io/iptv/index.m3u."""
    return await iptv_service.get_channels(
        category=category,
        country=country,
        search=search,
        limit=limit,
        offset=offset
    )

@router.get("/categories")
async def get_categories():
    """Retrieve all IPTV categories."""
    categories = await iptv_service.get_categories()
    return {"categories": categories}

@router.get("/countries")
async def get_countries():
    """Retrieve all IPTV country codes."""
    countries = await iptv_service.get_countries()
    return {"countries": countries}

@router.get("/stream-proxy")
async def stream_proxy(url: str = Query(..., description="Target media stream URL")):
    """
    VLC-style chunked stream proxy:
    Streams live chunks directly to client to bypass CORS or network constraints.
    """
    try:
        return await iptv_service.stream_media_proxy(url)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Streaming error: {str(e)}")

@router.post("/parse-custom")
async def parse_custom(body: CustomM3URequest):
    """Parse custom M3U playlist URL or raw text exactly like VLC Open Network Stream."""
    if body.raw_content:
        parsed = iptv_service.parse_m3u_content(body.raw_content)
        return {"total": len(parsed), "channels": parsed}
    elif body.m3u_url:
        import httpx
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            res = await client.get(body.m3u_url)
            if res.status_code != 200:
                raise HTTPException(status_code=400, detail=f"Failed to fetch M3U: HTTP {res.status_code}")
            parsed = iptv_service.parse_m3u_content(res.text)
            return {"total": len(parsed), "channels": parsed}
    else:
        raise HTTPException(status_code=400, detail="Provide either m3u_url or raw_content")
