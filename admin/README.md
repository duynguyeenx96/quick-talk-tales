# Admin Dashboard — React

Internal administration interface for Quick Talk Tales. Provides user management, payment order tracking, and platform statistics. Intended for local use only and is not deployed to production.

## Tech Stack

- **Framework:** React 19 + TypeScript
- **Build Tool:** Vite
- **HTTP Client:** Axios
- **Auth:** Admin secret key (Bearer token)
- **Port:** 5173

## Prerequisites

- Node.js ≥ 18
- A running `backend` instance (port 3000)
- The `ADMIN_SECRET` value from `backend/.env`

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment

Create a `.env` file:

```bash
VITE_API_URL=http://localhost:3000
VITE_ADMIN_SECRET=${your_admin_secret}
```

> `VITE_ADMIN_SECRET` must match the `ADMIN_SECRET` value set in `backend/.env`.

### 3. Run

```bash
npm run dev
```

The dashboard opens at `http://localhost:5173`.

## Features

| Feature | Description |
|---------|-------------|
| User management | View users, grant/revoke premium subscription |
| Payment orders | Track Sepay payment status |
| Platform stats | Active users, submission counts, revenue |

## Security Notice

This dashboard is **not** intended for public deployment. It uses a shared secret for authentication and has no rate limiting. Keep it local or behind a VPN/firewall.

The `admin/` directory is listed in the root `.gitignore` to prevent accidental commits of sensitive admin tooling.
