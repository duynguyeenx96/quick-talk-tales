# Quick Talk Tales - Project Summary

**Date Created:** September 10, 2025  
**Developer:** Duy Nguyen  
**AI Assistant:** Claude (Sonnet 4)  

## 🎯 Project Overview

**Quick Talk Tales** is an interactive storytelling platform for children where users receive 3/5/7 random English words, then create stories using text or voice input. The system processes audio with Whisper (local), evaluates stories with AI/LLM for grammar/creativity/coherence, and provides detailed feedback with scoring, history tracking, and achievements.

## 🏗️ Architecture

### Microservices Architecture:
```
Flutter Mobile App ↔ NestJS Backend ↔ FastAPI AI Service
                          ↕              ↕
                    PostgreSQL DB     Whisper AI
```

### Technology Stack:
- **Backend**: NestJS (TypeScript)
- **AI Service**: FastAPI (Python) 
- **Database**: PostgreSQL
- **Queue**: Redis + BullMQ
- **Storage**: S3/MinIO
- **Mobile**: Flutter (Dart)
- **AI**: OpenAI Whisper (local)

## 📁 Project Structure

```
/Users/duynguyen/Documents/Personal_Project/
├── quick_talk_tales/           # NestJS Backend (Port 3000)
├── quick_talk_tales_ai/        # FastAPI AI Service (Port 5000)
└── quick_talk_tales_mobile/    # Flutter Mobile App
```

## 🚀 What's Been Completed

### ✅ NestJS Backend (`quick_talk_tales/`)
**Location:** `/Users/duynguyen/Documents/Personal_Project/quick_talk_tales`

#### Features Implemented:
- **WebSocket Gateway** for real-time speech processing
- **JWT Authentication** system with refresh tokens
- **User Management** (Reader, Author, Admin roles)
- **Story & Chapter Management** with CRUD operations
- **Database Entities** (User, Story, Chapter, Progress, Ratings, etc.)
- **Speech Module** for WebSocket communication

#### Key Files:
- `src/speech/speech.gateway.ts` - WebSocket gateway for audio processing
- `src/speech/speech.service.ts` - Speech processing service
- `src/auth/` - Authentication module
- `src/users/`, `src/stories/`, `src/chapters/` - Core modules
- `src/database/entities/` - TypeORM entities

#### API Endpoints:
- WebSocket: `ws://localhost:3000/speech`
- REST: `http://localhost:3000/api/v1/*`

#### Dependencies Installed:
- `@nestjs/websockets`, `@nestjs/platform-socket.io`
- `socket.io`, `axios`, `form-data`
- `bcrypt`, `passport-jwt`, `typeorm`, `pg`

---

### ✅ FastAPI AI Service (`quick_talk_tales_ai/`)
**Location:** `/Users/duynguyen/Documents/Personal_Project/quick_talk_tales_ai`

#### Features Implemented:
- **Whisper Speech-to-Text** processing
- **Binary Audio Support** (FormData uploads)
- **Session Management** for audio chunks
- **Async Processing** with proper error handling
- **Docker Containerization** ready

#### Key Files:
- `app/main.py` - FastAPI application entry
- `app/models/speech_models.py` - Whisper processing logic
- `app/routers/speech_router.py` - Base64 audio endpoints
- `app/routers/speech_binary_router.py` - Binary audio endpoints
- `app/config.py` - Configuration settings
- `Dockerfile` - Container setup

#### API Endpoints:
- Health: `GET http://localhost:5000/health`
- Base64 Audio: `POST http://localhost:5000/api/v1/process-audio`
- Binary Audio: `POST http://localhost:5000/api/v1/process-audio-binary`
- Documentation: `http://localhost:5000/docs`

#### Whisper Models Available:
- `tiny`, `base` (recommended for development)
- `turbo` (recommended for production)
- `small`, `medium`, `large` (higher accuracy)

---

### ✅ Flutter Mobile App (`quick_talk_tales_mobile/`)
**Location:** `/Users/duynguyen/Documents/Personal_Project/quick_talk_tales_mobile`

#### Features Implemented:
- **Kid-friendly UI Design** inspired by Duolingo
- **Real-time Speech Recognition** with visual feedback
- **WebSocket Integration** with NestJS backend
- **Animated Components** (pulse, transitions, typing effects)
- **State Management** with Provider pattern

#### Key Files:
- `lib/main.dart` - App entry point
- `lib/screens/story_screen.dart` - Main story interface
- `lib/providers/speech_provider.dart` - Speech state management
- `lib/widgets/` - Custom UI components
- `lib/theme/app_theme.dart` - Duolingo-inspired theme

#### UI Components:
- **StoryHeader** - Animated title and instructions
- **SpeechTextField** - Text display with listening animations
- **MicrophoneButton** - Center mic button with pulse effects
- **Color Scheme** - Green, Blue, Pink, Orange (kid-friendly)

#### Dependencies:
- `socket_io_client`, `speech_to_text`, `record`
- `animated_text_kit`, `flutter_animate`, `lottie`
- `provider`, `permission_handler`

## 🔄 Data Flow

