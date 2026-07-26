from flask import Blueprint
from handlers.intent_handler import handle_intent

intent_bp = Blueprint("intent", __name__)

@intent_bp.post("/intent")
def detect_intent():
    return handle_intent()
