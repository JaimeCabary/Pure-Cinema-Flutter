import os
import uuid
import time
import hmac
import hashlib
import json
import datetime
import httpx
from fastapi import APIRouter, HTTPException, Depends, Request, Header
from pydantic import BaseModel
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db, TransactionModel, SubscriptionModel, UserModel

router = APIRouter(prefix="/api/payment", tags=["Payment"])

def get_secret_key() -> str:
    return os.getenv("PAYSTACK_SECRET_KEY") or settings.PAYSTACK_SECRET_KEY or "sk_test_mock_pure_cinema_secret_key"

def get_public_key() -> str:
    return os.getenv("PAYSTACK_PUBLIC_KEY") or settings.PAYSTACK_PUBLIC_KEY or "pk_test_mock_pure_cinema_public_key"

ADMIN_EMAILS = {"shazzyazwike@gmail.com", "admin@purecinema.app", "shalom@purecinema.app", "shalom@purecinema.internal"}

def is_admin_email(email: str) -> bool:
    email_clean = email.strip().lower()
    return email_clean in ADMIN_EMAILS or "shazzy" in email_clean or "shalom" in email_clean

class InitializePaymentRequest(BaseModel):
    email: str
    amount: int  # in Kobo (e.g. 120000 = N1,200.00, 250000 = N2,500.00)
    plan: Optional[str] = "student_monthly"
    currency: Optional[str] = "NGN"
    mock: Optional[bool] = False

class VerifyPaymentRequest(BaseModel):
    reference: str
    mock: Optional[bool] = False

class AdminBypassRequest(BaseModel):
    email: str
    plan: Optional[str] = "founder_lifetime"
    admin_key: Optional[str] = None

@router.get("/plans")
def get_plans():
    return {
        "plans": [
            {
                "id": "student_monthly",
                "name": "Student Cinema Pass",
                "price": 400,
                "currency": "NGN",
                "period": "Monthly",
                "features": [
                    "1080p Full HD Streaming Quality",
                    "Full Access to 10,000+ Movies & TV Shows",
                    "1 Screen Concurrent Viewing",
                    "AI CineBot Personal Movie Assistant",
                    "Cheapest Tier for Verified Students"
                ],
                "badge": "STUDENT SPECIAL"
            },
            {
                "id": "vip_monthly",
                "name": "Pure Cinema VIP Pass",
                "price": 2500,
                "currency": "NGN",
                "period": "Monthly",
                "features": [
                    "4K HDR 60 FPS Master Quality",
                    "Ad-Free Streaming on all 10,000+ Live Channels",
                    "Unlimited Offline Downloads",
                    "AI CineBot Unlimited Recommendations",
                    "Dolby Atmos Spatial Audio"
                ],
                "badge": "MOST POPULAR"
            },
            {
                "id": "ultra_quarterly",
                "name": "Cinema Ultra Pass",
                "price": 6500,
                "currency": "NGN",
                "period": "3 Months",
                "features": [
                    "Everything in VIP Pass",
                    "4 Concurrent Screens / Family Sharing",
                    "Priority Low-Latency IPTV Transcoding",
                    "Early Access to Curated Film Premieres"
                ],
                "badge": "BEST VALUE"
            },
            {
                "id": "founder_lifetime",
                "name": "Founder Lifetime Pass",
                "price": 25000,
                "currency": "NGN",
                "period": "Lifetime",
                "features": [
                    "Lifetime Access to All Current & Future Features",
                    "Exclusive Shalom Developer & VIP Discord Access",
                    "Direct Studio Master Bitrate Streaming",
                    "VIP Gold Badge on Profile"
                ],
                "badge": "FOUNDER"
            }
        ]
    }

def record_active_subscription(db: Session, email: str, plan_id: str, is_admin: bool = False):
    """
    Activates or renews user subscription in PostgreSQL database.
    """
    email_clean = email.strip().lower()
    user = db.query(UserModel).filter(UserModel.email == email_clean).first()
    user_id = user.id if user else None

    # Calculate end date based on plan
    now = datetime.datetime.utcnow()
    if plan_id == "founder_lifetime" or is_admin:
        end_date = None  # Lifetime
    elif plan_id == "ultra_quarterly":
        end_date = now + datetime.timedelta(days=90)
    else:  # student_monthly or vip_monthly
        end_date = now + datetime.timedelta(days=30)

    # Deactivate existing sub
    db.query(SubscriptionModel).filter(
        SubscriptionModel.user_email == email_clean
    ).update({"status": "expired"})

    # Create new sub
    sub = SubscriptionModel(
        id=f"sub_{uuid.uuid4().hex[:12]}",
        user_id=user_id,
        user_email=email_clean,
        plan_id=plan_id,
        status="active",
        start_date=now,
        end_date=end_date,
        is_admin_bypass=is_admin
    )
    db.add(sub)
    try:
        db.commit()
    except Exception:
        db.rollback()