### Audio Processing Flow:
```
1. Flutter App → WebSocket → NestJS Gateway
2. NestJS → HTTP FormData → FastAPI Server
3. FastAPI → Whisper Processing → Transcription
4. FastAPI → NestJS → WebSocket → Flutter App
```

### Binary vs Base64:
- **Binary Audio**: More efficient, less memory usage
- **FormData Upload**: Direct file processing by Whisper
- **Real-time Feedback**: Local speech recognition for UX

## ⚙️ Configuration Details

### Environment Variables:

#### NestJS (.env):
```bash
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/quick_talk_tales
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
```

#### FastAPI (.env):
```bash
PORT=5000
WHISPER_MODEL=base
WHISPER_DEVICE=cpu
WHISPER_LANGUAGE=en
MAX_AUDIO_SIZE=26214400
```

### Database Setup:
- PostgreSQL database with full schema
- Seeds with test users (Admin, Author, Reader)
- Migration system ready

## 🧪 Testing Status

### ✅ Tested:
- NestJS dependencies installation
- FastAPI dependencies installation
- Whisper model availability
- Basic configuration loading
- Project structure creation

### 🔄 Needs Testing:
- End-to-end WebSocket communication
- Audio file processing pipeline
- Flutter app connection to backend
- Database operations
- Complete user flow

## 🚧 Immediate Next Steps

### High Priority:
1. **Test FastAPI Server Startup**
   ```bash
   cd quick_talk_tales_ai
   uvicorn app.main:app --host 0.0.0.0 --port 5000
   ```

2. **Test NestJS Server Startup**
   ```bash
   cd quick_talk_tales
   npm start:dev
   ```

3. **Test Flutter App**
   ```bash
   cd quick_talk_tales_mobile
   flutter pub get
   flutter run
   ```

4. **End-to-End Integration Testing**
   - WebSocket connection Flutter ↔ NestJS
   - HTTP communication NestJS ↔ FastAPI
   - Audio processing pipeline

### Medium Priority:
5. **Database Setup & Connection**
   - Run PostgreSQL setup scripts
   - Test database migrations
   - Verify entity relationships

6. **Authentication Implementation**
   - User registration/login flow
   - JWT token management
   - Role-based permissions

### Low Priority:
7. **Random Words Feature**
   - Create Words module in NestJS
   - Word database and categories
   - Random word selection API

8. **Story Evaluation System**
   - LLM integration for story scoring
   - Grammar/creativity/coherence analysis
   - Feedback generation system

9. **User Progress & Achievements**
   - Progress tracking system
   - Achievement badges
   - Leaderboards and statistics

## 🐛 Known Issues

### Potential Issues:
1. **CORS Configuration** - May need adjustment for mobile app
2. **WebSocket Connection** - Local network access for mobile testing
3. **Whisper Model Loading** - First-time download ~74MB for base model
4. **Audio Permissions** - iOS/Android microphone permissions
5. **Binary Audio Format** - Ensure Flutter sends compatible audio format

### Missing Implementations:
1. **LLM Story Evaluation** - Main feature not implemented yet
2. **Random Words System** - Word generation API missing
3. **User Authentication** - Frontend login/register screens
4. **Story Submission** - Complete story processing pipeline
5. **Database Migrations** - Need to run initial setup

## 📝 Development Notes

### Code Quality:
- TypeScript strict mode enabled
- Flutter lint rules configured  
- Proper error handling implemented
- Async/await patterns used throughout

### Security Considerations:
- JWT tokens with refresh mechanism
- Input validation with class-validator
- CORS properly configured
- File upload size limits set

### Performance Optimizations:
- WebSocket for real-time communication
- Binary audio transfer (not base64)
- Efficient Whisper model loading
- Provider state management in Flutter

## 🎯 Project Goals Recap

### Primary Features:
- [x] **Speech-to-Text Processing** (Whisper integration)
- [x] **Real-time Audio Streaming** (WebSocket + binary)
- [x] **Kid-friendly Mobile UI** (Duolingo-inspired design)
- [ ] **Random Word Generation** (3/5/7 words system)
- [ ] **AI Story Evaluation** (LLM scoring system)
- [ ] **User Progress Tracking** (history, achievements)

### Architecture Goals:
- [x] **Microservices Design** (NestJS + FastAPI separation)
- [x] **Scalable WebSocket Architecture** 
- [x] **Modern Tech Stack** (TypeScript, Python, Flutter)
- [x] **Docker Containerization** (FastAPI ready)
- [ ] **Production Deployment** (not configured yet)

## 🔮 Future Enhancements

### Technical Improvements:
- Redis caching for session management
- BullMQ for background job processing
- S3/MinIO for audio file storage
- Kubernetes deployment configuration
- CI/CD pipeline setup

### Feature Extensions:
- Multi-language support
- Voice cloning/character voices
- Story sharing and social features
- Parent dashboard and analytics
- Offline mode capability

---

**Status:** Core architecture complete, ready for integration testing and feature development.  
**Next Session:** Start with testing all three services and implementing the missing random words + LLM evaluation features.