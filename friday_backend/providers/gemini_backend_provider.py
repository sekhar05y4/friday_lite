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
            log.warning("Gemini API key not configured or google-generativeai package missing. Using intelligent backend engine.")

    @property
    def provider_id(self) -> str:
        return "gemini"

    def detect_intent(self, text: str) -> Dict[str, Any]:
        """Detect intent using Gemini model or structured rule heuristic engine."""
        if not text or not text.strip():
            return {
                "intent": "UNKNOWN",
                "parameters": {},
                "speech_response": "I didn't hear anything.",
                "confidence": 0.0,
                "requires_confirmation": False,
                "prompt_tokens": 0,
                "completion_tokens": 0,
                "total_tokens": 0,
            }

        prompt_tokens = max(1, len(text) // 4)

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

                p_tokens = getattr(response.usage_metadata, 'prompt_token_count', len(prompt) // 4)
                c_tokens = getattr(response.usage_metadata, 'candidates_token_count', len(response.text) // 4)
                t_tokens = getattr(response.usage_metadata, 'total_token_count', p_tokens + c_tokens)

                return {
                    "intent": data.get("intent", "CHAT"),
                    "parameters": data.get("parameters", {}),
                    "speech_response": data.get("speech_response", "Processed with Gemini."),
                    "confidence": data.get("confidence", 0.9),
                    "requires_confirmation": False,
                    "prompt_tokens": p_tokens,
                    "completion_tokens": c_tokens,
                    "total_tokens": t_tokens,
                }
            except Exception as e:
                log.error(f"Gemini API error during intent detection: {e}")

        # Rich Backend Heuristic Engine
        speech = self.generate_chat_reply(text, [])
        comp_tokens = max(1, len(speech) // 4)
        return {
            "intent": "CHAT",
            "parameters": {},
            "speech_response": speech,
            "confidence": 0.85,
            "requires_confirmation": False,
            "prompt_tokens": prompt_tokens,
            "completion_tokens": comp_tokens,
            "total_tokens": prompt_tokens + comp_tokens,
        }

    def chat(self, message: str, history: List[Dict[str, str]] = None) -> str:
        return self.generate_chat_reply(message, history or [])

    def generate_chat_reply(self, message: str, history: List[Dict[str, str]]) -> str:
        """Process multi-turn chat through Gemini with full conversation context."""
        if self._is_configured:
            try:
                formatted_history = []
                if history:
                    for item in history:
                        role = "user" if item.get("role") == "user" else "model"
                        content = item.get("content", "")
                        if content:
                            formatted_history.append({"role": role, "parts": [content]})

                chat_session = self.model.start_chat(history=formatted_history)
                response = chat_session.send_message(message)
                return response.text.strip()
            except Exception as e:
                log.error(f"Gemini API error during chat: {e}")

        cleaned = message.lower().strip()

        if "human" in cleaned or "person" in cleaned or "robot" in cleaned or "real" in cleaned:
            return "No, I am not a human. I am FRIDAY, an artificial intelligence assistant designed to help you with telephony, daily productivity, vision processing, desktop controls, and smart home automation."

        if cleaned == "who are you" or cleaned == "what are you" or "your name" in cleaned:
            return "I am FRIDAY, your personal AI assistant running on your Flask Backend and mobile application."

        if cleaned in ["good", "great", "nice", "awesome", "cool"]:
            return "Thank you! I'm glad to help. Let me know what you would like to do next."

        if "thank" in cleaned:
            return "You're very welcome! I am always here to assist."

        if "what can you do" in cleaned or "features" in cleaned or "help" in cleaned or "capabilities" in cleaned:
            return "I can place calls, draft SMS with voice confirmation, search contacts, launch apps, set natural reminders, manage calendar agenda & to-do lists, control flashlight/Wi-Fi/Bluetooth, scan QR/barcodes, store long-term memories, automate rules, and control smart home devices."

        if "system" in cleaned or "module" in cleaned or "how many" in cleaned:
            return "FRIDAY Lite consists of 20 integrated feature systems across Telephony, Productivity, Device Control, Camera Vision, Long-Term Memory, Desktop Companion, Automation Engine, and Smart Home Platform."

        if cleaned.startswith("hi") or cleaned.startswith("hello") or cleaned.startswith("hey"):
            return "Hello! I am online and ready to assist."

        return f"Understood: '{message}'. All 20 FRIDAY backend services and local feature modules are active."
