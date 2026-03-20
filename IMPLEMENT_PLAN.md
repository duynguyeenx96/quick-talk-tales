# Quick Talk Tales — Implementation Plan

Last updated: 2026-03-16 (session 4)

---

## Legend
- ✅ Done
- 🐛 Done but has bug
- 🔄 In progress
- ⬜ Todo
- ❌ Blocked

---

## Phase 1 — Core Gameplay Loop ✅

### 1.1 Words Module (NestJS)
- ✅ `Word` entity (text, category, difficulty, isActive)
- ✅ 80 seed words across 8 categories (animal, food, nature, object, action, adjective, place, person)
- ✅ Auto-seed on startup via `OnModuleInit`
- ✅ `GET /words/random?count=3|5|7&difficulty=easy|medium|hard`
- ✅ Fisher-Yates shuffle
- ✅ Protected by JwtAuthGuard

### 1.2 AI Evaluation (FastAPI)
- ✅ `POST /api/v1/evaluate-story`
- ✅ Groq API integration (llama-3.3-70b-versatile)
- ✅ Mock fallback khi không có API key
- ✅ Scoring: grammar(25%) + creativity(30%) + coherence(25%) + word_usage(20%)
- ✅ Returns: scores, words_used, words_missing, feedback, encouragement

### 1.3 Evaluation Pipeline (NestJS)
- ✅ `StorySubmission` entity
- ✅ `POST /evaluation/submit` → call FastAPI → save DB
- ✅ `GET /evaluation/history`
- ✅ `GET /evaluation/:id`
- ✅ `GET /evaluation/leaderboard` (top 20, GROUP BY userId, join users)
- ✅ `GET /evaluation/my-stats` (totalScore, totalChallenges, avgScore, bestScore)

### 1.4 Flutter Screens
- ✅ AuthProvider, GameProvider, SpeechProvider
- ✅ ApiService (HTTP client, token management)
- ✅ LoginScreen, RegisterScreen
- ✅ HomeScreen (word count + difficulty picker, top bar: History/Leaderboard/Profile)
- ✅ WordsScreen (30s countdown, word chips, staggered animation)
- ✅ StoryInputScreen (text/voice toggle, real-time word highlight, editable transcript + re-record button)
- ✅ ResultScreen (score breakdown, word report, teacher feedback)

---

## Phase 2 — Integration & Device Testing ✅

### 2.1 Bug Fixes
- ✅ Logout button không hoạt động → root cause: ResultScreen dùng `Navigator.pushAndRemoveUntil(...false)` xoá mất `_AuthGate` root route → fix: dùng `Navigator.popUntil(isFirst)` + reset GameProvider on logout

### 2.2 Device Testing
- ✅ macOS desktop (đang dùng để test)
- ⬜ iPhone thật (steps bên dưới)
  1. `open ios/Runner.xcworkspace`
  2. Xcode → Runner → Signing & Capabilities → Automatically manage signing
  3. Chọn Apple ID, Bundle ID: `com.duynguyen.quicktalkstories`
  4. iPhone: Settings → General → VPN & Device Management → Trust
  5. `flutter run -d <device-id>`
  > Note: Free Apple ID → re-sign mỗi 7 ngày

---

## Phase 2.5 — Auth & Avatar Upgrade ✅

### SSO — Google
- ✅ Backend: `POST /auth/google` — verify idToken via google-auth-library, find-or-create user
- ✅ Backend: link existing local account nếu email trùng
- ✅ Flutter: `google_sign_in` package — lấy idToken → gửi backend → lưu JWT
- ✅ LoginScreen: "Continue with Google" button
- ✅ macOS: REVERSED_CLIENT_ID thêm vào `macos/Runner/Info.plist` CFBundleURLTypes
- ✅ iOS: REVERSED_CLIENT_ID thêm vào `ios/Runner/Info.plist` CFBundleURLTypes
- ⬜ Facebook SSO — cần native Facebook SDK setup (AppID, hash key) → TODO Phase 5

### Email Verification
- ✅ Backend: User entity thêm verificationToken, verificationTokenExpires
- ✅ Backend: EmailService (Nodemailer + Gmail SMTP, cấu hình qua GMAIL_USER + GMAIL_APP_PASSWORD, ~300 mails/day)
- ✅ Backend: `GET /auth/verify-email?token=xxx` + `POST /auth/resend-verification`
- ✅ Flutter: EmailVerificationScreen (resend button, 60s cooldown, "Already verified? Sign in")
- ✅ RegisterScreen: sau register → redirect sang EmailVerificationScreen

