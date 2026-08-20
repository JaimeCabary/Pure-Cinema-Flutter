import os
import uuid
import datetime

from sqlalchemy import (
    create_engine, Column, String, Integer, Boolean, DateTime, Text, ForeignKey
)
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from app.config import settings

Base = declarative_base()

class UserModel(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: f"usr_{uuid.uuid4().hex[:12]}")
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="USER", nullable=False) # USER or ADMIN
    avatar = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class SubscriptionModel(Base):
    __tablename__ = "subscriptions"

    id = Column(String, primary_key=True, default=lambda: f"sub_{uuid.uuid4().hex[:12]}")
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=True)
    user_email = Column(String, index=True, nullable=False)
    plan_id = Column(String, nullable=False) # student_monthly, vip_monthly, ultra_quarterly, founder_lifetime
    status = Column(String, default="active", nullable=False) # active, expired, cancelled
    start_date = Column(DateTime, default=datetime.datetime.utcnow)
    end_date = Column(DateTime, nullable=True)
    is_admin_bypass = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class TransactionModel(Base):
    __tablename__ = "transactions"

    id = Column(String, primary_key=True, default=lambda: f"tx_{uuid.uuid4().hex[:12]}")
    reference = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=True)
    email = Column(String, index=True, nullable=False)
    amount = Column(Integer, nullable=False) # in kobo or smallest currency unit
    currency = Column(String, default="NGN", nullable=False)
    plan_id = Column(String, nullable=False)
    status = Column(String, default="pending", nullable=False) # pending, success, failed
    channel = Column(String, nullable=True)
    gateway_response = Column(String, nullable=True)
    paid_at = Column(DateTime, nullable=True)
    raw_payload = Column(Text, nullable=True)
    is_mock = Column(Boolean, default=False)
    is_admin_bypass = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class WatchlistItemModel(Base):
    __tablename__ = "watchlist_items"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String, index=True, nullable=False)
    movie_id = Column(Integer, index=True, nullable=False)
    title = Column(String, nullable=False)
    poster_path = Column(String, nullable=True)
    media_type = Column(String, default="movie", nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

# Engine initialization with fallback mechanism
db_url = settings.get_sqlalchemy_database_url()

def get_engine():
    """
    Attempts to build PostgreSQL engine. If connection fails, falls back to SQLite.
    """
    try:
        if "postgresql" in db_url:
            eng = create_engine(
                db_url,
                pool_pre_ping=True,
                pool_size=10,
                max_overflow=20,
                connect_args={"connect_timeout": 5}
            )
            # Test quick connect
            with eng.connect() as conn:
                pass
            print("Successfully connected to PostgreSQL database (Supabase).")
            return eng
    except Exception as e:
        print(f"Warning: Primary PostgreSQL connection failed ({e}). Falling back to SQLite.")

    # SQLite Fallback Engine
    fallback_url = "sqlite:///./pure_cinema.db"
    eng = create_engine(fallback_url, connect_args={"check_same_thread": False})
    print(f"Using SQLite database engine at {fallback_url}.")
    return eng

engine = get_engine()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """
    Creates database tables if they do not exist.
    Seed default admin users if database is empty.
    """
    Base.metadata.create_all(bind=engine)
    print("PostgreSQL/SQLite database tables initialized successfully.")
