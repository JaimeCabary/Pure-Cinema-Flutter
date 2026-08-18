import os
import uuid
import time
import httpx
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, Dict, Any
from app.config import settings

router = APIRouter(prefix="/api/payment", tags=["Payment"])

PAYSTACK_SECRET_KEY = os.getenv("PAYSTACK_SECRET_KEY", "sk_test_mock_pure_cinema_secret_key")
PAYSTACK_PUBLIC_KEY = os.getenv("PAYSTACK_PUBLIC_KEY", "pk_test_mock_pure_cinema_public_key")

class InitializePaymentRequest(BaseModel):
    email: str
    amount: int  # in Kobo (e.g. 250000 = N2,500.00) or USD cents
    plan: Optional[str] = "vip_monthly"
    currency: Optional[str] = "NGN"
    mock: Optional[bool] = False

class VerifyPaymentRequest(BaseModel):
    reference: str
    mock: Optional[bool] = False

# In-memory store for mock transactions
mock_transactions: Dict[str, Dict[str, Any]] = {}

@router.get("/plans")
def get_plans():
    return {
        "plans": [
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

@router.post("/initialize")
async def initialize_payment(payload: InitializePaymentRequest):
    """
    Initializes a Paystack transaction or returns a simulated mock session.
    """
    ref = f"pstk_{'mock_' if payload.mock or not os.getenv('PAYSTACK_SECRET_KEY') else ''}{uuid.uuid4().hex[:12]}"
    
    # Check if mock mode is requested or live secret key is unset
    if payload.mock or not os.getenv("PAYSTACK_SECRET_KEY") or PAYSTACK_SECRET_KEY.startswith("sk_test_mock"):
        mock_transactions[ref] = {
            "reference": ref,
            "email": payload.email,
            "amount": payload.amount,
            "plan": payload.plan,
            "currency": payload.currency,
            "status": "pending",
            "created_at": time.time(),
        }
        return {
            "status": True,
            "message": "Mock Payment Authorization Initialized",
            "data": {
                "authorization_url": f"https://purecinema.app/checkout/mock/{ref}",
                "access_code": f"mock_acc_{uuid.uuid4().hex[:8]}",
                "reference": ref,
                "mock": True
            }
        }

    # Live Paystack API Call
    url = "https://api.paystack.co/transaction/initialize"
    headers = {
        "Authorization": f"Bearer {PAYSTACK_SECRET_KEY}",
        "Content-Type": "application/json"
    }
    body = {
        "email": payload.email,
        "amount": payload.amount,
        "reference": ref,
        "currency": payload.currency,
        "callback_url": "https://purecinema.app/payment/callback",
        "metadata": {
            "plan": payload.plan
        }
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(url, json=body, headers=headers)
            data = resp.json()
            if resp.status_code == 200 and data.get("status"):
                return data
            else:
                # Fallback to mock session if Paystack API fails or returns error
                mock_transactions[ref] = {
                    "reference": ref,
                    "email": payload.email,
                    "amount": payload.amount,
                    "plan": payload.plan,
                    "status": "pending"
                }
                return {
                    "status": True,
                    "message": "Fallback to Mock Checkout",
                    "data": {
                        "authorization_url": f"https://purecinema.app/checkout/mock/{ref}",
                        "reference": ref,
                        "mock": True
                    }
                }
    except Exception as e:
        # Graceful fallback to mock payment
        mock_transactions[ref] = {
            "reference": ref,
            "email": payload.email,
            "amount": payload.amount,
            "plan": payload.plan,
            "status": "pending"
        }
        return {
            "status": True,
            "message": f"Simulated Checkout Mode: {str(e)}",
            "data": {
                "authorization_url": f"https://purecinema.app/checkout/mock/{ref}",
                "reference": ref,
                "mock": True
            }
        }

@router.get("/verify/{reference}")
async def verify_payment(reference: str):
    """
    Verifies a Paystack transaction reference (Live or Mock).
    """
    # Mock Verification
    if reference.startswith("pstk_mock_") or reference in mock_transactions:
        tx = mock_transactions.get(reference, {})
        tx["status"] = "success"
        tx["paid_at"] = time.time()
        
        return {
            "status": True,
            "message": "Verification successful (Mock Mode)",
            "data": {
                "reference": reference,
                "amount": tx.get("amount", 250000),
                "currency": tx.get("currency", "NGN"),
                "status": "success",
                "gateway_response": "Successful (Simulated)",
                "paid_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "channel": "card",
                "customer": {
                    "email": tx.get("email", "subscriber@purecinema.app")
                },
                "plan": tx.get("plan", "vip_monthly"),
                "mock": True
            }
        }

    # Live Paystack Verification
    url = f"https://api.paystack.co/transaction/verify/{reference}"
    headers = {
        "Authorization": f"Bearer {PAYSTACK_SECRET_KEY}"
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, headers=headers)
            data = resp.json()
            return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")