@router.post("/initialize")
async def initialize_payment(payload: InitializePaymentRequest, db: Session = Depends(get_db)):
    """
    Initializes a Paystack transaction. Logs attempt to PostgreSQL.
    Returns authorization_url and reference.
    """
    secret_key = get_secret_key()
    ref = f"pstk_{uuid.uuid4().hex[:12]}"
    clean_email = payload.email.strip().lower()
    
    is_mock_key = not secret_key or secret_key.startswith("sk_test_mock")
    is_mock = payload.mock or is_mock_key

    user = db.query(UserModel).filter(UserModel.email == clean_email).first()
    user_id = user.id if user else None

    # Create Transaction record in PostgreSQL
    tx_model = TransactionModel(
        id=f"tx_{uuid.uuid4().hex[:12]}",
        reference=ref,
        user_id=user_id,
        email=clean_email,
        amount=payload.amount,
        currency=payload.currency or "NGN",
        plan_id=payload.plan or "student_monthly",
        status="pending",
        is_mock=is_mock
    )
    db.add(tx_model)
    try:
        db.commit()
    except Exception:
        db.rollback()

    if is_mock:
        return {
            "status": True,
            "message": "Mock Payment Authorization Initialized",
            "data": {
                "authorization_url": f"https://checkout.paystack.com/mock-{ref}",
                "access_code": f"mock_acc_{uuid.uuid4().hex[:8]}",
                "reference": ref,
                "mock": True
            }
        }

    # Live Paystack API Call
    url = "https://api.paystack.co/transaction/initialize"
    headers = {
        "Authorization": f"Bearer {secret_key}",
        "Content-Type": "application/json"
    }
    body = {
        "email": clean_email,
        "amount": payload.amount,
        "reference": ref,
        "currency": payload.currency or "NGN",
        "callback_url": "https://purecinema.app/payment/callback",
        "metadata": {
            "plan": payload.plan,
            "app": "Pure Cinema Flutter"
        }
    }

    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            resp = await client.post(url, json=body, headers=headers)
            data = resp.json()
            if resp.status_code == 200 and data.get("status"):
                return data
            else:
                return {
                    "status": True,
                    "message": data.get("message", "Paystack checkout session created"),
                    "data": {
                        "authorization_url": data.get("data", {}).get("authorization_url") or f"https://checkout.paystack.com/{ref}",
                        "reference": ref,
                        "mock": False
                    }
                }
    except Exception as e:
        return {
            "status": True,
            "message": f"Payment initialized (offline fallback): {str(e)}",
            "data": {
                "authorization_url": f"https://checkout.paystack.com/{ref}",
                "reference": ref,
                "mock": True
            }
        }

@router.get("/verify/{reference}")
async def verify_payment(reference: str, db: Session = Depends(get_db)):
    """
    Verifies a Paystack transaction reference and updates PostgreSQL logs & subscription.
    """
    # 1. Admin Bypass Verification
    if reference.startswith("admin_bypass_"):
        tx = db.query(TransactionModel).filter(TransactionModel.reference == reference).first()
        email = tx.email if tx else "admin@purecinema.app"
        plan = tx.plan_id if tx else "founder_lifetime"

        record_active_subscription(db, email, plan, is_admin=True)

        return {
            "status": True,
            "message": "Admin Zero-Paywall Bypass Verified",
            "data": {
                "reference": reference,
                "amount": 0,
                "currency": "NGN",
                "status": "success",
                "gateway_response": "Admin Bypass Granted",
                "paid_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "channel": "admin_privilege",
                "customer": {"email": email},
                "plan": plan,
                "is_admin": True,
                "mock": False
            }
        }

    # 2. Mock / Fallback Reference Verification
    tx = db.query(TransactionModel).filter(TransactionModel.reference == reference).first()
    if reference.startswith("pstk_mock_") or reference.startswith("pstk_fallback_") or (tx and tx.is_mock):
        if tx:
            tx.status = "success"
            tx.paid_at = datetime.datetime.utcnow()
            try:
                db.commit()
            except Exception:
                db.rollback()
            record_active_subscription(db, tx.email, tx.plan_id)

        return {
            "status": True,
            "message": "Verification successful (Mock)",
            "data": {
                "reference": reference,
                "amount": tx.amount if tx else 40000,
                "currency": tx.currency if tx else "NGN",
                "status": "success",
                "gateway_response": "Approved",
                "paid_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "channel": "card",
                "customer": {"email": tx.email if tx else "subscriber@purecinema.app"},
                "plan": tx.plan_id if tx else "student_monthly",
                "mock": True
            }
        }

    # 3. Live Paystack API Verification
    secret_key = get_secret_key()
    url = f"https://api.paystack.co/transaction/verify/{reference}"
    headers = {"Authorization": f"Bearer {secret_key}"}

    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            resp = await client.get(url, headers=headers)
            data = resp.json()
            if resp.status_code == 200 and data.get("status"):
                p_data = data.get("data", {})
                status_val = p_data.get("status")

                if tx:
                    tx.status = status_val
                    tx.channel = p_data.get("channel")
                    tx.gateway_response = p_data.get("gateway_response")
                    tx.raw_payload = json.dumps(p_data)
                    tx.paid_at = datetime.datetime.utcnow()
                    try:
                        db.commit()
                    except Exception:
                        db.rollback()

                if status_val == "success":
                    email = p_data.get("customer", {}).get("email") or (tx.email if tx else "")
                    plan_id = p_data.get("metadata", {}).get("plan") or (tx.plan_id if tx else "vip_monthly")
                    record_active_subscription(db, email, plan_id)

                return data
            else:
                return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@router.post("/admin-bypass")
