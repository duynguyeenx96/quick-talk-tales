from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # Server settings
    PORT: int = 5000
    HOST: str = "0.0.0.0"
    DEBUG: bool = True
    
    # Whisper model settings
    WHISPER_MODEL: str = "base"  # base, turbo, small, medium, large
    WHISPER_DEVICE: str = "cpu"  # cpu, cuda
    WHISPER_LANGUAGE: Optional[str] = "en"  # Auto-detect if None
    
    # Audio processing settings
    MAX_AUDIO_SIZE: int = 25 * 1024 * 1024  # 25MB
    SUPPORTED_FORMATS: list = ["mp3", "wav", "m4a", "ogg", "webm"]
    
    # Performance settings
    MAX_CONCURRENT_REQUESTS: int = 10
    REQUEST_TIMEOUT: int = 300  # 5 minutes
    
    # Cache settings (Redis)
    REDIS_URL: Optional[str] = None
    CACHE_TTL: int = 3600  # 1 hour
    
    # Groq API for story evaluation
    GROQ_API_KEY: Optional[str] = None
    EVALUATION_MODEL: str = "llama-3.3-70b-versatile"

    # Anthropic API (optional)
    ANTHROPIC_API_KEY: Optional[str] = None

    # Logging
    LOG_LEVEL: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()