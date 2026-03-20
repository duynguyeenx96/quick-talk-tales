# Quick Talk Tales

An interactive storytelling platform for children. Players receive 3, 5, or 7 random English words and must compose a short story using all of them — via text or voice. Stories are transcribed with OpenAI Whisper and evaluated by an LLM for grammar, creativity, and coherence.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter App (mobile/)               │
│        macOS · iOS · Web (Duolingo-inspired UI)      │
└──────────────────────┬──────────────────────────────┘
                       │ REST + WebSocket
┌──────────────────────▼──────────────────────────────┐
│              NestJS Backend (backend/)               │
│   Auth · Stories · Words · Payments · WebSocket GW   │
└──────────┬───────────────────────────┬──────────────┘
           │ PostgreSQL                │ HTTP
┌──────────▼──────────┐   ┌───────────▼──────────────┐
│      PostgreSQL      │   │   FastAPI AI (ai-service/)│
│  Users · Stories     │   │   Whisper STT · Groq LLM  │
│  Payments · Words    │   │   Story Evaluation        │
└─────────────────────┘   └──────────────────────────┘
```

| Service | Tech | Port |
|---------|------|------|
| Backend API | NestJS + TypeScript | 3000 |
| AI Service | FastAPI + Python | 5001 |
| Flutter Web | Served via NestJS static | 3000 |
| Admin Dashboard | React + Vite | 5173 |

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | ≥ 18 |
| Python | ≥ 3.11 |
| Flutter | ≥ 3.4 |
| PostgreSQL | ≥ 14 |
| FFmpeg | any |

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/your-username/quick-talk-tales.git
cd quick-talk-tales
```

### 2. Configure environment variables

```bash
# Backend
cp backend/.env.example backend/.env

# AI Service
cp ai-service/.env.example ai-service/.env
```

Edit each `.env` file and fill in your credentials (see per-service README for details).

### 3. Configure the startup script

```bash
cp start.sh.example start.sh
cp stop.sh.example stop.sh
chmod +x start.sh stop.sh
```

Open `start.sh` and fill in your Google OAuth Client IDs:

```bash
WEB_CLIENT_ID="${your_google_web_client_id}"
MACOS_CLIENT_ID="${your_google_macos_client_id}"
```

### 4. Install dependencies

```bash
# Backend
cd backend && npm install && cd ..

# AI Service
cd ai-service && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && cd ..

# Flutter
cd mobile && flutter pub get && cd ..

# Admin (optional)
cd admin && npm install && cd ..
```

### 5. Set up the database

```bash
psql -U postgres -c "CREATE DATABASE quick_talk_tales;"
psql -U postgres -d quick_talk_tales -f backend/database/schema.sql
# Optional: seed test data
psql -U postgres -d quick_talk_tales -f backend/database/seeds/seed.sql
```

### 6. Start all services

```bash
./start.sh
```

**Options:**

```bash
./start.sh --skip-build          # Skip Flutter builds (faster restart)
./start.sh --skip-flutter-web    # Skip only Flutter Web build
./start.sh --skip-flutter-macos  # Skip only Flutter macOS build
```

**Stop all services:**

```bash
./stop.sh
```

Logs are written to `.logs/nestjs.log`, `.logs/fastapi.log`, `.logs/admin.log`.

## Repository Structure

```
quick-talk-tales/
├── backend/          # NestJS REST API + WebSocket gateway
├── ai-service/       # FastAPI speech-to-text + story evaluation
├── mobile/           # Flutter cross-platform app (macOS, iOS, Web)
├── admin/            # React admin dashboard (local only)
├── start.sh.example  # Startup script template
├── stop.sh.example   # Stop script template
└── .gitignore
```

## Services

- **[backend/](./backend/README.md)** — REST API, JWT auth, Google OAuth, Sepay payments, WebSocket gateway
- **[ai-service/](./ai-service/README.md)** — Whisper speech-to-text, Groq LLM story evaluation
- **[mobile/](./mobile/README.md)** — Flutter app for macOS, iOS, and Web
- **[admin/](./admin/README.md)** — React admin dashboard for user and payment management

## License

MIT
