from flask import request, jsonify
from services.ai_service import ai_service
from memory.conversation_memory import memory_store
from utils.logger import get_logger

log = get_logger("intent_handler")

def handle_intent():
    """Handle POST /intent endpoint."""
    try:
        data = request.get_json(silent=True) or {}
        text = data.get("text", "").strip()

        if not text:
            return jsonify({
                "status": "error",
                "message": "Missing 'text' parameter in request body."
            }), 400

        result = ai_service.process_intent(text)
        memory_store.add_entry("user", text)
        memory_store.add_entry("assistant", result.get("speech_response", ""))

        return jsonify(result)
    except Exception as e:
        log.error(f"Error handling intent: {e}")
        return jsonify({
            "status": "error",
            "message": "Internal server error processing intent."
        }), 500


def handle_chat():
    """Handle POST /chat endpoint."""
    try:
        data = request.get_json(silent=True) or {}
        message = data.get("message", "").strip()
        history = data.get("history", [])

        if not message:
            return jsonify({
                "status": "error",
                "message": "Missing 'message' parameter in request body."
            }), 400

        reply = ai_service.process_chat(message, history)
        memory_store.add_entry("user", message)
        memory_store.add_entry("assistant", reply)

        return jsonify({
            "reply": reply,
            "status": "ok"
        })
    except Exception as e:
        log.error(f"Error handling chat: {e}")
        return jsonify({
            "status": "error",
            "message": "Internal server error processing chat."
        }), 500
