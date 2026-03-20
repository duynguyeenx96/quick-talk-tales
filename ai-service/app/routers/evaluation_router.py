from fastapi import APIRouter, HTTPException
import json
import logging
import random
from pydantic import BaseModel
from typing import Optional

from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


def _mock_evaluate(story_text: str, target_words: list[str]) -> dict:
    """Return a realistic mock evaluation without calling any LLM."""
    story_lower = story_text.lower()
    words_used = [w for w in target_words if w.lower() in story_lower]
    words_missing = [w for w in target_words if w.lower() not in story_lower]

    word_usage = int(len(words_used) / max(len(target_words), 1) * 100)
    grammar = random.randint(65, 90)
    creativity = random.randint(60, 88)
    coherence = random.randint(62, 85)
    overall = int(grammar * 0.25 + creativity * 0.30 + coherence * 0.25 + word_usage * 0.20)

    feedbacks = [
        "Your story has a wonderful imagination! Try to use more descriptive words to paint a vivid picture. Keep practicing and your writing will get even better!",
        "Great effort on your story! Your ideas are creative and fun. Work on connecting your sentences more smoothly for an even better flow.",
        "You did a fantastic job telling your story! Try adding more details about how characters feel. You're making great progress!",
    ]
    encouragements = [
        "You're a storytelling superstar — keep it up! 🌟",
        "Amazing work! Every story you write makes you a better author! 📖",
        "Wonderful effort! The world needs your creative stories! ✨",
    ]

    return {
        "grammar": grammar,
        "creativity": creativity,
        "coherence": coherence,
        "word_usage": word_usage,
        "overall": overall,
        "words_used": words_used,
        "words_missing": words_missing,
        "feedback": random.choice(feedbacks),
        "encouragement": random.choice(encouragements),
    }


class EvaluateStoryRequest(BaseModel):
    story_text: str
    target_words: list[str]
    word_count: int = 5  # 3, 5, or 7


class EvaluationScores(BaseModel):
    grammar: int          # 0-100
    creativity: int       # 0-100
    coherence: int        # 0-100
    word_usage: int       # 0-100 (how many target words used)
    overall: int          # 0-100 weighted average


class EvaluateStoryResponse(BaseModel):
    scores: EvaluationScores
    words_used: list[str]
    words_missing: list[str]
    feedback: str
    encouragement: str


EVALUATION_SYSTEM_PROMPT = """You are a friendly English teacher evaluating stories written by children (ages 6-12).
Evaluate the story and respond ONLY with a valid JSON object — no extra text, no markdown.

JSON format:
{
  "grammar": <0-100>,
  "creativity": <0-100>,
  "coherence": <0-100>,
  "word_usage": <0-100>,
  "words_used": ["word1", "word2"],
  "words_missing": ["word3"],
  "feedback": "<2-3 sentences of constructive, age-appropriate feedback>",
  "encouragement": "<1 short encouraging sentence>"
}

Scoring guide:
- grammar: correctness of sentences, punctuation, subject-verb agreement
- creativity: originality, imagination, interesting plot or ideas
- coherence: logical flow, clear beginning/middle/end
- word_usage: percentage of target_words meaningfully incorporated (not just mentioned)
- overall: NOT included in JSON, will be computed separately

Be kind and encouraging. Use simple language suitable for children."""


@router.post("/evaluate-story", response_model=EvaluateStoryResponse)
async def evaluate_story(request: EvaluateStoryRequest):
    """Evaluate a child's story. Uses LLM if API key is set, otherwise returns a mock result."""
    if len(request.story_text.strip()) < 20:
        raise HTTPException(
            status_code=400,
            detail="Story is too short. Please write at least a few sentences."
        )

    # --- Mock mode (no API key configured) ---
    if not settings.GROQ_API_KEY:
        logger.info("GROQ_API_KEY not set — using mock evaluation")
        data = _mock_evaluate(request.story_text, request.target_words)
        return EvaluateStoryResponse(
            scores=EvaluationScores(
                grammar=data["grammar"],
                creativity=data["creativity"],
                coherence=data["coherence"],
                word_usage=data["word_usage"],
                overall=data["overall"],
            ),
            words_used=data["words_used"],
            words_missing=data["words_missing"],
            feedback=data["feedback"],
            encouragement=data["encouragement"],
        )

    # --- Real LLM mode (Groq) ---
    from groq import Groq

    client = Groq(api_key=settings.GROQ_API_KEY)
    user_message = (
        f"Target words the child must use: {', '.join(request.target_words)}\n\n"
        f"Child's story:\n{request.story_text}"
    )

    try:
        response = client.chat.completions.create(
            model=settings.EVALUATION_MODEL,
            max_tokens=1024,
            messages=[
                {"role": "system", "content": EVALUATION_SYSTEM_PROMPT},
                {"role": "user", "content": user_message},
            ],
        )
        raw_text = response.choices[0].message.content

        data = json.loads(raw_text)

        grammar = int(data.get("grammar", 50))
        creativity = int(data.get("creativity", 50))
        coherence = int(data.get("coherence", 50))
        word_usage = int(data.get("word_usage", 0))
        overall = int(grammar * 0.25 + creativity * 0.30 + coherence * 0.25 + word_usage * 0.20)

        return EvaluateStoryResponse(
            scores=EvaluationScores(
                grammar=grammar,
                creativity=creativity,
                coherence=coherence,
                word_usage=word_usage,
                overall=overall,
            ),
            words_used=[w.lower() for w in data.get("words_used", [])],
            words_missing=[w.lower() for w in data.get("words_missing", [])],
            feedback=data.get("feedback", "Great effort!"),
            encouragement=data.get("encouragement", "Keep writing!"),
        )

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Groq response as JSON: {e}\nRaw: {raw_text}")
        raise HTTPException(status_code=500, detail="Evaluation service returned invalid response")
    except Exception as e:
        logger.error(f"Groq API error: {e}")
        raise HTTPException(status_code=502, detail="Story evaluation service temporarily unavailable")
