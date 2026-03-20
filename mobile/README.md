# Mobile — Flutter App

Cross-platform app for Quick Talk Tales. Players receive random English words, record or type a short story, and receive an AI-generated score. Targets macOS, iOS, and Web.

## Tech Stack

- **Framework:** Flutter 3.4+ (Dart)
- **State Management:** Provider
- **Real-time:** Socket.io WebSocket
- **Auth:** JWT + Google Sign-In
- **Speech:** `speech_to_text` (local, for live feedback) + Whisper via backend (for final evaluation)
- **Platforms:** macOS · iOS · Web

## Prerequisites

- Flutter SDK ≥ 3.4 (`flutter doctor` to verify)
- Xcode (for macOS/iOS builds)
- A running `backend` instance (port 3000)

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Google Sign-In configuration

**macOS / iOS:**
1. Download `GoogleService-Info.plist` from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Place it in `ios/Runner/` and `macos/Runner/`
3. Add `REVERSED_CLIENT_ID` from the plist to `ios/Runner/Info.plist` under `CFBundleURLTypes`

**Web:**
The Google Client ID is injected at build time via `--dart-define` (handled by the root `start.sh`).

### 3. Configure the API base URL

In `lib/providers/api_service.dart`, update the base URL if your backend is not on `localhost:3000`:

```dart
static const String baseUrl = 'http://localhost:3000/api/v1';
static const String wsUrl = 'http://localhost:3000';
```

## Run

```bash
# macOS
flutter run -d macos --dart-define=GOOGLE_CLIENT_ID=${your_google_macos_client_id}

# iOS simulator
flutter run -d iPhone --dart-define=GOOGLE_CLIENT_ID=${your_google_ios_client_id}

# Web (development)
flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=${your_google_web_client_id}
```

## Build

```bash
# macOS release
flutter build macos --dart-define=GOOGLE_CLIENT_ID=${your_google_macos_client_id} --release

# Web release (output copied to backend/public/ by start.sh)
flutter build web --dart-define=GOOGLE_CLIENT_ID=${your_google_web_client_id} --release
```

> The root `start.sh` handles both builds automatically and copies the web output to `backend/public/`.

## Project Structure

```
lib/
├── main.dart
├── screens/
│   ├── auth/            # Login, register, email verification
│   ├── home_screen.dart
│   ├── words_screen.dart        # 30s countdown + word chips
│   ├── story_input_screen.dart  # Text / voice input
│   ├── result_screen.dart       # Score breakdown
│   ├── history_screen.dart
│   ├── leaderboard_screen.dart
│   ├── profile_screen.dart
│   └── subscription_screen.dart
├── providers/
│   ├── auth_provider.dart
│   ├── game_provider.dart
│   ├── speech_provider.dart
│   └── api_service.dart
├── widgets/             # Reusable UI components
└── l10n/
    └── app_strings.dart # English / Vietnamese
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `socket_io_client` | WebSocket connection to backend |
| `speech_to_text` | Local speech recognition (live feedback) |
| `google_sign_in` | Google OAuth |
| `provider` | State management |
| `image_picker` | Avatar upload |
| `animated_text_kit`, `lottie`, `flutter_animate` | Animations |
| `shared_preferences` | Local token storage |
