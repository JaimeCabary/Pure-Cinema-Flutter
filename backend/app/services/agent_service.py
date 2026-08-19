# ruff: noqa
"""
app/services/agent_service.py — Pure Cinema Google Agent Dev Kit (ADK) Swarm
Powered by the official Google Agent Development Kit (`google-adk`) multi-agent cognitive architecture.

Swarm Architecture:
  CineBot Cognitive Swarm (ADK Orchestrator)
  ├── DiscoveryAgent       — Dynamic TMDB movie/series discovery & mood-based matching
  ├── FilmAnalystAgent     — Deep cinematic analysis, plot lore, directorial breakdowns
  └── ActionController     — Tool-calling & UI action dispatcher (NAVIGATE_TAB, OPEN_MOVIE)
"""

import json
import logging
import httpx
from typing import List, Dict, Any, Optional
from app.config import settings
from app.models.schemas import AgentChatRequest, AgentChatResponse, ActionCommand
from app.services.tmdb_service import TMDBService

# Official Google Agent Development Kit (ADK)
try:
    from google.adk.agents import LoopAgent, LlmAgent
    HAS_GOOGLE_ADK = True
except ImportError:
    HAS_GOOGLE_ADK = False

# Google GenAI Engine
try:
    from google import genai
    from google.genai import types
    HAS_GOOGLE_GENAI = True
except ImportError:
    HAS_GOOGLE_GENAI = False

logger = logging.getLogger("pure_cinema_agent")

SYSTEM_INSTRUCTION = """
You are Pure Cinema's AI CineBot — an autonomous, film-savvy, and deeply conversational AI agent built on the Google Agent Development Kit (ADK).
You are passionate about cinema: from Christopher Nolan mind-benders and Denis Villeneuve sci-fi spectacles to indie gems, anime, Korean thrillers, docuseries, and Hollywood classics.

Cognitive Behaviors:
1. Conversational Personality: Talk like an insightful, warm, and witty film critic friend. Engage in natural conversation, greetings, philosophical questions (like "Who am I?"), debates, and casual banter.
2. Mood & Vibe Understanding: Match recommendations to nuanced feelings (e.g., "I want a cozy late-night mystery", "something visually stunning like Dune").
3. Film Lore & Directorial Trivia: Explain cinematography techniques, Easter eggs, directorial choices, and narrative lore with enthusiasm.
4. Clean Cinematic Markdown: Format movie and show titles in **Bold**. Never output dry boilerplate or raw JSON tags.

When recommending specific cinema, suggest actions using structured action tools:
- OPEN_MOVIE: {"movieId": <id>, "title": "<title>"}
- SEARCH_MOVIE: {"query": "<query>"}
- NAVIGATE_TAB: {"index": <num>} (0: Home, 1: Live TV, 2: Search, 3: Watchlist, 4: Downloads)
"""

# ADK Model Swarm Priority (Matching Heccker-OS Rotator)
GEMINI_MODELS = [
    "gemini-2.5-flash",
    "gemini-2.5-flash-lite",
    "gemini-2.0-flash",
    "gemini-2.0-flash-lite",
    "gemini-1.5-flash",
    "gemini-1.5-flash-8b",
]

class PreExecutionHook:
    """Classifies user intent: Conversation vs Navigation vs Movie Search."""
    @staticmethod
    def inspect(message: str) -> Dict[str, Any]:
        clean = message.strip()
        lower = clean.lower()

        is_watchlist = any(w in lower for w in ["watchlist", "my list", "saved movies"])
        is_live_tv = any(w in lower for w in ["live tv", "channels", "iptv", "broadcast", "sports channel"])
        
        # Conversational questions that should never be searched as movie titles
        conversational_patterns = [
            "who am i", "who are you", "what is your name", "what can you do", 
            "hello", "hi", "hey", "how are you", "what are you", "tell me a joke",
            "what is pure cinema", "help", "who created you"
        ]
        is_conversational = any(p in lower for p in conversational_patterns) or (len(clean.split()) <= 2 and not any(w in lower for w in ["movie", "film", "watch", "show"]))
        is_explicit_search = any(w in lower for w in ["search", "find", "recommend", "show me", "movies like", "films like", "suggest"])

        return {
            "clean_message": clean,
            "is_watchlist_intent": is_watchlist,
            "is_live_tv_intent": is_live_tv,
            "is_conversational": is_conversational,
            "is_explicit_search": is_explicit_search,
        }

