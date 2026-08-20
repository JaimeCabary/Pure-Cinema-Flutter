from fastapi import APIRouter, HTTPException, status
from app.models.schemas import (
    UserLoginRequest,
    UserRegisterRequest,
    SendOtpRequest,
    VerifyOtpRequest,
    ResetPasswordRequest,
    AuthResponse
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/mobile/login", response_model=AuthResponse)
def login(req: UserLoginRequest):
    res = AuthService.login(req.email, req.password)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=res.error)
    return res

@router.post("/mobile/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest):
    res = AuthService.register(req.name, req.email, req.password)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=res.error)
    return res

@router.post("/send-otp", response_model=AuthResponse)
async def send_otp(req: SendOtpRequest):
    return await AuthService.send_otp(req.email, req.purpose or "login")

@router.post("/verify-otp", response_model=AuthResponse)
def verify_otp(req: VerifyOtpRequest):
    res = AuthService.verify_otp(req.email, req.code, req.purpose or "login", req.name)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=res.error)
    return res

@router.post("/reset-password", response_model=AuthResponse)
def reset_password(req: ResetPasswordRequest):
    return AuthService.reset_password(req.email, req.code, req.newPassword)
