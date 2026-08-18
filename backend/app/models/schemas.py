from typing import List, Optional, Any, Dict
from pydantic import BaseModel, EmailStr, Field

# --- Auth Schemas ---
class UserLoginRequest(BaseModel):
    email: str
    password: str

class UserRegisterRequest(BaseModel):
    name: str
    email: str
    password: str

class SendOtpRequest(BaseModel):
    email: str
    purpose: Optional[str] = "login"

class VerifyOtpRequest(BaseModel):
    email: str
    code: str
    purpose: Optional[str] = "login"
    name: Optional[str] = None

class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    newPassword: str

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    avatar: Optional[str] = None
    role: str = "USER"

class AuthResponse(BaseModel):
    success: bool
    user: Optional[UserResponse] = None
    token: Optional[str] = None
    message: Optional[str] = None
    error: Optional[str] = None
    devCode: Optional[str] = None

# --- Movie Schemas ---
class MovieSchema(BaseModel):
    id: int
    title: str
    overview: str
    posterPath: Optional[str] = None
    backdropPath: Optional[str] = None
    releaseDate: Optional[str] = None
    voteAverage: float = 0.0

class CastMemberSchema(BaseModel):
    id: int
    name: str
    character: str
    profilePath: Optional[str] = None

# --- Watchlist & History Schemas ---
class WatchlistAddRequest(BaseModel):
    movie: MovieSchema

class HistorySaveRequest(BaseModel):
    movieId: int
    position: int
    duration: int

# --- In-App Agent Schemas ---
class ChatMessage(BaseModel):
    role: str  # "user" | "assistant" | "system"
    content: str

class ActionCommand(BaseModel):
    type: str  # e.g. "OPEN_MOVIE", "SEARCH_MOVIE", "NAVIGATE_TAB", "SHOW_TRAILER"
    payload: Dict[str, Any] = {}

class AgentChatRequest(BaseModel):
    message: str
    history: List[ChatMessage] = []
    currentScreen: Optional[str] = None
    currentMovieId: Optional[int] = None
    userId: Optional[str] = None

class AgentChatResponse(BaseModel):
    success: bool
    reply: str
    actions: List[ActionCommand] = []
    suggestedPrompts: List[str] = []
    error: Optional[str] = None
