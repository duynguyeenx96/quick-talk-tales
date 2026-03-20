import whisper
import asyncio
import tempfile
import base64
import os
import logging
from typing import Dict, Optional, Tuple
from pydantic import BaseModel
import soundfile as sf
import numpy as np
from io import BytesIO

from app.config import settings

logger = logging.getLogger(__name__)


class AudioChunkRequest(BaseModel):
    """Request model for audio chunk processing"""
    audioData: str  # base64 encoded audio
    sessionId: str
    challengeId: str
    timestamp: int


class AudioProcessResponse(BaseModel):
    """Response model for audio processing"""
    text: str
    confidence: float
    processing_time: float
    session_id: str


class SpeechProcessor:
    """Speech processing class using OpenAI Whisper"""
    
    def __init__(self):
        self.model = None
        self.model_name = settings.WHISPER_MODEL
        self.device = settings.WHISPER_DEVICE
        self.language = settings.WHISPER_LANGUAGE
        self.is_ready = False
        self.session_buffers = {}  # Store audio buffers per session
        
    async def initialize(self):
        """Initialize Whisper model"""
        try:
            logger.info(f"Loading Whisper model: {self.model_name}")
            # Run in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            self.model = await loop.run_in_executor(
                None, 
                whisper.load_model, 
                self.model_name, 
                self.device
            )
            
            self.is_ready = True
            logger.info(f"Whisper model {self.model_name} loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load Whisper model: {e}")
            raise
    
    async def cleanup(self):
        """Cleanup resources"""
        self.session_buffers.clear()
        self.model = None
        self.is_ready = False
        logger.info("Speech processor cleaned up")
    
    def _decode_audio_data(self, base64_data: str) -> np.ndarray:
        """Decode base64 audio data to numpy array"""
        try:
            # Remove data URL prefix if present
            if "," in base64_data:
                base64_data = base64_data.split(",")[1]
            
            # Decode base64
            audio_bytes = base64.b64decode(base64_data)
            
            # Convert to numpy array using soundfile
            with BytesIO(audio_bytes) as audio_buffer:
                audio_data, sample_rate = sf.read(audio_buffer)
                
            # Ensure mono and correct sample rate for Whisper (16kHz)
            if len(audio_data.shape) > 1:
                audio_data = np.mean(audio_data, axis=1)
            
            # Resample to 16kHz if needed
            if sample_rate != 16000:
                # Simple resampling (for production, use proper resampling)
                target_length = int(len(audio_data) * 16000 / sample_rate)
                audio_data = np.interp(
                    np.linspace(0, len(audio_data), target_length),
                    np.arange(len(audio_data)),
                    audio_data
                )
            
            return audio_data.astype(np.float32)
            
        except Exception as e:
            logger.error(f"Failed to decode audio data: {e}")
            raise ValueError("Invalid audio data format")
    
    async def process_audio_chunk(self, request: AudioChunkRequest) -> AudioProcessResponse:
        """Process a single audio chunk"""
        if not self.is_ready:
            raise RuntimeError("Speech processor not initialized")
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            # Decode audio data
            audio_data = self._decode_audio_data(request.audioData)
            
            # Add to session buffer (for future use with streaming)
            if request.sessionId not in self.session_buffers:
                self.session_buffers[request.sessionId] = []
            
            self.session_buffers[request.sessionId].append(audio_data)
            
            # Process with Whisper
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._transcribe_audio,
                audio_data
            )
            
            processing_time = asyncio.get_event_loop().time() - start_time
            
            return AudioProcessResponse(
                text=result["text"].strip(),
                confidence=self._calculate_confidence(result),
                processing_time=processing_time,
                session_id=request.sessionId
            )
            
        except Exception as e:
            logger.error(f"Error processing audio chunk: {e}")
            raise
    
    def _transcribe_audio(self, audio_data: np.ndarray) -> Dict:
        """Transcribe audio using Whisper model"""
        try:
            # Whisper transcription
            result = self.model.transcribe(
                audio_data,
                language=self.language,
                fp16=False,  # Use fp32 for better compatibility
                verbose=False
            )
            return result
            
        except Exception as e:
            logger.error(f"Whisper transcription failed: {e}")
            raise
    
    def _calculate_confidence(self, result: Dict) -> float:
        """Calculate confidence score from Whisper result"""
        try:
            if "segments" in result and result["segments"]:
                # Average confidence across segments
                confidences = []
                for segment in result["segments"]:
                    if "avg_logprob" in segment:
                        # Convert log probability to confidence (0-1)
                        confidence = np.exp(segment["avg_logprob"])
                        confidences.append(confidence)
                
                if confidences:
                    return float(np.mean(confidences))
            
            # Fallback confidence based on text length and quality
            text = result.get("text", "").strip()
            if len(text) > 0:
                return 0.85  # Reasonable default
            else:
                return 0.1
                
        except Exception:
            return 0.5  # Default confidence
    
    async def process_final_audio(self, request: AudioChunkRequest) -> AudioProcessResponse:
        """Process final audio for a session (combine all chunks)"""
        if not self.is_ready:
            raise RuntimeError("Speech processor not initialized")
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            # Get session buffer
            session_audio = self.session_buffers.get(request.sessionId, [])
            
            if not session_audio:
                # Process single chunk if no buffer
                audio_data = self._decode_audio_data(request.audioData)
            else:
                # Combine all audio chunks
                audio_data = np.concatenate(session_audio)
            
            # Process with Whisper
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._transcribe_audio,
                audio_data
            )
            
            processing_time = asyncio.get_event_loop().time() - start_time
            
            # Clean up session buffer
            if request.sessionId in self.session_buffers:
                del self.session_buffers[request.sessionId]
            
            return AudioProcessResponse(
                text=result["text"].strip(),
                confidence=self._calculate_confidence(result),
                processing_time=processing_time,
                session_id=request.sessionId
            )
            
        except Exception as e:
            logger.error(f"Error processing final audio: {e}")
            raise
    
    async def process_audio_file(
        self, 
        file_path: str, 
        session_id: str, 
        challenge_id: str
    ) -> AudioProcessResponse:
        """Process audio file directly from file path"""
        if not self.is_ready:
            raise RuntimeError("Speech processor not initialized")
        
        start_time = asyncio.get_event_loop().time()
        
        try:
            logger.info(f"Processing audio file: {file_path}")
            
            # Process with Whisper directly from file
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._transcribe_audio_file,
                file_path
            )
            
            processing_time = asyncio.get_event_loop().time() - start_time
            
            return AudioProcessResponse(
                text=result["text"].strip(),
                confidence=self._calculate_confidence(result),
                processing_time=processing_time,
                session_id=session_id
            )
            
        except Exception as e:
            logger.error(f"Error processing audio file: {e}")
            raise
    
    async def process_final_audio_file(
        self, 
        file_path: str, 
        session_id: str, 
        challenge_id: str
    ) -> AudioProcessResponse:
        """Process final audio file, cleaning up session"""
        try:
            result = await self.process_audio_file(file_path, session_id, challenge_id)
            
            # Clean up session buffer
            if session_id in self.session_buffers:
                del self.session_buffers[session_id]
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing final audio file: {e}")
            raise
    
    def _transcribe_audio_file(self, file_path: str) -> Dict:
        """Transcribe audio file using Whisper model"""
        try:
            # Whisper can handle file paths directly
            result = self.model.transcribe(
                file_path,
                language=self.language,
                fp16=False,  # Use fp32 for better compatibility
                verbose=False
            )
            return result
            
        except Exception as e:
            logger.error(f"Whisper file transcription failed: {e}")
            raise