### Avatar Upload
- ✅ Backend: `POST /users/avatar` — Multer multipart, save to `uploads/avatars/`, serve via `/uploads` static
- ✅ Backend: file filter chấp nhận `image/*` MIME hoặc extension (fix lỗi macOS gửi `application/octet-stream`)
- ✅ Flutter: `image_picker` package — gallery hoặc camera
- ✅ Flutter: explicit `contentType` trên multipart request, tự append `.jpg` nếu filename không có extension
- ✅ ProfileScreen: avatar picker có 2 tab: "📷 Photo" (gallery/camera) + "😸 Emoji" (16 predefined)
- ✅ AvatarWidget (public): hiển thị emoji / HTTP photo URL / initials fallback
- ✅ macOS sandbox entitlements: `com.apple.security.files.user-selected.read-write` + `assets.pictures.read-only`

### User entity additions
- ✅ googleId, facebookId, authProvider ('local'|'google'|'facebook')
- ✅ verificationToken, verificationTokenExpires, emailVerified
- ✅ subscriptionPlan ('free'|'premium'), subscriptionExpiresAt

---

## Phase 3 — User Profile & Personalization ✅

### 3.1 Profile Screen ✅
- ✅ Hiển thị thông tin user (username, email, join date, account ID)
- ✅ Avatar emoji picker + photo upload
- ✅ Chỉnh sửa Display Name (fullName) → PUT /users/profile
- ✅ Language preference (EN 🇺🇸 / VI 🇻🇳) → lưu vào preferences.language → đổi locale app ngay lập tức
- ✅ Subscription badge (Free / Premium) — đọc đúng field `subscriptionPlan` (fix bug dùng nhầm `role`)
- ✅ Stats strip: Total Challenges, Avg Score, Best Score
- ✅ Logout button
- ✅ refreshProfile() khi mở màn hình → luôn hiển thị trạng thái subscription mới nhất
- ⬜ Streak tracking (số ngày liên tiếp chơi)

### 3.2 Theme Settings
- ⬜ Light / Dark mode toggle
- ⬜ Lưu preference vào SharedPreferences

### 3.3 History Screen ✅
- ✅ Danh sách submissions trước đó (sorted by date, staggered animation)
- ✅ Tap → bottom sheet chi tiết (score, breakdown, word report, feedback, story text)
- ✅ Nút History icon trong HomeScreen top bar

### 3.4 Leaderboard Screen ✅
- ✅ Backend: GET /evaluation/leaderboard + GET /evaluation/my-stats
- ✅ Flutter: 2 tabs — Total Score / Total Challenges (client-side sort)
- ✅ Rank medals 🥇🥈🥉, AvatarWidget, "You" badge cho current user
- ✅ My Rank banner ở top nếu không nằm trong top 3
- ✅ Pull-to-refresh

---

## Phase 4 — Subscription & Monetization ✅

### 4.1 Subscription Tiers
- ✅ Free: 3 stories/day, easy/medium difficulty
- ✅ Premium: unlimited, hard difficulty, detailed feedback
- ✅ Backend: `GET /users/subscription/plans`
- ✅ Backend: `POST /users/subscription/mock-upgrade` (còn giữ lại cho testing)

### 4.2 Subscription Screen ✅
- ✅ Plan cards (Free vs Premium) với feature comparison table
- ✅ Monthly (59.000 VND) / Yearly (499.000 VND) billing toggle
- ✅ CTA → navigate sang PaymentScreen (real QR flow)
- ✅ Note giải thích thanh toán qua chuyển khoản ngân hàng

### 4.3 Sepay Payment Integration ✅
- ✅ `PaymentOrder` entity (userId, planId, amount, transferContent, status, expiresAt, paidAt, sepayTransactionId)
- ✅ Backend: `POST /payments/create-order` (JWT) — tạo order, cancel pending cũ, sinh transferContent = `{PREFIX} {6_HEX}`
- ✅ Backend: `GET /payments/status/:orderId` (JWT) — auto-expire nếu hết giờ
- ✅ Backend: `POST /payments/webhook/sepay` (no JWT, Apikey header) — match transferContent trong `code`, nâng cấp subscription
- ✅ VietQR URL: `https://img.vietqr.io/image/${bank}-${acc}-compact.jpg?amount=...&addInfo=...`
- ✅ Flutter: PaymentScreen — hiển thị QR + bank info, countdown 30 phút, polling 5 giây, success sheet
- ✅ Flutter: copy-to-clipboard cho account number và transfer content
- ✅ `.env` placeholders: `SEPAY_API_KEY`, `BANK_CODE`, `BANK_ACCOUNT`, `BANK_ACCOUNT_NAME`, `TRANSFER_PREFIX`

