import jwt
import random
import datetime
import bcrypt
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.config import settings
from app.database import UserModel, SessionLocal
from app.models.schemas import UserResponse, AuthResponse
from app.services.email_service import EmailService

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        # Check standard bcrypt hash
        if hashed_password.startswith("$2b$") or hashed_password.startswith("$2a$"):
            return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
        # Fallback for plain text legacy passwords during transition
        return plain_password == hashed_password
    except Exception:
        return plain_password == hashed_password

def get_password_hash(password: str) -> str:
    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode("utf-8")

def is_admin_email(email: str) -> bool:
    clean = email.strip().lower()
    return "shazzyazwike@gmail.com" in clean or "shalom" in clean or "shazzy" in clean

def is_student_email(email: str) -> bool:
    clean = email.strip().lower()
    student_domains = (".edu", ".edu.ng", ".ac.uk", ".sch.ng", ".edu.gh", ".edu.za", ".stu.")
    return any(clean.endswith(domain) or f"{domain}" in clean for domain in student_domains)

# Active in-memory store for 6-digit OTP verification codes
OTP_DB: Dict[str, str] = {}

def create_jwt_token(user_id: str, email: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=30)
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")

def seed_default_users(db: Session):
    """
    Ensures default admin & demo user accounts exist in the database.
    """
    default_accounts = [
        {
            "id": "admin-shazzy-id",
            "email": "shazzyazwike@gmail.com",
            "name": "Shazzy (Admin)",
            "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&q=80",
            "role": "ADMIN",
            "password": "password123"
        },
        {
            "id": "admin-shalom-id",
            "email": "shalom@purecinema.internal",
            "name": "Shalom (Admin)",
            "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&q=80",
            "role": "ADMIN",
            "password": "password123"
        },
        {
            "id": "demo-user-id",
            "email": "demo@purecinema.internal",
            "name": "VIP Guest",
            "avatar": None,
            "role": "USER",
            "password": "demopassword"
        }
    ]

    for acc in default_accounts:
        existing = db.query(UserModel).filter(UserModel.email == acc["email"]).first()
        if not existing:
            hashed_pwd = get_password_hash(acc["password"])
            user = UserModel(
                id=acc["id"],
                email=acc["email"],
                name=acc["name"],
                hashed_password=hashed_pwd,
                role=acc["role"],
                avatar=acc["avatar"]
            )
            db.add(user)
    try:
        db.commit()
    except Exception:
        db.rollback()

class AuthService:
    @staticmethod
    def login(db: Session, email: str, password: str) -> AuthResponse:
        clean_email = email.strip().lower()

        # Seed defaults if needed
        seed_default_users(db)

        user_record = db.query(UserModel).filter(UserModel.email == clean_email).first()
        if not user_record:
            return AuthResponse(
                success=False,
                error="Account not found"
            )

        if not verify_password(password, user_record.hashed_password):
            return AuthResponse(
                success=False,
                error="Incorrect password. Please verify your credentials."
            )

        user = UserResponse(
            id=user_record.id,
            email=user_record.email,
            name=user_record.name,
            avatar=user_record.avatar,
            role=user_record.role
        )
        token = create_jwt_token(user.id, user.email, user.role)
        return AuthResponse(success=True, user=user, token=token, message="Signed in successfully")

    @staticmethod
    def register(db: Session, name: str, email: str, password: str) -> AuthResponse:
        clean_email = email.strip().lower()
        seed_default_users(db)

        existing = db.query(UserModel).filter(UserModel.email == clean_email).first()
        if existing:
            return AuthResponse(
                success=False,
                error="An account already exists with this email address. Please log in."
            )

        user_id = f"usr_{abs(hash(clean_email))}"
        clean_name = name.strip() if name.strip() else clean_email.split("@")[0].capitalize()
        role = "ADMIN" if is_admin_email(clean_email) else "USER"
        hashed_pwd = get_password_hash(password)

        user_model = UserModel(
            id=user_id,
            email=clean_email,
            name=clean_name,
            hashed_password=hashed_pwd,
            role=role
        )
        db.add(user_model)
        try:
            db.commit()
            db.refresh(user_model)
        except Exception as e:
            db.rollback()
            return AuthResponse(success=False, error=f"Database error during registration: {str(e)}")

        user = UserResponse(id=user_model.id, email=user_model.email, name=user_model.name, role=user_model.role)
        token = create_jwt_token(user.id, user.email, user.role)
        return AuthResponse(success=True, user=user, token=token, message="Account created successfully")

    @staticmethod
    async def send_otp(email: str, purpose: str = "login") -> AuthResponse:
        clean_email = email.strip().lower()
        random_code = str(random.randint(100000, 999999))
        OTP_DB[clean_email] = random_code
        
        try:
            await EmailService.send_otp_email(clean_email, random_code, purpose=purpose)
        except Exception as e:
            print(f"Error dispatching OTP email: {e}")

        return AuthResponse(
            success=True,
            message=f"Verification code sent to {clean_email}"
        )

    @staticmethod
    def verify_otp(db: Session, email: str, code: str, purpose: str = "login", name: Optional[str] = None) -> AuthResponse:
        clean_email = email.strip().lower()
        clean_code = code.strip()

        seed_default_users(db)

        valid_otp = OTP_DB.get(clean_email)
        if valid_otp and clean_code == valid_otp:
            # Clear used OTP
            OTP_DB.pop(clean_email, None)
            user_record = db.query(UserModel).filter(UserModel.email == clean_email).first()
            if not user_record:
                user_id = f"usr_{abs(hash(clean_email))}"
                role = "ADMIN" if is_admin_email(clean_email) else "USER"
                user_name = name.strip() if (name and name.strip()) else clean_email.split("@")[0].capitalize()
                hashed_pwd = get_password_hash("otppassword123")

                user_record = UserModel(
                    id=user_id,
                    email=clean_email,
                    name=user_name,
                    hashed_password=hashed_pwd,
                    role=role
                )
                db.add(user_record)
                try:
                    db.commit()
                    db.refresh(user_record)
                except Exception:
                    db.rollback()

            user = UserResponse(
                id=user_record.id,
                email=user_record.email,
                name=user_record.name,
                avatar=user_record.avatar,
                role=user_record.role
            )
            token = create_jwt_token(user.id, user.email, user.role)
            return AuthResponse(success=True, user=user, token=token)

        return AuthResponse(success=False, error="Invalid verification code")

    @staticmethod
    def reset_password(db: Session, email: str, code: str, new_password: str) -> AuthResponse:
        clean_email = email.strip().lower()
        user_record = db.query(UserModel).filter(UserModel.email == clean_email).first()
        if user_record:
            user_record.hashed_password = get_password_hash(new_password)
            try:
                db.commit()
            except Exception:
                db.rollback()
        return AuthResponse(success=True, message="Password updated successfully")
