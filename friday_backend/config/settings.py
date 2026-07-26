"""
FRIDAY Lite Backend — Configuration
Loads all settings from environment variables (via python-dotenv).
All application code imports from here — never from os.environ directly.
"""
import os
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


class Config:
    # ── AI ────────────────────────────────────────────────────────────────────
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-1.5-flash-latest")

    # ── Weather ───────────────────────────────────────────────────────────────
    WEATHER_API_KEY: str = os.getenv("WEATHER_API_KEY", "")
    DEFAULT_LOCATION: str = os.getenv("DEFAULT_LOCATION", "London")

    # ── Flask ─────────────────────────────────────────────────────────────────
    FLASK_PORT: int = int(os.getenv("FLASK_PORT", "5000"))
    DEBUG: bool = os.getenv("FLASK_DEBUG", "true").lower() == "true"


config = Config()