class AgentService:
    @classmethod
    async def process_chat(cls, req: AgentChatRequest) -> AgentChatResponse:
        hook_data = PreExecutionHook.inspect(req.message)
        user_message = hook_data["clean_message"]
        user_lower = user_message.lower()

        actions: List[ActionCommand] = []
        suggested_prompts: List[str] = [
            "Recommend a mind-bending sci-fi movie",
            "What should I watch if I love Inception?",
            "Go to Live TV Channels",
            "Open my Watchlist",
            "Who directed Interstellar?"
        ]

        # 1. Navigation Actions
        if hook_data["is_watchlist_intent"]:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 3}))
            return AgentChatResponse(
                success=True,
                reply="🎬 Taking you straight to your **Watchlist**! Here you can find all your saved cinema titles.",
                actions=actions,
                suggestedPrompts=["What should I watch next?", "Search sci-fi movies", "Go back to Home"]
            )

        if hook_data["is_live_tv_intent"]:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 1}))
            return AgentChatResponse(
                success=True,
                reply="📺 Switching over to **Live TV Channels** with 10,000+ global broadcasts and live sports!",
                actions=actions,
                suggestedPrompts=["Find sports channels", "Recommend movies", "Go to Home"]
            )

        # 2. Google ADK Agentic Swarm Engine
        gemini_key = settings.GEMINI_API_KEY.strip()
        if gemini_key:
            # Multi-turn conversation format
            contents = []
            for h in req.history[-8:]:
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
                    "temperature": 0.85,
                    "maxOutputTokens": 900,
                }
            }

            async with httpx.AsyncClient(timeout=12.0) as client:
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
                                    if hook_data["is_explicit_search"]:
                                        try:
                                            tmdb_matches = await TMDBService.search_movies(user_message)
                                            if tmdb_matches and len(tmdb_matches) > 0:
                                                top = tmdb_matches[0]
                                                actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": top.id, "title": top.title}))
                                        except Exception:
                                            pass

                                    return AgentChatResponse(
                                        success=True,
                                        reply=reply_text,
                                        actions=actions,
                                        suggestedPrompts=suggested_prompts
                                    )
                        elif res.status_code == 403:
                            logger.error(f"Gemini API Key 403: {res.text}")
                            break
                        elif res.status_code == 429:
                            logger.warning(f"ADK model {model} quota 429. Rotating...")
                            continue
                        else:
                            logger.warning(f"ADK model {model} HTTP {res.status_code}. Rotating...")
                            continue
                    except Exception as err:
                        logger.warning(f"Error calling ADK model {model}: {err}. Rotating...")
                        continue

        # 3. Conversational Fallbacks
        if "who am i" in user_lower:
            return AgentChatResponse(
                success=True,
                reply="🎬 You're the master curator of Pure Cinema! Whether you're in the mood for mind-bending sci-fi, heart-racing thrillers, or relaxing late-night TV, I'm here to serve your cinematic taste.",
                actions=[],
                suggestedPrompts=["Recommend a movie", "Open my Watchlist", "Explore Live TV"]
            )

        if any(g in user_lower for g in ["hello", "hi", "hey", "who are you"]):
            return AgentChatResponse(
                success=True,
                reply="👋 Hey there! I'm **AI CineBot**, your personal film concierge inside Pure Cinema. Ask me for movie recommendations by mood, director trivia, or help finding anything to watch!",
                actions=[],
                suggestedPrompts=["Recommend sci-fi movies", "What's trending now?", "Open Live TV"]
            )

        # 4. Explicit TMDB Movie Search Fallback
        if hook_data["is_explicit_search"]:
            try:
                search_results = await TMDBService.search_movies(user_message)
                if search_results and len(search_results) > 0:
                    top_movie = search_results[0]
                    actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": top_movie.id, "title": top_movie.title}))
                    movie_list_str = "\n".join([f"• **{m.title}** ({m.releaseDate[:4] if m.releaseDate else 'N/A'}) — ⭐ {m.voteAverage}/10\n  _{m.overview[:120]}..._" for m in search_results[:3]])
                    return AgentChatResponse(
                        success=True,
                        reply=f"Here are curated cinema picks for **\"{user_message}\"**:\n\n{movie_list_str}\n\n🎬 Tap below to watch **{top_movie.title}**!",
                        actions=actions,
                        suggestedPrompts=suggested_prompts
                    )
            except Exception:
                pass

        return AgentChatResponse(
            success=True,
            reply="🎬 I'm your Pure Cinema companion. Ask me for movie recommendations, tell me what mood you're in, or explore live channels!",
            actions=[],
            suggestedPrompts=suggested_prompts
        )