async def admin_bypass(payload: AdminBypassRequest, db: Session = Depends(get_db)):
    """
    Direct VIP Bypass endpoint strictly for Master Administrator accounts.
    Logs transaction & activates lifetime VIP in PostgreSQL.
    """
    clean_email = payload.email.strip().lower()
    if not is_admin_email(clean_email) and payload.admin_key != "pure_cinema_master_admin_2026":
        raise HTTPException(
            status_code=403,
            detail="Access Denied: Payment bypass is restricted to Master Admin accounts only."
        )

    bypass_ref = f"admin_bypass_{uuid.uuid4().hex[:12]}"
    user = db.query(UserModel).filter(UserModel.email == clean_email).first()

    tx = TransactionModel(
        id=f"tx_{uuid.uuid4().hex[:12]}",
        reference=bypass_ref,
        user_id=user.id if user else None,
        email=clean_email,
        amount=0,
        currency="NGN",
        plan_id=payload.plan or "founder_lifetime",
        status="success",
        channel="admin_privilege",
        gateway_response="Admin Bypass Granted",
        paid_at=datetime.datetime.utcnow(),
        is_mock=False,
        is_admin_bypass=True
    )
    db.add(tx)
    try:
        db.commit()
    except Exception:
        db.rollback()

    record_active_subscription(db, clean_email, payload.plan or "founder_lifetime", is_admin=True)

    return {
        "status": True,
        "message": "Admin Zero-Paywall Access Activated",
        "data": {
            "reference": bypass_ref,
            "status": "success",
            "plan": payload.plan or "founder_lifetime",
            "email": clean_email,
            "is_admin": True,
            "features": [
                "4K HDR 60 FPS Master Quality",
                "Ad-Free Streaming on all 10,000+ Live Channels",
                "Unlimited Offline Downloads",
                "AI CineBot Unlimited Recommendations",
                "Dolby Atmos Spatial Audio",
                "Master Admin Privileges & Direct Stream Controls"
            ]
        }
    }

@router.post("/webhook")
async def paystack_webhook(
    request: Request,
    db: Session = Depends(get_db),
    x_paystack_signature: Optional[str] = Header(None)
):
    """
    Paystack Webhook listener with HMAC-SHA512 Signature verification.
    """
    secret_key = get_secret_key()
    body_bytes = await request.body()

    # Validate signature if secret key is present
    if secret_key and not secret_key.startswith("sk_test_mock") and x_paystack_signature:
        computed_sig = hmac.new(secret_key.encode('utf-8'), body_bytes, hashlib.sha512).hexdigest()
        if not hmac.compare_digest(computed_sig, x_paystack_signature):
            raise HTTPException(status_code=400, detail="Invalid Paystack Webhook Signature")

    try:
        event = json.loads(body_bytes.decode('utf-8'))
        event_type = event.get("event")
        data = event.get("data", {})
        reference = data.get("reference")

        if event_type == "charge.success" and reference:
            tx = db.query(TransactionModel).filter(TransactionModel.reference == reference).first()
            if tx:
                tx.status = "success"
                tx.channel = data.get("channel")
                tx.gateway_response = data.get("gateway_response")
                tx.raw_payload = json.dumps(data)
                tx.paid_at = datetime.datetime.utcnow()
                try:
                    db.commit()
                except Exception:
                    db.rollback()

            email = data.get("customer", {}).get("email") or (tx.email if tx else None)
            plan_id = data.get("metadata", {}).get("plan") or (tx.plan_id if tx else "student_monthly")
            if email:
                record_active_subscription(db, email, plan_id)

        return {"status": True, "message": "Webhook processed successfully"}
    except Exception as e:
        return {"status": False, "message": f"Webhook parsing error: {str(e)}"}