### 4.4 Admin Dashboard (Web) ✅
- ✅ React + Vite + TypeScript SPA (`quick_talk_tales_admin/`) — **không commit lên GitHub**
- ✅ Login page: xác thực bằng `ADMIN_SECRET` bearer token
- ✅ Dashboard: 4 stat cards (total users, premium users, total orders, completed orders)
- ✅ Users tab: search, paginate, Grant 30d / Revoke premium một click
- ✅ Orders tab: danh sách payment orders với color-coded status
- ✅ Backend: `GET /admin/stats`, `GET /admin/users`, `PATCH /admin/users/:id/subscription`, `GET /admin/orders`
- ✅ Backend: CORS enabled (`app.enableCors`) cho dev

---

## Phase 5 — i18n & Localization ✅ (partial)

### 5.1 Multi-language Support
- ✅ `flutter_localizations` thêm vào pubspec (SDK bundled, no extra package)
- ✅ `AppStrings` class với EN/VI string map (`lib/l10n/app_strings.dart`)
- ✅ `AppLocaleProvider` InheritedWidget — inject strings down the tree
- ✅ `MaterialApp.locale` + `supportedLocales` + `localizationsDelegates` driven by `AuthProvider.language`
- ✅ ProfileScreen strings localized: Language, Display Name, Free Plan, Premium, Upgrade, Log Out, Save
- ⬜ Localize các màn hình còn lại (HomeScreen, HistoryScreen, LeaderboardScreen, PaymentScreen...)
- ⬜ Thêm strings khi có feature mới vào `AppStrings`

---

## Phase 6 — Polish & Production ⬜

### 6.1 UX Polish
- ⬜ Loading skeletons
- ⬜ Error states với retry button (các màn hình hiện chỉ show text)
- ⬜ Onboarding flow (first-time user tutorial)
- ⬜ Sound effects / haptic feedback
- ⬜ Streak tracking

### 6.2 Performance
- ⬜ Prompt caching cho Groq (giảm latency)
- ⬜ Offline mode (cache words locally)

### 6.3 Auth
- ⬜ Facebook SSO (native SDK)
- ⬜ Refresh token flow (hiện chỉ dùng access token 1d)

### 6.4 Production Infra
- ⬜ Docker Compose cho tất cả services
- ⬜ Environment configs (staging / production)
- ⬜ CI/CD pipeline
- ⬜ Deploy backend lên cloud (Railway / Render / VPS)
- ⬜ App Store / TestFlight setup

---

## Env Variables Reference

### Backend (`.env`)
```
DB_HOST / DB_PORT / DB_NAME / DB_USERNAME / DB_PASSWORD
JWT_SECRET / JWT_EXPIRES_IN / JWT_REFRESH_SECRET / JWT_REFRESH_EXPIRES_IN
AI_SERVICE_URL=http://localhost:5001
BASE_URL=http://localhost:3000
GMAIL_USER / GMAIL_APP_PASSWORD
GOOGLE_CLIENT_ID
APP_SCHEME=quicktalkstories
SEPAY_API_KEY          # Sepay dashboard → Webhook → API Key
BANK_CODE              # e.g. MB
BANK_ACCOUNT           # tài khoản ngân hàng
BANK_ACCOUNT_NAME      # tên chủ tài khoản
TRANSFER_PREFIX=QTTALES
ADMIN_SECRET           # bảo vệ /admin/* endpoints
```

### Admin Dashboard (`.env`)
```
VITE_API_URL=http://localhost:3000
```

---

## Tech Stack

| Layer | Tech | Notes |
|-------|------|-------|
| Mobile | Flutter | macOS + iOS |
| Backend | NestJS (TypeScript) | Port 3000 |
| AI Service | FastAPI (Python) | Port 5001 |
| Database | PostgreSQL | Docker |
| AI Model | Groq llama-3.3-70b | Free tier |
| Auth | JWT + Google OAuth | Access token 1d |
| Payment | Sepay webhook + VietQR | Bank transfer QR |
| Admin | React + Vite | Local only, không commit |
| State | Provider | AuthProvider, GameProvider, SpeechProvider |
| i18n | flutter_localizations + AppStrings | EN / VI |
