import json
import logging
from typing import List, Dict, Any, Optional
from app.config import settings
from app.models.schemas import AgentChatRequest, AgentChatResponse, ActionCommand
from app.services.tmdb_service import TMDBService

logger = logging.getLogger("pure_cinema_agent")

SYSTEM_INSTRUCTION = """
You are Pure Cinema's AI Agent - an intelligent, movie-savvy cinema concierge assistant inside the Pure Cinema app.
Your goals:
1. Help users discover movies, TV shows, and live content based on their mood, genre preference, or natural language prompts.
2. Provide concise, enthusiastic, and insightful answers about films, directors, cast, and trivia.
3. Suggest interactive app actions using JSON action flags when appropriate:
   - OPEN_MOVIE: navigate directly to a movie watch screen. Payload: {"movieId": <id>, "title": "<title>"}
   - SEARCH_MOVIE: search movies matching a query. Payload: {"query": "<query>"}
   - NAVIGATE_TAB: switch app tab (0: Home, 1: Search, 2: Watchlist, 3: Live TV, 4: Profile). Payload: {"index": <num>}
   - ADD_WATCHLIST: add movie to user watchlist. Payload: {"movieId": <id>}

Keep responses friendly, elegant, and concise.
"""

class AgentService:
    @classmethod
    async def process_chat(cls, req: AgentChatRequest) -> AgentChatResponse:
        user_message = req.message.strip()
        user_lower = user_message.lower()

        actions: List[ActionCommand] = []
        suggested_prompts: List[str] = [
            "Recommend a mind-bending sci-fi movie",
            "Show me top rated action movies",
            "Go to my Watchlist",
            "Who starred in Interstellar?"
        ]

        # 1. Check for explicit local intent matching for instant sub-millisecond response
        if "watchlist" in user_lower or "my list" in user_lower or "saved movies" in user_lower:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 2}))
            return AgentChatResponse(
                success=True,
                reply="Taking you straight to your Watchlist! Here you can find all your saved titles.",
                actions=actions,
                suggestedPrompts=["What should I watch next?", "Search sci-fi movies", "Go back to Home"]
            )

        if "live tv" in user_lower or "channels" in user_lower or "broadcast" in user_lower:
            actions.append(ActionCommand(type="NAVIGATE_TAB", payload={"index": 3}))
            return AgentChatResponse(
                success=True,
                reply="Navigating to Live TV channels. Sit back and enjoy the stream!",
                actions=actions,
                suggestedPrompts=["Find news channels", "Recommend movies", "Go to Home"]
            )

        if "interstellar" in user_lower:
            actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": 157336, "title": "Interstellar"}))
            return AgentChatResponse(
                success=True,
                reply="🚀 **Interstellar (2014)**\nDirected by Christopher Nolan, Interstellar follows a team of explorers traveling through a wormhole in space to ensure humanity's survival. Starring Matthew McConaughey & Anne Hathaway.",
                actions=actions,
                suggestedPrompts=["Show similar sci-fi movies", "Who is Christopher Nolan?", "Add to Watchlist"]
            )

        if "inception" in user_lower:
            actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": 27205, "title": "Inception"}))
            return AgentChatResponse(
                success=True,
                reply="🌀 **Inception (2010)**\nA thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
                actions=actions,
                suggestedPrompts=["Who directed Inception?", "Show action movies", "Go to Watchlist"]
            )

        # 2. Try Google GenAI SDK (ADK) if GEMINI_API_KEY is available
        if settings.GEMINI_API_KEY:
            try:
                from google import genai
                from google.genai import types

                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                
                prompt = f"{SYSTEM_INSTRUCTION}\nUser query: {user_message}\nCurrent screen: {req.currentScreen or 'Home'}"
                
                response = client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt
                )
                
                if response and response.text:
                    reply_text = response.text
                    
                    # Search movie trigger if user asked for recommendations
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
            except Exception as e:
                logger.warning(f"Google GenAI SDK call failed: {e}. Falling back to TMDB-assisted agent response.")

        # 3. Dynamic TMDB Search & Intelligent Concierge Fallback
        search_results = await TMDBService.search_movies(user_message)
        if search_results and len(search_results) > 0:
            top_movie = search_results[0]
            actions.append(ActionCommand(type="OPEN_MOVIE", payload={"movieId": top_movie.id, "title": top_movie.title}))
            
            movie_list_str = "\n".join([f"• **{m.title}** ({m.releaseDate[:4] if m.releaseDate else 'N/A'}) - ⭐ {m.voteAverage}/10" for m in search_results[:3]])
            reply = f"Here are top cinema picks for your query **\"{user_message}\"**:\n\n{movie_list_str}\n\nClick below to start watching **{top_movie.title}**!"
            
            return AgentChatResponse(
                success=True,
                reply=reply,
                actions=actions,
                suggestedPrompts=suggested_prompts
            )

        # Standard Concierge Response
        return AgentChatResponse(
            success=True,
            reply=f"🍿 I'm your Pure Cinema AI Agent! I can help you find blockbusters, navigate to your watchlist, or answer film trivia. Try searching for genres like 'Sci-Fi', 'Action', or 'Nolan films'!",
            actions=[],
            suggestedPrompts=suggested_prompts
        )
