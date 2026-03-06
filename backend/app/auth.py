"""
Authentication Routes
Handles user registration and login with JWT token generation
"""

from flask import Blueprint, request, jsonify
import psycopg2
from psycopg2 import pool
import bcrypt
import jwt
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Create Blueprint
auth_bp = Blueprint('auth', __name__)

# Database connection pool (initialize this in __init__.py)
db_pool = None

def init_db_pool(pool_instance):
    """Initialize database pool from main app"""
    global db_pool
    db_pool = pool_instance

def get_db_connection():
    """Get connection from pool"""
    return db_pool.getconn()

def release_db_connection(conn):
    """Release connection back to pool"""
    db_pool.putconn(conn)


# ============================================================
# REGISTER ENDPOINT
# ============================================================
@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Register a new user
    
    Request Body:
    {
        "email": "user@example.com",
        "password": "securePassword123",
        "first_name": "John",
        "last_name": "Doe",
        "phone": "0300-1234567",
        "role": "member",
        "date_of_birth": "1995-01-15",
        "gender": "male"
    }
    
    Returns:
    {
        "success": true,
        "message": "User registered successfully",
        "user_id": 21
    }
    """
    try:
        # Get request data
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['email', 'password', 'first_name', 'last_name', 'role']
        for field in required_fields:
            if field not in data or not data[field]:
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Validate role
        valid_roles = ['member', 'trainer', 'staff', 'admin']
        if data['role'] not in valid_roles:
            return jsonify({
                "success": False,
                "error": f"Invalid role. Must be one of: {', '.join(valid_roles)}"
            }), 400
        
        # Validate email format (basic)
        if '@' not in data['email'] or '.' not in data['email']:
            return jsonify({
                "success": False,
                "error": "Invalid email format"
            }), 400
        
        # Validate password strength
        if len(data['password']) < 8:
            return jsonify({
                "success": False,
                "error": "Password must be at least 8 characters long"
            }), 400
        
        # Hash password using bcrypt
        password_hash = bcrypt.hashpw(
            data['password'].encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Check if email already exists
            cursor.execute(
                "SELECT user_id FROM users WHERE email = %s",
                (data['email'],)
            )
            
            if cursor.fetchone():
                return jsonify({
                    "success": False,
                    "error": "Email already registered"
                }), 409  # Conflict
            
            # Insert new user
            cursor.execute("""
                INSERT INTO users (
                    email, password_hash, first_name, last_name,
                    phone, role, date_of_birth, gender, is_active
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, TRUE)
                RETURNING user_id
            """, (
                data['email'],
                password_hash,
                data['first_name'],
                data['last_name'],
                data.get('phone'),
                data['role'],
                data.get('date_of_birth'),
                data.get('gender')
            ))
            
            user_id = cursor.fetchone()[0]
            conn.commit()
            
            return jsonify({
                "success": True,
                "message": "User registered successfully",
                "user_id": user_id
            }), 201
            
        except psycopg2.Error as db_error:
            conn.rollback()
            return jsonify({
                "success": False,
                "error": "Database error occurred",
                "details": str(db_error)
            }), 500
            
        finally:
            cursor.close()
            release_db_connection(conn)
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "details": str(e)
        }), 500


# ============================================================
# LOGIN ENDPOINT
# ============================================================
@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Login user and return JWT token
    
    Request Body:
    {
        "email": "user@example.com",
        "password": "securePassword123"
    }
    
    Returns:
    {
        "success": true,
        "message": "Login successful",
        "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
        "user": {
            "user_id": 1,
            "email": "user@example.com",
            "first_name": "John",
            "last_name": "Doe",
            "role": "member"
        }
    }
    """
    try:
        # Get request data
        data = request.get_json()
        
        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({
                "success": False,
                "error": "Email and password are required"
            }), 400
        
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Get user from database
            cursor.execute("""
                SELECT user_id, email, password_hash, first_name, last_name, role, is_active
                FROM users
                WHERE email = %s
            """, (data['email'],))
            
            user = cursor.fetchone()
            
            # Check if user exists
            if not user:
                return jsonify({
                    "success": False,
                    "error": "Invalid email or password"
                }), 401
            
            user_id, email, password_hash, first_name, last_name, role, is_active = user
            
            # Check if account is active
            if not is_active:
                return jsonify({
                    "success": False,
                    "error": "Account is deactivated. Please contact admin."
                }), 403
            
            # Verify password
            if not bcrypt.checkpw(
                data['password'].encode('utf-8'),
                password_hash.encode('utf-8')
            ):
                return jsonify({
                    "success": False,
                    "error": "Invalid email or password"
                }), 401
            
            # Generate JWT token
            secret_key = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
            token_expiry = datetime.utcnow() + timedelta(hours=24)
            
            payload = {
                "user_id": user_id,
                "email": email,
                "role": role,
                "exp": token_expiry,
                "iat": datetime.utcnow()
            }
            
            token = jwt.encode(payload, secret_key, algorithm="HS256")
            
            # Return success response
            return jsonify({
                "success": True,
                "message": "Login successful",
                "token": token,
                "user": {
                    "user_id": user_id,
                    "email": email,
                    "first_name": first_name,
                    "last_name": last_name,
                    "role": role
                }
            }), 200
            
        except psycopg2.Error as db_error:
            return jsonify({
                "success": False,
                "error": "Database error occurred",
                "details": str(db_error)
            }), 500
            
        finally:
            cursor.close()
            release_db_connection(conn)
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": "Internal server error",
            "details": str(e)
        }), 500


# ============================================================
# GET CURRENT USER (Protected Route - For Testing)
# ============================================================
@auth_bp.route('/me', methods=['GET'])
def get_current_user():
    """
    Get current logged-in user's information
    Requires valid JWT token in Authorization header
    
    Headers:
    Authorization: Bearer <token>
    
    Returns:
    {
        "success": true,
        "user": {
            "user_id": 1,
            "email": "user@example.com",
            "first_name": "John",
            "last_name": "Doe",
            "role": "member",
            "phone": "0300-1234567"
        }
    }
    
    Note: This endpoint will be protected by @token_required middleware
    which we'll add in the next step
    """
    # This will be implemented after middleware is created
    return jsonify({
        "success": False,
        "error": "Endpoint requires middleware implementation"
    }), 501


# ============================================================
# LOGOUT ENDPOINT (Optional - JWT is stateless)
# ============================================================
@auth_bp.route('/logout', methods=['POST'])
def logout():
    """
    Logout endpoint (for client-side token removal)
    
    Since JWT is stateless, actual logout happens on client side
    by removing the token. This endpoint is just for consistency.
    
    For a real token blacklist, you'd need Redis or a database table
    to store invalidated tokens until their expiry.
    
    Returns:
    {
        "success": true,
        "message": "Logged out successfully"
    }
    """
    return jsonify({
        "success": True,
        "message": "Logged out successfully. Please remove token from client."
    }), 200