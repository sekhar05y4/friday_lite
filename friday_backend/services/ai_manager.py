"""
AI Manager abstraction — backend equivalent of IAIProvider.
Concrete implementations (GeminiProvider, etc.) implement this interface.
"""
from abc import ABC, abstractmethod
from typing import Any


class AIProvider(ABC):
    """Abstract base for all AI provider implementations."""

    @abstractmethod
    def chat(self, message: str, history: list[dict]) -> str:
        """Return a plain-text chat reply."""

    @abstractmethod
    def detect_intent(self, text: str) -> dict[str, Any]:
        """
        Return a structured intent dict:
        {
            "intent": str,
            "parameters": dict,
            "speech_response": str,
            "confidence": float,
            "requires_confirmation": bool
        }
        """
