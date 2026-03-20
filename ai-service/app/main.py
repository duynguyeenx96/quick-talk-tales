from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import logging
from contextlib import asynccontextmanager

from app.models.speech_models import SpeechProcessor
from app.routers import speech_router, speech_binary_router
from app.routers import evaluation_router
from app.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Initialize global speech processor
speech_processor = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan events for FastAPI application"""
    global speech_processor
    
    # Startup
    logger.info("Starting Quick Talk Tales AI Service...")
    speech_processor = SpeechProcessor()
    await speech_processor.initialize()
    logger.info("Speech processor initialized successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down AI Service...")
    if speech_processor:
        await speech_processor.cleanup()
    logger.info("AI Service shutdown complete")


# Create FastAPI application
app = FastAPI(
    title="Quick Talk Tales AI Service",
    description="Microservice for speech-to-text processing using Whisper",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure as needed for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    global speech_processor
    
    status = "healthy" if speech_processor and speech_processor.is_ready else "unhealthy"
    
    return {
        "status": status,
        "service": "Quick Talk Tales AI Service",
        "version": "1.0.0",
        "whisper_model": speech_processor.model_name if speech_processor else None
    }


# Include routers
app.include_router(speech_router.router, prefix="/api/v1", tags=["Speech Processing"])
app.include_router(speech_binary_router.router, prefix="/api/v1", tags=["Binary Speech Processing"])
app.include_router(evaluation_router.router, prefix="/api/v1", tags=["Story Evaluation"])


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Global exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": "Something went wrong processing your request"
        }
    )


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )