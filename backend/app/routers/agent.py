from fastapi import APIRouter
from typing import List
from app.models.schemas import AgentChatRequest, AgentChatResponse
from app.services.agent_service import AgentService

router = APIRouter(prefix="/api/agent", tags=["In-App AI Agent"])

@router.post("/chat", response_model=AgentChatResponse)
async def agent_chat(req: AgentChatRequest):
    return await AgentService.process_chat(req)

@router.get("/suggestions", response_model=List[str])
def get_suggestions():
    return [
        "Recommend a mind-bending sci-fi movie",
        "Take me to Live TV",
        "What's in my watchlist?",
        "Find movies with Christopher Nolan"
    ]
