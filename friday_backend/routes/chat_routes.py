from flask import Blueprint
from handlers.intent_handler import handle_chat

chat_bp = Blueprint("chat", __name__)

@chat_bp.post("/chat")
def chat():
    return handle_chat()
