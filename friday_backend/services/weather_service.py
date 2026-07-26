"""
Weather service — Phase 13 implementation.
Stub returns a mock response so the /weather route doesn't crash.
"""
from flask import request, jsonify
from utils.logger import get_logger

log = get_logger("weather")


def get_weather():
    """Fetch weather for ?location= query param. Phase 13 full implementation."""
    location = request.args.get("location", "Unknown")
    log.debug(f"Weather request for: {location} (stub)")
    # Phase 13: replace with real OpenWeatherMap call
    return jsonify({
        "location": location,
        "temperature": "--",
        "condition": "Phase 13 not yet implemented",
        "humidity": "--",
    })
