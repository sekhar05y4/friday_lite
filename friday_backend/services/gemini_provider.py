"""
GeminiProvider — full implementation added in Phase 7.
Stub included so app.py can import the handler without crashing.
"""
from .ai_manager import AIProvider
from config.settings import config
from utils.logger import get_logger

log = get_logger("gemini")


class GeminiProvider(AIProvider):
    """Google Gemini AI provider. Implemented in Phase 7."""

    def __init__(self):
        self._client = None
        self._model = None
        log.debug("GeminiProvider: stub initialised (Phase 7 will configure client)")

    def chat(self, message: str, history: list[dict]) -> str:
        # Phase 7 implementation
        raise NotImplementedError("GeminiProvider.chat — implemented in Phase 7")

    def detect_intent(self, text: str) -> dict:
        # Phase 7 implementation
        raise NotImplementedError("GeminiProvider.detect_intent — implemented in Phase 7")
