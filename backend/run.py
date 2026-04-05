"""
Application Entry Point
Run this file to start the Flask development server
"""

from app import create_app
import os

# Create Flask app
app = create_app()

if __name__ == '__main__':
    # Get port from environment or use 5000
    port = int(os.getenv('PORT', 5000))
    
    # Run development server
    print(f"\n Starting Smart Gym API on http://localhost:{port}")
    print(f" API Documentation: http://localhost:{port}/api/docs (coming soon)")
    print(f" Health Check: http://localhost:{port}/health")
    print(f" Auth Endpoints: http://localhost:{port}/api/v1/auth")
    print("\nPress CTRL+C to stop the server\n")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=True  # Set to False in production
    )