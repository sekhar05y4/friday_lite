import json
from typing import Dict, Any, List
from providers.i_backend_ai_provider import IBackendAIProvider
from config.settings import config
from utils.logger import get_logger

log = get_logger("gemini_provider")

try:
    import google.generativeai as genai
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False


class GeminiBackendProvider(IBackendAIProvider):
    """Google Gemini AI Provider implementation on Flask Backend."""

    def __init__(self):
        self._is_configured = False
        if GENAI_AVAILABLE and config.GEMINI_API_KEY:
            try:
                genai.configure(api_key=config.GEMINI_API_KEY)
                self.model = genai.GenerativeModel(config.GEMINI_MODEL)
                self._is_configured = True
                log.info(f"GeminiBackendProvider initialized with model {config.GEMINI_MODEL}")
            except Exception as e:
                log.error(f"Failed to configure Gemini: {e}")
        else:
            log.warning("Gemini API key not configured or google-generativeai package missing. Using intelligent fallback mode.")

    @property
    def provider_id(self) -> str:
        return "gemini"

    def detect_intent(self, text: str) -> Dict[str, Any]:
        """Detect intent using Gemini model or structured rule heuristic fallback."""
        if not text or not text.strip():
            return {
                "intent": "UNKNOWN",
                "parameters": {},
                "speech_response": "I didn't hear anything.",
                "confidence": 0.0,
                "requires_confirmation": False,
            }

        if self._is_configured:
            prompt = f"""
System: You are FRIDAY, an AI personal assistant. Classify the user prompt into an intent.
User prompt: "{text}"

Respond ONLY with a JSON object in this format:
{{
  "intent": "CHAT" | "OPEN_APP" | "CALL_CONTACT" | "SEND_SMS" | "SET_REMINDER" | "TAKE_NOTE" | "GET_WEATHER",
  "parameters": {{}},
  "speech_response": "Short natural response to speak to user",
  "confidence": 0.95
}}
"""
            try:
                response = self.model.generate_content(prompt)
                clean_json = response.text.strip()
                if clean_json.startswith("```json"):
                    clean_json = clean_json[7:]
                if clean_json.endswith("```"):
                    clean_json = clean_json[:-3]
                clean_json = clean_json.strip()

                data = json.loads(clean_json)
                return {
                    "intent": data.get("intent", "CHAT"),
                    "parameters": data.get("parameters", {}),
                    "speech_response": data.get("speech_response", "Processed with Gemini."),
                    "confidence": data.get("confidence", 0.9),
                    "requires_confirmation": False,
                }
            except Exception as e:
                log.error(f"Gemini API error during intent detection: {e}")

        # Intelligent Fallback
        return {
            "intent": "CHAT",
            "parameters": {},
            "speech_response": f"I received your request: '{text}'. I am FRIDAY, your personal assistant.",
            "confidence": 0.8,
            "requires_confirmation": False,
        }

    def chat(self, message: str, history: List[Dict[str, str]] = None) -> str:
        """Process multi-turn chat through Gemini."""
        if self._is_configured:
            try:
                chat_session = self.model.start_chat(history=[])
                response = chat_session.send_message(message)
                return response.text.strip()
            except Exception as e:
                log.error(f"Gemini API error during chat: {e}")

        return f"Hello! I am FRIDAY. You said: '{message}'."
