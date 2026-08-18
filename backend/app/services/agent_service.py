import json
import logging
from typing import List, Dict, Any, Optional
from app.config import settings
from app.models.schemas import AgentChatRequest, AgentChatResponse, ActionCommand
from app.services.tmdb_service import TMDBService

logger = logging.getLogger("pure_cinema_agent")

SYSTEM_INSTRUCTION = """
You are Pure Cinema's AI CineBot - an intelligent, movie-savvy cinema concierge assistant inside the Pure Cinema streaming platform.
Your goals:
1. Help users discover movies, TV shows, and live content based on mood, genre, cast, director, or natural language prompts.
2. Provide concise, enthusiastic, and insightful answers about films, directors, cinematography, and trivia.
3. Suggest interactive app actions using JSON action flags when appropriate:
   - OPEN_MOVIE: navigate directly to a movie watch screen. Payload: {"movieId": <id>, "title": "<title>"}
   - SEARCH_MOVIE: search movies matching a query. Payload: {"query": "<query>"}
   - NAVIGATE_TAB: switch app tab (0: Home, 1: Live TV, 2: Search, 3: Watchlist, 4: Downloads). Payload: {"index": <num>}
   - ADD_WATCHLIST: add movie to user watchlist. Payload: {"movieId": <id>}

Keep responses friendly, elegant, cinematic, and concise. Format titles in bold.
"""

# Free-tier model rotation priority list
FREE_TIER_MODELS = [
    "gemini-2.5-flash",
    "gemini-2.0-flash",
    "gemini-1.5-flash",
    "gemini-1.5-pro",
    "gemini-2.0-flash-lite",
]

class AgentService:
    @classmethod
    async def process_chat(cls, req: AgentChatRequest) -> AgentChatResponse:
        user_message = req.message.strip()
        user_lower = user_message.lower()

        actions: List[ActionCommand] = []
        suggested_prompts: List[str] = [
            "Recommend a mind-bending sci-fi movie",
            "Show me top rated action movies",
            "Go to Live TV",
            "Open my Watchlist",
            "Who directed Interstellar?"
        ]

        # 1. Instant local intent matcher for sub-millisecond tab navigation
        if "watchlist" in user_lower or "my list" in user_lower or "saved movies" in user_lower:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 3}))
            return AgentChatResponse(
                success=True,
                reply="🎬 Taking you straight to your **Watchlist**! Here you can find all your saved titles.",
                actions=actions,
                suggestedPrompts=["What should I watch next?", "Search sci-fi movies", "Go back to Home"]
            )

        if "live tv" in user_lower or "channels" in user_lower or "broadcast" in user_lower or "iptv" in user_lower:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 1}))
            return AgentChatResponse(
                success=True,
                reply="📺 Switching over to **Live TV Channels** with 10,000+ global broadcasts!",
                actions=actions,
                suggestedPrompts=["Find news channels", "Recommend movies", "Go to Home"]
            )

        if "search" in user_lower and len(user_lower.split()) <= 4:
            clean_q = user_lower.replace("search", "").replace("for", "").strip()
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 2}))
            return AgentChatResponse(
                success=True,
                reply=f"🔍 Opening **Search** for *\"{clean_q}\"*.",
                actions=actions,
                suggestedPrompts=["Show trending movies", "Open Live TV", "Go to Watchlist"]
            )

        # 2. Google GenAI SDK (ADK) with Multi-Model Rotator over Free Models
        if settings.GEMINI_API_KEY:
            try:
                from google import genai
                from google.genai import types

                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                prompt = f"{SYSTEM_INSTRUCTION}\nUser query: {user_message}\nCurrent screen: {req.currentScreen or 'Home'}"

                # Model Rotator Loop
                for model_name in FREE_TIER_MODELS:
                    try:
                        logger.info(f"Invoking GenAI ADK with model: {model_name}")
                        response = client.models.generate_content(
                            model=model_name,
                            contents=prompt
                        )

                        if response and response.text:
                            reply_text = response.text

                            # Extract movie query intent if user asked for suggestions
                            if "search" in user_lower or "find" in user_lower or "recommend" in user_lower:
                                clean_query = user_lower.replace("recommend", "").replace("find", "").replace("search", "").strip()
                                if clean_query:
                                    actions.append(ActionCommand(type="SEARCH_MOVIE", payload={"query": clean_query}))

                            return AgentChatResponse(
                                success=True,
                                reply=reply_text,
                                actions=actions,
                                suggestedPrompts=suggested_prompts
                            )
                    except Exception as model_err:
                        logger.warning(f"Model {model_name} failed or rate-limited: {model_err}. Rotating to next free model...")
                        continue

            except Exception as e:
                logger.warning(f"Google GenAI ADK client error: {e}. Falling back to TMDB-assisted concierge.")

        # 3. Dynamic TMDB Semantic Concierge Fallback
        search_results = await TMDBService.search_movies(user_message)
        if search_results and len(search_results) > 0:
            top_movie = search_results[0]
            actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": top_movie.id, "title": top_movie.title}))
            
            movie_list_str = "\n".join([f"• **{m.title}** ({m.releaseDate[:4] if m.releaseDate else 'N/A'}) - ⭐ {m.voteAverage}/10" for m in search_results[:3]])
            reply = f"Here are curated cinema picks for **\"{user_message}\"**:\n\n{movie_list_str}\n\nTap below to watch **{top_movie.title}** right now!"
            
            return AgentChatResponse(
                success=True,
                reply=reply,
                actions=actions,
                suggestedPrompts=suggested_prompts
            )

        # Standard Concierge Response
        return AgentChatResponse(
            success=True,
            reply="🍿 **Welcome to Pure Cinema AI CineBot!**\nI can recommend blockbusters, navigate to your watchlist or Live TV, or answer cinema trivia. Ask me anything like *\"Recommend mind-bending sci-fi movies\"*!",
            actions=[],
            suggestedPrompts=suggested_prompts
        )
