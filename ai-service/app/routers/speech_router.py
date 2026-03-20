from fastapi import APIRouter, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
import logging
from typing import Dict, Any

from app.models.speech_models import AudioChunkRequest, AudioProcessResponse, SpeechProcessor

logger = logging.getLogger(__name__)

router = APIRouter()

# Global speech processor instance (will be injected)
speech_processor: SpeechProcessor = None


def get_speech_processor() -> SpeechProcessor:
    """Get the global speech processor instance"""
    from app.main import speech_processor as global_processor
    return global_processor


@router.post("/process-audio", response_model=AudioProcessResponse)
async def process_audio_chunk(request: AudioChunkRequest):
    """
    Process audio chunk for real-time transcription
    
    This endpoint receives base64-encoded audio chunks and returns
    the transcribed text using Whisper.
    """
    try:
        processor = get_speech_processor()
        
        if not processor or not processor.is_ready:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        logger.info(f"Processing audio chunk for session: {request.sessionId}")
        
        # Process the audio chunk
        result = await processor.process_audio_chunk(request)
        
        logger.info(f"Transcription completed: '{result.text[:50]}...' "
                   f"(confidence: {result.confidence:.2f})")
        
        return result
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        logger.error(f"Error processing audio chunk: {e}")
        raise HTTPException(status_code=500, detail="Audio processing failed")


@router.post("/process-final-audio", response_model=AudioProcessResponse)
async def process_final_audio(request: AudioChunkRequest):
    """
    Process final audio for complete transcription
    
    This endpoint processes the final audio submission, potentially
    combining all chunks from a session for the most accurate transcription.
    """
    try:
        processor = get_speech_processor()
        
        if not processor or not processor.is_ready:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        logger.info(f"Processing final audio for session: {request.sessionId}")
        
        # Process final audio
        result = await processor.process_final_audio(request)
        
        logger.info(f"Final transcription completed: '{result.text[:100]}...' "
                   f"(confidence: {result.confidence:.2f}, "
                   f"processing_time: {result.processing_time:.2f}s)")
        
        return result
        
    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        logger.error(f"Error processing final audio: {e}")
        raise HTTPException(status_code=500, detail="Final audio processing failed")


@router.get("/sessions/{session_id}/status")
async def get_session_status(session_id: str) -> Dict[str, Any]:
    """
    Get status of a processing session
    
    Returns information about the current session including
    number of processed chunks and session state.
    """
    try:
        processor = get_speech_processor()
        
        if not processor:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        # Get session info
        session_buffer = processor.session_buffers.get(session_id, [])
        
        return {
            "session_id": session_id,
            "chunks_processed": len(session_buffer),
            "status": "active" if session_buffer else "inactive",
            "processor_ready": processor.is_ready
        }
        
    except Exception as e:
        logger.error(f"Error getting session status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get session status")


@router.delete("/sessions/{session_id}")
async def clear_session(session_id: str) -> Dict[str, str]:
    """
    Clear session data
    
    Removes all buffered audio data for a session.
    """
    try:
        processor = get_speech_processor()
        
        if not processor:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        # Clear session buffer
        if session_id in processor.session_buffers:
            del processor.session_buffers[session_id]
            logger.info(f"Cleared session: {session_id}")
        
        return {"message": f"Session {session_id} cleared successfully"}
        
    except Exception as e:
        logger.error(f"Error clearing session: {e}")
        raise HTTPException(status_code=500, detail="Failed to clear session")


@router.get("/models/info")
async def get_model_info() -> Dict[str, Any]:
    """
    Get information about the loaded Whisper model
    """
    try:
        processor = get_speech_processor()
        
        if not processor:
            raise HTTPException(
                status_code=503, 
                detail="Speech processing service unavailable"
            )
        
        return {
            "model_name": processor.model_name,
            "device": processor.device,
            "language": processor.language,
            "is_ready": processor.is_ready,
            "active_sessions": len(processor.session_buffers)
        }
        
    except Exception as e:
        logger.error(f"Error getting model info: {e}")
        raise HTTPException(status_code=500, detail="Failed to get model info")