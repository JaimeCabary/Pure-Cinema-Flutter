import json
import logging
import httpx
from typing import List, Dict, Any, Optional
from app.config import settings
from app.models.schemas import AgentChatRequest, AgentChatResponse, ActionCommand
from app.services.tmdb_service import TMDBService

logger = logging.getLogger("pure_cinema_agent")

SYSTEM_INSTRUCTION = """
You are Pure Cinema's AI CineBot — an ultra-knowledgeable, witty, and deeply conversational film concierge & cinema bestie.
You are passionate about cinema: from Christopher Nolan mind-benders and Denis Villeneuve sci-fi spectacles to indie gems, anime, Korean thrillers, docuseries, and Hollywood classics.

Your conversational style:
- Talk naturally, warmly, and conversationally. Treat the user like a fellow film lover.
- Engage in casual banter, answer movie trivia, debate fan theories, and match recommendations to specific moods (e.g. "I need a cozy rainy-day movie", "something like Interstellar", "best plot twists").
- Keep formatting clean, stylish, and readable with Markdown. Format movie and TV show titles in bold.
- Never respond with dry robotic boilerplate.

When suggesting actionable items, include relevant app actions:
- OPEN_MOVIE: navigate directly to a movie watch screen. Payload: {"movieId": <id>, "title": "<title>"}
- SEARCH_MOVIE: search movies matching a query. Payload: {"query": "<query>"}
- NAVIGATE_TAB: switch app tab (0: Home, 1: Live TV, 2: Search, 3: Watchlist, 4: Downloads). Payload: {"index": <num>}
- ADD_WATCHLIST: add movie to user watchlist. Payload: {"movieId": <id>}
"""

# Gemini Model Swarm Priority
GEMINI_MODELS = [
    "gemini-3.7-flash",
    "gemini-3.6-flash",
    "gemini-3.5-flash",
    "gemini-3.1-flash-lite",
    "gemini-2.5-flash",
]

class AgentService:
    @classmethod
    async def process_chat(cls, req: AgentChatRequest) -> AgentChatResponse:
        user_message = req.message.strip()
        user_lower = user_message.lower()

        actions: List[ActionCommand] = []
        suggested_prompts: List[str] = [
            "Recommend a mind-bending sci-fi movie",
            "What should I watch if I love Inception?",
            "Go to Live TV Channels",
            "Open my Watchlist",
            "Who directed Interstellar?"
        ]

        # 1. Quick In-App Tab Navigation Intents
        if user_lower in ["watchlist", "my list", "open watchlist", "show watchlist"]:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 3}))
            return AgentChatResponse(
                success=True,
                reply="🎬 Taking you straight to your **Watchlist**! Here you can find all your saved cinema titles.",
                actions=actions,
                suggestedPrompts=["What should I watch next?", "Search sci-fi movies", "Go back to Home"]
            )

        if user_lower in ["live tv", "channels", "open live tv", "live stream", "iptv"]:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 1}))
            return AgentChatResponse(
                success=True,
                reply="📺 Switching over to **Live TV Channels** with 10,000+ global broadcasts!",
                actions=actions,
                suggestedPrompts=["Find news channels", "Recommend movies", "Go to Home"]
            )

        # 2. Live Google Gemini Rotator Swarm
        gemini_key = settings.GEMINI_API_KEY.strip()
        if gemini_key:
            contents = []
            for h in req.history[-6:]:
                role = "user" if h.get("role") == "user" else "model"
                contents.append({"role": role, "parts": [{"text": h.get("content", "")}]})

            contents.append({
                "role": "user",
                "parts": [{"text": f"Context - Current Screen: {req.currentScreen or 'Home'}\nUser: {user_message}"}]
            })

            payload = {
                "system_instruction": {"parts": [{"text": SYSTEM_INSTRUCTION}]},
                "contents": contents,
                "generationConfig": {
                    "temperature": 0.8,
                    "maxOutputTokens": 800,
                }
            }

            async with httpx.AsyncClient(timeout=10.0) as client:
                for model in GEMINI_MODELS:
                    try:
                        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={gemini_key}"
                        res = await client.post(url, json=payload)
                        if res.status_code == 200:
                            data = res.json()
                            candidates = data.get("candidates", [])
                            if candidates and len(candidates) > 0:
                                text_parts = candidates[0].get("content", {}).get("parts", [])
                                reply_text = "".join([p.get("text", "") for p in text_parts])
                                if reply_text:
                                    if "search" in user_lower or "recommend" in user_lower or "find" in user_lower:
                                        clean_q = user_lower.replace("search", "").replace("recommend", "").replace("find", "").strip()
                                        if clean_q and len(clean_q) > 2:
                                            actions.append(ActionCommand(type="SEARCH_MOVIE", payload={"query": clean_q}))

                                    return AgentChatResponse(
                                        success=True,
                                        reply=reply_text,
                                        actions=actions,
                                        suggestedPrompts=suggested_prompts
                                    )
                        elif res.status_code == 403:
                            logger.error(f"Gemini API Key 403 Forbidden: {res.text}")
                            break
                        elif res.status_code == 429:
                            logger.warning(f"Model {model} hit rate limit (429). Rotating to next model...")
                            continue
                        else:
                            logger.warning(f"Model {model} returned HTTP {res.status_code}. Rotating...")
                            continue
                    except Exception as err:
                        logger.warning(f"Model {model} connection error: {err}. Rotating...")
                        continue

        # 3. Dynamic TMDB Search Fallback
        try:
            search_results = await TMDBService.search_movies(user_message)
            if search_results and len(search_results) > 0:
                top_movie = search_results[0]
                actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": top_movie.id, "title": top_movie.title}))
                
                movie_list_str = "\n".join([f"• **{m.title}** ({m.releaseDate[:4] if m.releaseDate else 'N/A'}) — ⭐ {m.voteAverage}/10\n  _{m.overview[:120]}..._" for m in search_results[:3]])
                reply = f"Here are curated cinema picks for **\"{user_message}\"**:\n\n{movie_list_str}\n\n🎬 Tap below to watch **{top_movie.title}**!"
                
                return AgentChatResponse(
                    success=True,
                    reply=reply,
                    actions=actions,
                    suggestedPrompts=suggested_prompts
                )
        except Exception:
            pass

        # 4. Natural Conversational Fallback
        return AgentChatResponse(
            success=True,
            reply=f"🎬 Hey there! I'm your Pure Cinema concierge. Ask me for movie recommendations, explore directors and cast trivia, or tell me what mood you're in!",
            actions=[],
            suggestedPrompts=suggested_prompts
        )
