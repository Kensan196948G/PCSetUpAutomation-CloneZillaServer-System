"""Flask application factory."""
import os
import logging
from pathlib import Path
from flask import Flask
from flask_cors import CORS
from config import config
from models import db


def create_app(config_name=None):
    """Create and configure Flask application.

    Args:
        config_name: Configuration name (development/production/testing)

    Returns:
        Flask application instance
    """
    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')

    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)

    # Setup CORS if enabled
    if app.config.get('CORS_ENABLED'):
        CORS(app, origins=app.config.get('CORS_ORIGINS'))

    # Setup logging
    setup_logging(app)

    # Register blueprints
    register_blueprints(app)

    # Create database tables
    with app.app_context():
        db.create_all()

    # Register error handlers
    register_error_handlers(app)

    # Register CLI commands
    register_commands(app)

    return app


def setup_logging(app):
    """Setup application logging.

    Args:
        app: Flask application instance
    """
    log_level = getattr(logging, app.config['LOG_LEVEL'].upper())
    log_file = app.config['LOG_FILE']

    # Create logs directory if not exists
    log_dir = Path(log_file).parent
    log_dir.mkdir(parents=True, exist_ok=True)

    # Configure logging
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

    app.logger.setLevel(log_level)
    app.logger.info(f'Application started in {app.config["ENV"]} mode')


def register_blueprints(app):
    """Register Flask blueprints.

    Args:
        app: Flask application instance
    """
    from api import api_bp
    from views import views_bp

    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(views_bp, url_prefix='/')


def register_error_handlers(app):
    """Register error handlers.

    Args:
        app: Flask application instance
    """
    @app.errorhandler(404)
    def not_found(error):
        return {'error': 'Not found'}, 404

    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        app.logger.error(f'Internal error: {error}')
        return {'error': 'Internal server error'}, 500


def register_commands(app):
    """Register CLI commands.

    Args:
        app: Flask application instance
    """
    @app.cli.command()
    def init_db():
        """Initialize database."""
        db.create_all()
        print('Database initialized.')

    @app.cli.command()
    def drop_db():
        """Drop all database tables."""
        if input('Are you sure? (yes/no): ').lower() == 'yes':
            db.drop_all()
            print('Database dropped.')
        else:
            print('Cancelled.')


if __name__ == '__main__':
    app = create_app()
    app.run(
        host=app.config['API_HOST'],
        port=app.config['API_PORT'],
        debug=app.config['DEBUG']
    )
