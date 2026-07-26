from typing import List, Dict, Any

class ConversationMemory:
    """In-memory conversation buffer for the Flask backend."""

    def __init__(self, max_history: int = 20):
        self.max_history = max_history
        self._history: List[Dict[str, str]] = []

    def add_entry(self, role: str, content: str):
        self._history.append({"role": role, "content": content})
        if len(self._history) > self.max_history:
            self._history.pop(0)

    def get_history(self) -> List[Dict[str, str]]:
        return list(self._history)

    def clear(self):
        self._history.clear()

memory_store = ConversationMemory()
