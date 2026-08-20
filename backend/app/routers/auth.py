import jwt
from fastapi import APIRouter, HTTPException, status, Depends, Header
from sqlalchemy.orm import Session
from typing import Optional

from app.config import settings
from app.database import get_db, UserModel, SubscriptionModel
from app.models.schemas import (
    UserLoginRequest,
    UserRegisterRequest,
    SendOtpRequest,
    VerifyOtpRequest,
    ResetPasswordRequest,
    AuthResponse,
    UserResponse
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

def get_current_user(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> UserModel:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header required"
        )
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
        user_id = payload.get("sub")
        email = payload.get("email")
        if not user_id and not email:
            raise HTTPException(status_code=401, detail="Invalid token payload")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token validation failed: {str(e)}")

    user = db.query(UserModel).filter(
        (UserModel.id == user_id) | (UserModel.email == email)
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="User account not found")

    return user

@router.post("/mobile/login", response_model=AuthResponse)
def login(req: UserLoginRequest, db: Session = Depends(get_db)):
    res = AuthService.login(db, req.email, req.password)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=res.error)
    return res

@router.post("/mobile/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest, db: Session = Depends(get_db)):
    res = AuthService.register(db, req.name, req.email, req.password)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=res.error)
    return res

@router.post("/send-otp", response_model=AuthResponse)
async def send_otp(req: SendOtpRequest):
    return await AuthService.send_otp(req.email, req.purpose or "login")

@router.post("/verify-otp", response_model=AuthResponse)
def verify_otp(req: VerifyOtpRequest, db: Session = Depends(get_db)):
    res = AuthService.verify_otp(db, req.email, req.code, req.purpose or "login", req.name)
    if not res.success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=res.error)
    return res

@router.post("/reset-password", response_model=AuthResponse)
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    return AuthService.reset_password(db, req.email, req.code, req.newPassword)

@router.get("/me")
def get_user_profile(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    sub = db.query(SubscriptionModel).filter(
        SubscriptionModel.user_email == current_user.email,
        SubscriptionModel.status == "active"
    ).first()

    return {
        "user": UserResponse(
            id=current_user.id,
            email=current_user.email,
            name=current_user.name,
            avatar=current_user.avatar,
            role=current_user.role
        ),
        "has_active_subscription": sub is not None or current_user.role == "ADMIN",
        "subscription": {
            "plan_id": sub.plan_id if sub else ("founder_lifetime" if current_user.role == "ADMIN" else "free"),
            "status": sub.status if sub else ("active" if current_user.role == "ADMIN" else "none"),
            "is_admin_bypass": sub.is_admin_bypass if sub else (current_user.role == "ADMIN")
        }
    }
