from fastapi import APIRouter, HTTPException, File, UploadFile, Form, BackgroundTasks
from fastapi.responses import JSONResponse
import logging
from typing import Dict, Any, Optional
import tempfile
import os

from app.models.speech_models import AudioProcessResponse, SpeechProcessor

logger = logging.getLogger(__name__)

router = APIRouter()


def get_speech_processor() -> SpeechProcessor:
    """Get the global speech processor instance"""
    from app.main import speech_processor as global_processor
    return global_processor


@router.post("/process-audio-binary", response_model=AudioProcessResponse)
async def process_audio_binary(
    audio: UploadFile = File(..., description="Audio file to process"),
    sessionId: str = Form(..., description="Session ID"),
    challengeId: str = Form(..., description="Challenge ID"),
    timestamp: Optional[str] = Form(None, description="Timestamp")
):
    """
    Process binary audio file for real-time transcription
    
    This endpoint receives binary audio files and returns
    the transcribed text using Whisper.
    """
    try:
        processor = get_speech_processor()
        
        if not processor or not processor.is_ready:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        # Validate audio file
        if not audio.content_type or not audio.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=400,
                detail="Invalid audio file format"
            )
        
        logger.info(f"Processing binary audio for session: {sessionId}")
        
        # Read audio file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            audio_content = await audio.read()
            temp_file.write(audio_content)
            temp_file_path = temp_file.name
        
        try:
            # Process the audio file
            result = await processor.process_audio_file(
                temp_file_path,
                sessionId,
                challengeId
            )
            
            logger.info(f"Binary transcription completed: '{result.text[:50]}...' "
                       f"(confidence: {result.confidence:.2f})")
            
            return result
            
        finally:
            # Cleanup temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        logger.error(f"Error processing binary audio: {e}")
        raise HTTPException(status_code=500, detail="Binary audio processing failed")


@router.post("/process-final-audio-binary", response_model=AudioProcessResponse)
async def process_final_audio_binary(
    audio: UploadFile = File(..., description="Final audio file to process"),
    sessionId: str = Form(..., description="Session ID"),
    challengeId: str = Form(..., description="Challenge ID"),
    timestamp: Optional[str] = Form(None, description="Timestamp")
):
    """
    Process final binary audio file for complete transcription
    
    This endpoint processes the final audio file, potentially
    combining it with previous chunks for the most accurate transcription.
    """
    try:
        processor = get_speech_processor()
        
        if not processor or not processor.is_ready:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        # Validate audio file
        if not audio.content_type or not audio.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=400,
                detail="Invalid audio file format"
            )
        
        logger.info(f"Processing final binary audio for session: {sessionId}")
        
        # Read audio file to temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            audio_content = await audio.read()
            temp_file.write(audio_content)
            temp_file_path = temp_file.name
        
        try:
            # Process the final audio file
            result = await processor.process_final_audio_file(
                temp_file_path,
                sessionId,
                challengeId
            )
            
            logger.info(f"Final binary transcription completed: '{result.text[:100]}...' "
                       f"(confidence: {result.confidence:.2f}, "
                       f"processing_time: {result.processing_time:.2f}s)")
            
            return result
            
        finally:
            # Cleanup temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        logger.error(f"Error processing final binary audio: {e}")
        raise HTTPException(status_code=500, detail="Final binary audio processing failed")