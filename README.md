<div align="center">

# 🎬 PURE CINEMA
### *Uncompromised 4K Cinema Streaming · 10,000+ Worldwide Live TV · AI CineBot Concierge*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Google GenAI](https://img.shields.io/badge/Google_GenAI-ADK_Rotator-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://aistudio.google.com)
[![Paystack](https://img.shields.io/badge/Paystack-VIP_Pass-0BA4DB?style=for-the-badge&logo=paystack&logoColor=white)](https://paystack.com)
[![Render](https://img.shields.io/badge/Render-Live_Deploy-46E3B7?style=for-the-badge&logo=render&logoColor=white)](https://render.com)
[![License](https://img.shields.io/badge/License-MIT-E50914?style=for-the-badge)](LICENSE)

<br/>

**Pure Cinema** is a state-of-the-art cross-platform streaming platform built with **Flutter** (Web, iOS, Android, Desktop) and a high-performance **FastAPI** backend. It blends ultra-high-definition cinema streaming, 10,000+ international live television channels, a silicon brushed titanium AI assistant powered by Google GenAI ADK, and seamless VIP subscription monetization.

---

</div>

## 🌟 Highlights & Features

### 🎞️ 1. Ultra HD 4K Cinema & Auto-Playing Trailers
- **Non-Seeking Half-Screen Player**: Expanded half-screen cinema overview that auto-plays HD trailers with audio toggles, expand-to-fullscreen capabilities, and touch-friendly controls.
- **Smart Recommendations & Best Picks**: Curated "Best Picks" legal streaming catalog powered by TMDB metadata, high-resolution backdrops, and cast filmographies.
- **Instant Resume & Playback History**: Client-side storage tracks watched seconds, durations, and auto-generates "Continue Watching" rails.

### 📺 2. 10,000+ Worldwide Live TV Channels
- **Global Broadcasts**: 10,000+ 24/7 channels categorized by Movies, News, Sports, Documentaries, Music, Entertainment, and Kids.
- **Authentic National Flags**: Real Unicode country flags (🇺🇸, 🇬🇧, 🇫🇷, 🇩🇪, 🇪🇸, 🇮🇹, 🇯🇵, 🇰🇷, 🇳🇬, 🇧🇷, 🇿🇦, 🇮🇳, 🇦🇺) across channel cards and filter chips.
- **Resilient Multi-Source Streaming**: Native HLS stream parser with chunked VLC proxying on the FastAPI backend for low latency and zero buffer stalls.

### 🤖 3. Silicon Metal AI CineBot (Google GenAI ADK)
- **Multi-Model Rotator & Auto-Failover**: Rotates dynamically across Google GenAI free-tier models (`gemini-2.5-flash`, `gemini-2.0-flash`, `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash-lite`) with instant exception handling if rate limits occur.
- **In-App Action Execution**: The CineBot can autonomously navigate between tabs (`OPEN_MOVIE`, `SEARCH_MOVIE`, `NAVIGATE_TAB`, `ADD_WATCHLIST`) via structured JSON action protocols.
- **Brushed Titanium Industrial Design**: Minimalist Apple/Silicon-inspired floating metal badge with zero annoying green glow.

### 💳 4. Paystack VIP Subscription Gateway & Mock Mode
- **VIP Passes**: Monthly, Quarterly, and Annual VIP passes unlocking 4K Ultra HD streams and exclusive cinema channels.
- **Instant Mock Mode Toggle**: Seamless in-app mock mode switch allowing developers and testers to simulate end-to-end checkout flows with zero live billing.

### 🎨 5. Premium Cinematic Aesthetics
- **S-Core Dream Typography**: Exquisite Korean/Latin modern typographic hierarchy throughout brand headers, titles, and modals.
- **Living Breathing Logo**: Sine-wave breathing scale pulse with dynamic `#E50914` crimson ambient halo.
- **Floating Capsule Dock Navbar**: Floating obsidian glass capsule dock with active white pill button and dark icon glyphs.
- **3-Step Cinematic Onboarding**: Fluid swipeable master onboarding flow leading to dedicated Sign In / Sign Up screens with guest bypass.

---

## 📐 System Design & UML Diagrams

### 1. 🎯 Use Case Diagram
Illustrates interactions between system actors (**Guest User**, **VIP Member**, and **System Administrator**) and core Pure Cinema subsystems.

```mermaid
graph LR
    actorGuest(("👤 Guest User"))
    actorVIP(("⭐ VIP Member"))
    actorAdmin(("👑 System Administrator"))

    subgraph PureCinemaSystem ["🎬 Pure Cinema Ecosystem"]
        UC1(["Browse 4K Cinema & Best Picks"])
        UC2(["Expand Non-Seeking Half-Screen Trailers"])
        UC3(["Stream 10,000+ Worldwide Live IPTV"])
        UC4(["Filter Channels by Country Flags & Genres"])
        UC5(["Chat with Google GenAI CineBot"])
        UC6(["Execute In-App Navigation Commands"])
        UC7(["Upgrade VIP Pass via Paystack"])
        UC8(["Simulate Mock Payments & Receipts"])
        UC9(["Manage Local Watchlist & Resume Progress"])
        UC10(["Access Administrator Portal"])
    end

    actorGuest --> UC1
    actorGuest --> UC2
    actorGuest --> UC3
    actorGuest --> UC4
    actorGuest --> UC5
    actorGuest --> UC7
    actorGuest --> UC8
    actorGuest --> UC9

    actorVIP --> UC1
    actorVIP --> UC2
    actorVIP --> UC3
    actorVIP --> UC5
    actorVIP --> UC6
    actorVIP --> UC9

    actorAdmin --> UC1
    actorAdmin --> UC3
    actorAdmin --> UC5
    actorAdmin --> UC6
    actorAdmin --> UC10
```

---

### 2. 🏛️ Class Diagram (Architecture & Relationships)
Shows structural object-oriented relationships between core data models, client controllers, and service handlers.

```mermaid
classDiagram
    class Movie {
        +int id
        +String title
        +String overview
        +String posterPath
        +String backdropPath
        +String releaseDate
        +double voteAverage
        +String? trailerUrl
        +List~String~ genres
        +List~CastMember~ cast
    }

    class CastMember {
        +int id
        +String name
        +String character
        +String? profilePath
    }

    class LiveChannel {
        +String id
        +String name
        +String logo
        +String group
        +String streamUrl
        +String country
        +String badge
        +String currentProgram
    }

    class User {
        +String id
        +String email
        +String name
        +String? avatar
        +String role
        +bool isVip
    }

    class SubscriptionPlan {
        +String id
        +String name
        +int priceInKobo
        +String currency
        +String period
        +List~String~ features
        +String? badge
    }

    class AgentChatMessage {
        +String role
        +String content
        +List~ActionCommand~ actions
    }

    class ActionCommand {
        +String type
        +Map~String,dynamic~ payload
    }

    class TMDBService {
        +searchMovies(query)
        +getTrending()
        +getMovieCredits(movieId)
    }

    class IPTVService {
        +loadChannels()
        +filterByCountry(country)
        +filterByGenre(genre)
    }

    class AgentService {
        +processChat(request)
        +rotateModel()
    }

    class PaymentService {
        +initializePayment(email, amount)
        +verifyPayment(ref)
    }

    class DatabaseService {
        +getWatchlist()
        +addToWatchlist(movie)
        +saveWatchProgress(id, pos, dur)
    }

    Movie "1" *-- "many" CastMember : features
    User "1" --> "many" Movie : saves in watchlist
    User "1" --> "0..1" SubscriptionPlan : subscribes
    AgentChatMessage "1" *-- "0..*" ActionCommand : triggers
    AgentService ..> AgentChatMessage : generates
    IPTVService ..> LiveChannel : manages
    TMDBService ..> Movie : fetches
    DatabaseService ..> Movie : persists
    PaymentService ..> SubscriptionPlan : processes
```

---

### 3. 🗄️ Entity Relationship Diagram (ERD)
Defines the pure data schema, attributes, and relationships across persistent entities (without behavioral methods).

```mermaid
erDiagram
    USER ||--o{ MOVIE_WATCHLIST : "bookmarks"
    USER ||--o{ PLAYBACK_HISTORY : "tracks"
    USER ||--o| VIP_SUBSCRIPTION : "owns"
    MOVIE ||--o{ MOVIE_WATCHLIST : "contained in"
    MOVIE ||--o{ PLAYBACK_HISTORY : "recorded in"
    MOVIE ||--|{ CAST_MEMBER : "features"
    LIVE_CHANNEL }|--|| REGION_FLAG : "originates from"
    LIVE_CHANNEL }|--|| CHANNEL_GENRE : "belongs to"
    VIP_SUBSCRIPTION }|--|| PAYMENT_TRANSACTION : "verified by"

    USER {
        string id PK
        string email
        string name
        string role
        string avatar_url
        boolean is_vip
        timestamp created_at
    }

    MOVIE {
        int id PK
        string title
        string overview
        string poster_path
        string backdrop_path
        string release_date
        float vote_average
        string trailer_youtube_key
    }

    CAST_MEMBER {
        int id PK
        int movie_id FK
        string actor_name
        string character_role
        string profile_image_url
    }

    MOVIE_WATCHLIST {
        string user_id FK
        int movie_id FK
        timestamp added_at
    }

    PLAYBACK_HISTORY {
        string user_id FK
        int movie_id FK
        int position_seconds
        int duration_seconds
        timestamp last_watched_at
    }

    VIP_SUBSCRIPTION {
        string id PK
        string user_id FK
        string plan_tier
        string status
        timestamp start_date
        timestamp expires_at
    }

    PAYMENT_TRANSACTION {
        string reference PK
        string user_email
        int amount_in_kobo
        string currency
        string payment_gateway
        string transaction_status
        boolean is_mock_test
        timestamp paid_at
    }

    LIVE_CHANNEL {
        string id PK
        string channel_name
        string logo_url
        string stream_url
        string country_code
        string genre_category
        string stream_quality_badge
    }

    REGION_FLAG {
        string country_code PK
        string country_name
        string unicode_flag_emoji
    }

    CHANNEL_GENRE {
        string category_name PK
        string description
    }
```

---

### 4. 🏊 Activity Diagram with Swimlanes
Maps cross-functional workflows across the **User**, **Flutter Client**, **FastAPI Backend**, and **Cloud Providers**.

```mermaid
flowchart TB
    subgraph UserLane ["👤 User / Client"]
        start([Start App]) --> splash[Launch Screen & Breathing Logo]
        splash --> onboarding[Swipe 3-Step Onboarding]
        onboarding --> authChoice{Select Entry Mode}
        authChoice -->|Sign In / Up| authScreen[Submit Auth Credentials]
        authChoice -->|Guest Mode| mainUI[Enter Main Cinema Hub]
        authScreen --> mainUI
        mainUI --> userAction{User Intent}
        userAction -->|Watch Cinema| clickMovie[Select Movie & Expand Trailer]
        userAction -->|Live TV| selectChannel[Browse Flag Filtered Channels]
        userAction -->|AI CineBot| openBot[Prompt Cinema Concierge]
        userAction -->|Upgrade VIP| clickUpgrade[Select VIP Pass Plan]
    end

    subgraph FlutterLane ["📱 Flutter Client Layer"]
        clickMovie --> initPlayer[Initialize 4K Player & Load Resume Timestamp]
        selectChannel --> reqChannel[Request Stream HLS Playlist]
        openBot --> sendMsg[Dispatch Message & Current Screen Context]
        clickUpgrade --> checkoutModal[Render Paystack Checkout / Mock Switch]
    end

    subgraph BackendLane ["⚡ FastAPI UV Backend"]
        reqChannel --> vlcProxy[Proxy & Cache M3U Chunk Stream]
        sendMsg --> intentCheck{Matches App Intent?}
        intentCheck -->|Yes: Direct Nav| buildAction[Build Action Payload: OPEN/NAVIGATE]
        intentCheck -->|No: Query AI| modelRotator[Invoke Google GenAI ADK Rotator]
        checkoutModal --> initPaystack[Initialize Paystack Reference]
    end

    subgraph CloudLane ["☁️ Cloud Services (Google GenAI / Paystack / TMDB)"]
        modelRotator --> genaiCall[Gemini 2.5-Flash]
        genaiCall -->|Success| genaiResponse[Return AI Cinematic Answer]
        genaiCall -->|Quota 429| failoverModel[Failover to Gemini 2.0 / 1.5-Flash]
        failoverModel --> genaiResponse
        initPaystack --> paystackVerify[Process Paystack / Mock Verification]
    end

    vlcProxy --> livePlayer[Stream 60 FPS Video to User]
    genaiResponse --> streamReply[Display Bot Response & Execute In-App Action]
    buildAction --> streamReply
    paystackVerify --> activateVIP[Issue VIP Pass & Unlock 4K Streams]
```

---

### 5. 🔄 Sequence Diagram (End-to-End Discovery & Checkout)
Details synchronous and asynchronous message exchanges during an AI-driven movie discovery and VIP Pass checkout lifecycle.

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 Cinema User
    participant Flutter as 📱 Flutter Client
    participant Storage as 💾 LocalStorage / SQLite
    participant Backend as ⚡ FastAPI Backend
    participant GenAI as 🤖 Google GenAI (ADK Rotator)
    participant Paystack as 💳 Paystack Gateway

    %% Phase 1: AI Chat & Action Execution
    Note over User,GenAI: 1. AI CineBot Recommendation & In-App Navigation
    User->>Flutter: Types "Recommend top sci-fi like Interstellar"
    Flutter->>Backend: POST /api/agent/chat { message, currentScreen: "Home" }
    Backend->>GenAI: Try client.models.generate_content("gemini-2.5-flash")
    alt Rate Limit / Quota 429
        GenAI-->>Backend: 429 Resource Exhausted
        Backend->>GenAI: Failover to "gemini-2.0-flash" / "gemini-1.5-flash"
    end
    GenAI-->>Backend: Return formatted response + SEARCH_MOVIE action
    Backend-->>Flutter: { success: true, reply: "...", actions: [{"type": "OPEN_MOVIE", "payload": {"movieId": 157336}}] }
    Flutter->>User: Displays Titanium Bot Message
    Flutter->>Flutter: Automatically opens Interstellar Details Modal

    %% Phase 2: Video Playback & Resume Sync
    Note over User,Storage: 2. Video Playback & Local Progress Resume
    User->>Flutter: Presses "Watch Now (4K HDR)"
    Flutter->>Storage: getWatchProgress(157336)
    Storage-->>Flutter: { position: 1420s, duration: 10140s }
    Flutter->>User: Resumes playback seamlessly from 00:23:40
    Flutter->>Storage: saveWatchProgress(157336, 1850s, 10140s)

    %% Phase 3: VIP Pass Checkout
    Note over User,Paystack: 3. Paystack VIP Pass Checkout & Mock Mode
    User->>Flutter: Clicks "Upgrade to Pure Cinema VIP Pass"
    Flutter->>Backend: POST /api/payment/initialize { email, planId: "vip_monthly" }
    Backend->>Paystack: Create transaction reference
    Paystack-->>Backend: { authUrl, reference: "pc_tx_928172" }
    Backend-->>Flutter: Return checkout details
    Flutter->>User: Renders Paystack Modal (or Instant Mock Switch)
    User->>Flutter: Confirms Mock Checkout Approval
    Flutter->>Backend: POST /api/payment/verify { reference: "pc_tx_928172" }
    Backend-->>Flutter: { success: true, isVip: true, transaction: { status: "success" } }
    Flutter->>Storage: updateUserSession(isVip: true)
    Flutter->>User: Shows VIP Celebration Badge & Unlocks VIP Streams 🎉
```

---

## 📁 Repository Structure

```text
pure_cinema_flutter/
├── lib/                               # Flutter Frontend Codebase
│   ├── models/                        # Movie, Cast, LiveChannel data schemas
│   ├── screens/
│   │   ├── splash_screen.dart         # Living breathing logo splash
│   │   ├── onboarding_screen.dart     # 3-step cinematic onboarding
│   │   ├── sign_in_screen.dart        # Dedicated authentication screen
│   │   ├── sign_up_screen.dart        # Dedicated registration screen
│   │   ├── landing_screen.dart        # Cinematic brand landing & guest entry
│   │   ├── main_nav_screen.dart       # Floating capsule dock navigator
│   │   ├── home_screen.dart           # Hero banner, auto-trailers, best picks
│   │   ├── live_tv_screen.dart        # 10,000+ live channels with national flags
│   │   ├── search_screen.dart         # Instant movie & genre search
│   │   ├── watchlist_screen.dart      # Saved cinema titles & continue watching
│   │   ├── profile_screen.dart        # Account settings & VIP pass upgrade
│   │   └── agent_chat_screen.dart     # Titanium AI CineBot conversation modal
│   ├── services/
│   │   ├── agent_service.dart         # CineBot communication client
│   │   ├── auth_service.dart          # Session manager & offline fallback
│   │   ├── database_service.dart      # LocalStorage & SQLite repository
│   │   ├── iptv_service.dart          # Live TV stream coordinator
│   │   ├── payment_service.dart       # Paystack & Mock transaction service
│   │   └── tmdb_service.dart          # Movie metadata & backdrop client
│   ├── theme/                         # S-Core Dream typography & colors
│   └── widgets/                       # Reusable UI widgets & modals
├── backend/                           # FastAPI UV Backend
│   ├── app/
│   │   ├── models/schemas.py          # Pydantic schemas & action flags
│   │   ├── routers/                   # API routes (agent, auth, iptv, payment)
│   │   ├── services/                  # Agent rotator, IPTV parser, TMDB cache
│   │   ├── config.py                  # Environment settings
│   │   └── main.py                    # FastAPI entrypoint & CORS middleware
│   ├── pyproject.toml                 # UV dependency management
│   ├── requirements.txt               # PIP dependencies for cloud builders
│   └── run.py                         # Production server launcher
├── web/                               # Web runner, PWA icons, breathing splash
├── render.yaml                        # 1-Click Render Blueprint infrastructure
└── README.md                          # You are here!
```

---

## ⚡ Quick Start Guide

### Prerequisites
- **Flutter SDK**: `3.x+` ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Python**: `3.10+` ([Install Python](https://python.org))
- **UV** (Optional, recommended): `pip install uv`

---

### 1. Run the FastAPI Backend

```bash
# Navigate to backend folder
cd backend

# Install dependencies and start server with hot reload
uv run python run.py

# Or with standard Python / Uvicorn:
# pip install -r requirements.txt
# uvicorn app.main:app --host 0.0.0.0 --port 3000 --reload
```
> **Backend URL**: `http://localhost:3000`  
> **API Health Check**: `http://localhost:3000/health`

---

### 2. Run the Flutter App

Open a second terminal in the project root:

```bash
# Run on Chrome / Desktop Browser
flutter run -d chrome

# Or run with HTML renderer (optimized for iPhone / Safari on local Wi-Fi)
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8090 --web-renderer html
```
> **Access from Mobile**: Open Safari on your phone and visit `http://YOUR_LOCAL_IP:8090` (e.g. `http://192.168.1.245:8090`).

---

## 🔑 Environment Configuration

Create a `.env` file in the `backend/` directory (see [`backend/.env.example`](backend/.env.example)):

| Variable | Description | Default / Required |
| :--- | :--- | :--- |
| `HOST` | Backend host binding | `0.0.0.0` |
| `PORT` | Backend port | `3000` |
| `TMDB_API_KEY` | TMDB API key for movie metadata & trailers | Required for live TMDB |
| `GEMINI_API_KEY` | Google Gemini API key (powers AI CineBot) | Required for Gemini ADK |
| `PAYSTACK_SECRET_KEY` | Paystack secret key for VIP subscriptions | Optional (uses Mock Mode if unset) |
| `PAYSTACK_PUBLIC_KEY` | Paystack public key | Optional (uses Mock Mode if unset) |
| `JWT_SECRET` | Secret key for signing auth tokens | Any 64-char string |
| `DATABASE_URL` | Optional PostgreSQL / Supabase connection | Optional (uses client storage) |

---

## 🚀 Cloud Deployment

### Backend on Render (1-Click Blueprint)
The repository includes a ready-to-use [`render.yaml`](render.yaml) specification:
1. Go to [dashboard.render.com](https://dashboard.render.com/) $\rightarrow$ **New +** $\rightarrow$ **Blueprint**.
2. Select your repository: `JaimeCabary/Pure-Cinema-Flutter`.
3. Render automatically provisions your FastAPI web service and configures health checks.
4. **Live Production URL**: `https://pure-cinema-backend.onrender.com`

### Frontend on Render Static Site / Netlify / Vercel
1. Build the production web bundle:
   ```bash
   flutter build web --release
   ```
2. Deploy the `build/web` folder to:
   - **Render Static Site**: Build command: `git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk && export PATH="$PATH:\`pwd\`/flutter-sdk/bin" && flutter build web --release`, Publish directory: `build/web`.
   - **Netlify Drop**: Drag `build/web` into [app.netlify.com/drop](https://app.netlify.com/drop).
   - **Vercel**: Run `npx -y vercel --prod build/web`.

---

## 💡 Access Modes

- **Guest Access**: Tap **"ENTER AS GUEST"** on the landing screen for instant zero-friction cinema streaming.
- **Member Access**: Create an account or sign in to save your personal watchlists and track watch history across sessions.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

<div align="center">
  <br/>
  <b>Pure Cinema Studios · 2026</b>
  <br/>
  <i>Crafted with passion for cinema lovers worldwide.</i>
</div>
