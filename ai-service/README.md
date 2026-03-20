# AI Service — FastAPI

Speech-to-text and story evaluation microservice for Quick Talk Tales. Transcribes user audio using OpenAI Whisper (local) and evaluates submitted stories using the Groq LLM API.

## Tech Stack

- **Framework:** FastAPI (Python 3.11)
- **Speech-to-Text:** OpenAI Whisper (runs locally, no API key needed)
- **LLM Evaluation:** Groq API
- **Server:** Uvicorn (ASGI)
- **Audio Processing:** librosa, soundfile, FFmpeg
- **Port:** 5001

## Prerequisites

- Python ≥ 3.11
- FFmpeg (`brew install ffmpeg` / `apt install ffmpeg`)
- A [Groq API key](https://console.groq.com)

## Setup

### 1. Create a virtual environment

```bash
python -m venv .venv
source .venv/bin/activate        # macOS/Linux
# .venv\Scripts\activate         # Windows
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

> **Note:** The first run will download the Whisper model (~74 MB for `base`). This happens automatically.

### 3. Configure environment

```bash
cp .env.example .env
```

Fill in `.env`:

| Variable | Description |
|----------|-------------|
| `GROQ_API_KEY` | API key from [console.groq.com](https://console.groq.com) |
| `WHISPER_MODEL` | `tiny` · `base` · `small` · `medium` · `large` · `turbo` |
| `WHISPER_DEVICE` | `cpu` or `cuda` (if GPU available) |
| `WHISPER_LANGUAGE` | Language code, e.g. `en` |
| `PORT` | Server port (default: `5001`) |

**Whisper model guide:**

| Model | Size | Speed | Accuracy | Use case |
|-------|------|-------|----------|----------|
| `tiny` | 39 MB | Fastest | Low | Quick tests |
| `base` | 74 MB | Fast | Good | Development |
| `turbo` | 809 MB | Fast | High | Production |
| `large` | 1.5 GB | Slow | Best | High-accuracy |

### 4. Run

```bash
uvicorn app.main:app --host 0.0.0.0 --port 5001 --reload
```

The service starts at `http://localhost:5001`.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/api/v1/process-audio` | Transcribe base64-encoded audio |
| `POST` | `/api/v1/process-final-audio` | Transcribe final audio chunk |
| `GET` | `/api/v1/models/info` | Loaded Whisper model info |

Interactive docs: `http://localhost:5001/docs`

## Docker

```bash
docker build -t quick-talk-tales-ai .
docker run -p 5001:5001 --env-file .env quick-talk-tales-ai
```
