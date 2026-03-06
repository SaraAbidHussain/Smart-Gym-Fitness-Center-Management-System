"""
Flask Application Factory
Initializes app, database pool, and registers blueprints
"""

from flask import Flask, jsonify
from flask_cors import CORS
import psycopg2
from psycopg2 import pool
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


def create_app():
    """Create and configure Flask application"""
    
    # Initialize Flask app
    app = Flask(__name__)
    
    # Enable CORS (allow frontend to make requests)
    CORS(app, resources={
        r"/api/*": {
            "origins": "*",  # In production, specify your frontend domain
            "methods": ["GET", "POST", "PUT", "DELETE", "PATCH"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # Configuration
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
    app.config['JSON_SORT_KEYS'] = False  # Preserve JSON key order
    
    # Database configuration
    DB_CONFIG = {
        'database': os.getenv('DB_NAME', 'smart_gym'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', 'postgres'),
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432')
    }
    
    # Create database connection pool
    try:
        db_pool = psycopg2.pool.SimpleConnectionPool(
            minconn=1,
            maxconn=20,
            **DB_CONFIG
        )
        
        if db_pool:
            print("✅ Database connection pool created successfully")
        
        # Store pool in app config for access in blueprints
        app.config['DB_POOL'] = db_pool
        
    except Exception as e:
        print(f"❌ Error creating database pool: {e}")
        raise
    
    # Register blueprints
    from app.auth import auth_bp, init_db_pool as auth_init_pool
    from app.routes.members import members_bp, init_db_pool as members_init_pool
    
    # Initialize database pool in modules
    auth_init_pool(db_pool)
    members_init_pool(db_pool)
    
    # Register blueprints with URL prefixes
    app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    app.register_blueprint(members_bp, url_prefix='/api/v1/members')
    
    # Root endpoint
    @app.route('/')
    def index():
        return jsonify({
            "message": "Smart Gym Management API",
            "version": "1.0.0",
            "status": "running",
            "endpoints": {
                "auth": "/api/v1/auth",
                "docs": "/api/docs (coming soon)"
            }
        })
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        """Check if API and database are running"""
        try:
            conn = db_pool.getconn()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            db_pool.putconn(conn)
            
            return jsonify({
                "status": "healthy",
                "database": "connected"
            }), 200
            
        except Exception as e:
            return jsonify({
                "status": "unhealthy",
                "database": "disconnected",
                "error": str(e)
            }), 500
    
    # 404 handler
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            "success": False,
            "error": "Endpoint not found",
            "message": "The requested URL was not found on the server."
        }), 404
    
    # 500 handler
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "message": "An unexpected error occurred. Please try again later."
        }), 500
    
    return app