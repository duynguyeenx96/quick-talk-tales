# Backend — NestJS API

REST API and WebSocket gateway for Quick Talk Tales. Handles authentication, story/word management, real-time audio streaming, email verification, payments, and communicates with the AI service for story evaluation.

## Tech Stack

- **Framework:** NestJS 10 (TypeScript)
- **Database:** PostgreSQL + TypeORM
- **Auth:** JWT (access + refresh tokens), Google OAuth 2.0
- **Real-time:** Socket.io WebSocket gateway
- **Email:** Nodemailer + Gmail SMTP
- **Payments:** Sepay webhook + VietQR
- **Port:** 3000

## Prerequisites

- Node.js ≥ 18
- PostgreSQL ≥ 14
- A running instance of `ai-service` (port 5001)

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Fill in `.env`:

| Variable | Description |
|----------|-------------|
| `DB_HOST` / `DB_PORT` / `DB_NAME` | PostgreSQL connection |
| `DB_USERNAME` / `DB_PASSWORD` | Database credentials |
| `JWT_SECRET` | Random secret string (min 32 chars) |
| `JWT_REFRESH_SECRET` | Separate secret for refresh tokens |
| `GMAIL_USER` | Gmail address for sending emails |
| `GMAIL_APP_PASSWORD` | [Gmail App Password](https://myaccount.google.com/apppasswords) |
| `GOOGLE_CLIENT_ID` | OAuth client ID from [Google Cloud Console](https://console.cloud.google.com/apis/credentials) |
| `SEPAY_API_KEY` | API key from [sepay.vn](https://sepay.vn) |
| `BANK_ACCOUNT` | Bank account number for QR payments |
| `ADMIN_SECRET` | Bearer token for admin endpoints |
| `AI_SERVICE_URL` | URL of the AI service (default: `http://localhost:5001`) |

### 3. Set up the database

```bash
psql -U postgres -c "CREATE DATABASE quick_talk_tales;"
psql -U postgres -d quick_talk_tales -f database/schema.sql

# Optional: seed test data
psql -U postgres -d quick_talk_tales -f database/seeds/seed.sql
```

### 4. Run

```bash
# Development (hot-reload)
npm run start:dev

# Production
npm run build && npm run start:prod
```

The server starts at `http://localhost:3000`.

## Module Overview

| Module | Description |
|--------|-------------|
| `auth` | JWT login/register, refresh tokens, Google SSO |
| `users` | Profiles, avatars, roles (admin/author/reader) |
| `words` | Random word generation (3/5/7 mode) |
| `stories` | Story CRUD, publishing, categories, tags |
| `chapters` | Chapter management per story |
| `evaluation` | Submits user stories to AI service for LLM scoring |
| `speech` | WebSocket gateway — streams audio to AI service |
| `email` | Email verification and password reset |
| `payments` | Sepay webhook, VietQR generation, subscription management |
| `friends` | Friend requests and social graph |
| `group-challenges` | Multiplayer story challenges |
| `notifications` | In-app notification system |
| `admin` | Admin-only endpoints for user/payment management |

## Endpoints

- **REST API:** `http://localhost:3000/api/v1`
- **WebSocket:** `ws://localhost:3000/speech`
- **Flutter Web (static):** `http://localhost:3000`

Full API reference: [`API.md`](./API.md)

## Scripts

```bash
npm run start:dev    # Development with hot-reload
npm run start:prod   # Production
npm run build        # Compile TypeScript
npm run test         # Unit tests
npm run test:e2e     # End-to-end tests
npm run lint         # ESLint + Prettier
```
