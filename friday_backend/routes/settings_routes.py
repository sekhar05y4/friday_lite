from flask import Blueprint, jsonify
from config.settings import config

settings_bp = Blueprint("settings", __name__)

@settings_bp.get("/settings")
def settings():
    return jsonify({
        "gemini_model": config.GEMINI_MODEL,
        "default_location": config.DEFAULT_LOCATION,
        "ai_provider": "gemini",
        "has_api_key": bool(config.GEMINI_API_KEY),
    })
