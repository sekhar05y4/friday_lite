"""
FRIDAY Lite Backend — Structured Logger
All backend logging goes through here.
In production, set LOG_LEVEL=ERROR in your environment.
"""
import logging
import os

_level = os.getenv("LOG_LEVEL", "DEBUG").upper()

logging.basicConfig(
    level=getattr(logging, _level, logging.DEBUG),
    format="[FRIDAY/%(name)s] %(levelname)s — %(message)s",
)


def get_logger(name: str) -> logging.Logger:
    """Return a categorised logger for the given module name."""
    return logging.getLogger(name)
