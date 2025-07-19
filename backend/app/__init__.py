# el-ultimo-bastion/backend/app/__init__.py

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from config import Config

db = SQLAlchemy()
migrate = Migrate()

def create_app(test_config=None):
    app = Flask(__name__)
    if test_config:
        app.config.from_mapping(test_config)
    else:
        app.config.from_object(Config)

    db.init_app(app)
    migrate.init_app(app, db)

    # Importa los modelos para que Flask-Migrate los detecte
    from . import models

    # Importa y registra Blueprints (inicialmente solo placeholders)
    from .api.admin_routes import admin_bp
    app.register_blueprint(admin_bp, url_prefix='/api/v1/admin')

    # Configuración CORS
    frontend_url = app.config.get('FRONTEND_URL')
    if app.config.get('TESTING'): # En entorno de testing, permite todo
        CORS(app)
    elif frontend_url:
        CORS(app, resources={r"/api/*": {"origins": frontend_url}}, methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"], supports_credentials=True)
    else:
        print("ADVERTENCIA: FRONTEND_URL no definida. CORS menos restrictivo.")
        CORS(app)

    @app.route('/')
    def index():
        return "Backend de El Último Bastión está funcionando!"

    return app