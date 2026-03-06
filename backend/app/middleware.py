"""
Middleware for JWT Authentication and Role-Based Access Control
"""

from flask import request, jsonify
from functools import wraps
import jwt
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Secret key for JWT
SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')


# ============================================================
# TOKEN REQUIRED DECORATOR
# Validates JWT token and extracts user information
# ============================================================
def token_required(f):
    """
    Decorator to protect routes that require authentication
    
    Usage:
    @app.route('/protected')
    @token_required
    def protected_route(current_user):
        return f"Hello {current_user['email']}"
    
    Expects:
    - Authorization header: "Bearer <token>"
    
    Returns:
    - 401 if token is missing or invalid
    - Passes current_user dict to the wrapped function
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            
            try:
                # Format: "Bearer <token>"
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({
                    "success": False,
                    "error": "Invalid authorization header format. Use: Bearer <token>"
                }), 401
        
        # Check if token exists
        if not token:
            return jsonify({
                "success": False,
                "error": "Authorization token is missing"
            }), 401
        
        try:
            # Decode JWT token
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            
            # Extract user information from token
            current_user = {
                "user_id": data['user_id'],
                "email": data['email'],
                "role": data['role']
            }
            
        except jwt.ExpiredSignatureError:
            return jsonify({
                "success": False,
                "error": "Token has expired. Please login again."
            }), 401
            
        except jwt.InvalidTokenError:
            return jsonify({
                "success": False,
                "error": "Invalid token. Please login again."
            }), 401
        
        except Exception as e:
            return jsonify({
                "success": False,
                "error": "Token verification failed",
                "details": str(e)
            }), 401
        
        # Pass current_user to the wrapped function
        return f(current_user, *args, **kwargs)
    
    return decorated


# ============================================================
# ROLE REQUIRED DECORATOR
# Validates user has required role(s)
# Must be used AFTER @token_required
# ============================================================
def role_required(allowed_roles):
    """
    Decorator to restrict access based on user roles
    Must be used AFTER @token_required decorator
    
    Usage:
    @app.route('/admin-only')
    @token_required
    @role_required(['admin'])
    def admin_route(current_user):
        return "Admin access granted"
    
    @app.route('/member-or-trainer')
    @token_required
    @role_required(['member', 'trainer'])
    def mixed_route(current_user):
        return "Member or Trainer access"
    
    Args:
    - allowed_roles: List of roles that can access this route
                     Valid roles: ['member', 'trainer', 'staff', 'admin']
    
    Returns:
    - 403 if user role is not in allowed_roles
    - Passes current_user to the wrapped function
    """
    def decorator(f):
        @wraps(f)
        def decorated(current_user, *args, **kwargs):
            # Check if user's role is in allowed roles
            if current_user['role'] not in allowed_roles:
                return jsonify({
                    "success": False,
                    "error": f"Access denied. Required role(s): {', '.join(allowed_roles)}",
                    "your_role": current_user['role']
                }), 403
            
            # Role is allowed, proceed
            return f(current_user, *args, **kwargs)
        
        return decorated
    return decorator


# ============================================================
# OPTIONAL: Owner or Admin Check
# Allows access if user owns the resource OR is admin
# ============================================================
def owner_or_admin_required(resource_owner_id_getter):
    """
    Decorator to check if user is the resource owner or admin
    
    Usage:
    @app.route('/users/<int:user_id>/profile')
    @token_required
    @owner_or_admin_required(lambda user_id: user_id)
    def get_user_profile(current_user, user_id):
        # Only the user themselves or admin can access
        return f"Profile for user {user_id}"
    
    Args:
    - resource_owner_id_getter: Function that extracts the owner ID from route parameters
    
    Returns:
    - 403 if user is not owner and not admin
    """
    def decorator(f):
        @wraps(f)
        def decorated(current_user, *args, **kwargs):
            # Get the resource owner ID
            resource_owner_id = resource_owner_id_getter(*args, **kwargs)
            
            # Check if user is owner or admin
            if current_user['user_id'] != resource_owner_id and current_user['role'] != 'admin':
                return jsonify({
                    "success": False,
                    "error": "Access denied. You can only access your own resources."
                }), 403
            
            return f(current_user, *args, **kwargs)
        
        return decorated
    return decorator


# ============================================================
# EXAMPLE USAGE IN ROUTES
# ============================================================
"""
from middleware import token_required, role_required

# Example 1: Any authenticated user
@app.route('/api/v1/profile')
@token_required
def get_profile(current_user):
    return jsonify({
        "user_id": current_user['user_id'],
        "email": current_user['email'],
        "role": current_user['role']
    })

# Example 2: Member only
@app.route('/api/v1/members/dashboard')
@token_required
@role_required(['member'])
def member_dashboard(current_user):
    # Only members can access
    return jsonify({"message": "Member dashboard"})

# Example 3: Trainer or Admin
@app.route('/api/v1/trainers/clients')
@token_required
@role_required(['trainer', 'admin'])
def trainer_clients(current_user):
    # Trainers and admins can access
    return jsonify({"message": "Trainer clients"})

# Example 4: Staff only
@app.route('/api/v1/staff/checkin')
@token_required
@role_required(['staff'])
def staff_checkin(current_user):
    # Only staff can check in members
    return jsonify({"message": "Check-in endpoint"})

# Example 5: Admin only
@app.route('/api/v1/admin/users')
@token_required
@role_required(['admin'])
def admin_users(current_user):
    # Only admins can access
    return jsonify({"message": "All users"})
"""