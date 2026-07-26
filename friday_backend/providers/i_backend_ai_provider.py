from abc import ABC, abstractmethod
from typing import Dict, Any, List

class IBackendAIProvider(ABC):
    """Abstract Base Class for Flask Backend AI Providers."""

    @property
    @abstractmethod
    def provider_id(self) -> str:
        pass

    @abstractmethod
    def detect_intent(self, text: str) -> Dict[str, Any]:
        """Analyse text and return structured intent JSON."""
        pass

    @abstractmethod
    def chat(self, message: str, history: List[Dict[str, str]] = None) -> str:
        """Send chat message with history context and return reply string."""
        pass
