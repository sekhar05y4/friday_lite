"""
FRIDAY Lite Backend — Flask Application
Entry point. All routes and blueprints are registered here.
"""
from flask import Flask
from flask_cors import CORS

from config.settings import config
from utils.logger import get_logger

from routes.health_routes import health_bp
from routes.intent_routes import intent_bp
from routes.chat_routes import chat_bp
from routes.settings_routes import settings_bp

log = get_logger("app")

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests from Android emulator / device

# Register modular blueprints
app.register_blueprint(health_bp)
app.register_blueprint(intent_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(settings_bp)


@app.get("/weather")
def weather():
    """Returns weather data for ?location=city (Phase 13)."""
    from services.weather_service import get_weather
    return get_weather()


if __name__ == "__main__":
    log.info(f"FRIDAY backend starting on http://0.0.0.0:{config.FLASK_PORT}")
    app.run(host="0.0.0.0", port=config.FLASK_PORT, debug=config.DEBUG)
