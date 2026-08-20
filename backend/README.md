# 🎬 Pure Cinema FastAPI Backend Microservice

High-performance, fault-tolerant asynchronous **FastAPI** backend service for Pure Cinema. Powered by **SQLAlchemy ORM** (PostgreSQL / SQLite), **Paystack Gateway Integration**, **Google SMTP Email Dispatch**, **Google Gemini AI CineBot Rotator**, and **Internet Archive Public Domain Engine**.

---

## 🛠️ Key Capabilities

- **PostgreSQL ORM Persistence** ([`app/database.py`](app/database.py)):
  - Models for `UserModel`, `SubscriptionModel`, `TransactionModel`, and `WatchlistItemModel`.
  - Automatic connection pooling and graceful SQLite fallback if cloud database is offline.
- **Production Paystack Gateway** ([`app/routers/payment.py`](app/routers/payment.py)):
  - 4 Subscription Tiers (Student Pass @ ₦400/mo, VIP Pass @ ₦2,500/mo, Ultra Pass @ ₦6,500/3mo, Founder Lifetime @ ₦25,000).
  - HMAC SHA512 signature validation on Paystack webhooks (`x-paystack-signature`).
  - Transaction and subscription audit logging in PostgreSQL.
- **Google SMTP OTP Authentication** ([`app/services/email_service.py`](app/services/email_service.py)):
  - Dispatches cryptographically random 6-digit verification codes via `smtp.gmail.com:587` TLS.
- **Institutional Student Auto-Verification**:
  - Automatic student domain detection (`.edu`, `.edu.ng`, `.ac.uk`, `.sch.ng`, `.edu.gh`, `.edu.za`).
- **Multi-Worker Fault Tolerance** ([`run.py`](run.py)):
  - Runs with Uvicorn process clustering (`--workers 4`). Worker crashes are re-spawned in milliseconds without dropping connections.
- **Public Domain Cinema Engine** ([`app/services/public_domain_service.py`](app/services/public_domain_service.py)):
  - Serves verified open movies (*Big Buck Bunny*, *Tears of Steel*, *Sintel*) and queries Internet Archive's database live.

---

## ⚡ Quick Start

```powershell
# Fast run using UV (Recommended)
uv run python run.py

# Interactive Swagger Documentation
# http://localhost:3000/docs
```

---

## 🔑 Environment Variables (`.env`)

```env
PORT=3000
HOST=0.0.0.0

DATABASE_URL=postgresql://user:password@host:5432/postgres
PAYSTACK_SECRET_KEY=sk_test_...
PAYSTACK_PUBLIC_KEY=pk_test_...

SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_16_char_app_password

JWT_SECRET=your_signing_secret
GEMINI_API_KEY=your_gemini_api_key
TMDB_API_KEY=your_tmdb_api_key
```
