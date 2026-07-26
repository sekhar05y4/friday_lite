from typing import Dict, Any, List
from providers.gemini_backend_provider import GeminiBackendProvider
from providers.local_llm_provider import LocalLLMProvider
from utils.logger import get_logger

log = get_logger("ai_service")

class AIService:
    """Orchestrates AI providers on the backend."""

    def __init__(self):
        self._providers = {
            "gemini": GeminiBackendProvider(),
            "local_llm": LocalLLMProvider(),
        }
        self.active_provider_id = "gemini"
        log.info(f"AIService active provider: {self.active_provider_id}")

    @property
    def provider(self):
        return self._providers.get(self.active_provider_id, self._providers["gemini"])

    def set_provider(self, provider_id: str):
        if provider_id in self._providers:
            self.active_provider_id = provider_id
            log.info(f"AIService: switched provider to {provider_id}")

    def process_intent(self, text: str) -> Dict[str, Any]:
        return self.provider.detect_intent(text)

    def process_chat(self, message: str, history: List[Dict[str, str]] = None) -> str:
        return self.provider.generate_chat_reply(message, history or [])

ai_service = AIService()
