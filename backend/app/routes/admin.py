"""
Admin Routes
All endpoints for administrative operations
Protected by JWT authentication and admin role
"""

from flask import Blueprint, request, jsonify
import psycopg2
from datetime import datetime
from app.middleware import token_required, role_required

# Create Blueprint
admin_bp = Blueprint('admin', __name__)

# Database pool (initialized from main app)
db_pool = None

def init_db_pool(pool_instance):
    """Initialize database pool"""
    global db_pool
    db_pool = pool_instance

def get_db_connection():
    """Get connection from pool"""
    return db_pool.getconn()

def release_db_connection(conn):
    """Release connection back to pool"""
    db_pool.putconn(conn)


# GET /api/v1/admin/users
# List all users with pagination
@admin_bp.route('/users', methods=['GET'])
@token_required
@role_required(['admin'])
def get_users(current_user):
    """
    Get all users with pagination and filtering
    
    Query Parameters:
    - page: Page number (default: 1)
    - per_page: Records per page (default: 20, max: 100)
    - role: Filter by role (member, trainer, staff, admin)
    - is_active: Filter by active status (true/false)
    - search: Search by name or email
    
    Returns:
    {
        "success": true,
        "users": [...],
        "pagination": {
            "page": 1,
            "per_page": 20,
            "total": 50,
            "total_pages": 3
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get query parameters
        page = int(request.args.get('page', 1))
        per_page = min(int(request.args.get('per_page', 20)), 100)
        role_filter = request.args.get('role')
        active_filter = request.args.get('is_active')
        search = request.args.get('search')
        
        # Build query
        query = """
            SELECT 
                user_id, email, first_name, last_name, phone,
                role, date_of_birth, gender, created_at, is_active
            FROM users
            WHERE 1=1
        """
        count_query = "SELECT COUNT(*) FROM users WHERE 1=1"
        params = []
        
        # Add filters
        if role_filter:
            query += " AND role = %s"
            count_query += " AND role = %s"
            params.append(role_filter)
        
        if active_filter is not None:
            is_active = active_filter.lower() == 'true'
            query += " AND is_active = %s"
            count_query += " AND is_active = %s"
            params.append(is_active)
        
        if search:
            search_pattern = f"%{search}%"
            query += " AND (first_name ILIKE %s OR last_name ILIKE %s OR email ILIKE %s)"
            count_query += " AND (first_name ILIKE %s OR last_name ILIKE %s OR email ILIKE %s)"
            params.extend([search_pattern, search_pattern, search_pattern])
        
        # Get total count
        cursor.execute(count_query, params)
        total = cursor.fetchone()[0]
        
        # Add pagination
        offset = (page - 1) * per_page
        query += " ORDER BY created_at DESC LIMIT %s OFFSET %s"
        params.extend([per_page, offset])
        
        # Execute query
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        users = []
        for row in results:
            users.append({
                "user_id": row[0],
                "email": row[1],
                "first_name": row[2],
                "last_name": row[3],
                "phone": row[4],
                "role": row[5],
                "date_of_birth": row[6].isoformat() if row[6] else None,
                "gender": row[7],
                "created_at": row[8].isoformat(),
                "is_active": row[9]
            })
        
        return jsonify({
            "success": True,
            "users": users,
            "pagination": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": (total + per_page - 1) // per_page
            }
        }), 200
        
    except psycopg2.Error as e:
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# POST /api/v1/admin/users
# Create a new user
@admin_bp.route('/users', methods=['POST'])
@token_required
@role_required(['admin'])
def create_user(current_user):
    """
    Create a new user (admin only)
    
    Request Body:
    {
        "email": "newuser@gym.com",
        "password": "TempPass123",
        "first_name": "New",
        "last_name": "User",
        "phone": "0300-1234567",
        "role": "member",
        "date_of_birth": "1990-01-01",
        "gender": "male"
    }
    
    Returns:
    {
        "success": true,
        "message": "User created successfully",
        "user_id": 25
    }
    """
    import bcrypt
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        data = request.get_json()
        
        # Validate required fields
        required = ['email', 'password', 'first_name', 'last_name', 'role']
        for field in required:
            if field not in data:
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Validate role
        if data['role'] not in ['member', 'trainer', 'staff', 'admin']:
            return jsonify({
                "success": False,
                "error": "Invalid role"
            }), 400
        
        # Check if email exists
        cursor.execute("SELECT user_id FROM users WHERE email = %s", (data['email'],))
        if cursor.fetchone():
            return jsonify({
                "success": False,
                "error": "Email already exists"
            }), 409
        
        # Hash password
        password_hash = bcrypt.hashpw(
            data['password'].encode('utf-8'),
            bcrypt.gensalt()
        ).decode('utf-8')
        
        # Insert user
        cursor.execute("""
            INSERT INTO users (
                email, password_hash, first_name, last_name,
                phone, role, date_of_birth, gender, is_active
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, TRUE)
            RETURNING user_id
        """, (
            data['email'], password_hash, data['first_name'],
            data['last_name'], data.get('phone'), data['role'],
            data.get('date_of_birth'), data.get('gender')
        ))
        
        user_id = cursor.fetchone()[0]
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "User created successfully",
            "user_id": user_id
        }), 201
        
    except psycopg2.Error as e:
        conn.rollback()
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# PUT /api/v1/admin/users/<user_id>
# Update user details
@admin_bp.route('/users/<int:user_id>', methods=['PUT'])
@token_required
@role_required(['admin'])
def update_user(current_user, user_id):
    """
    Update user details (admin only)
    
    Request Body (all optional):
    {
        "first_name": "Updated",
        "last_name": "Name",
        "phone": "0300-9999999",
        "role": "trainer",
        "is_active": false
    }
    
    Returns:
    {
        "success": true,
        "message": "User updated successfully"
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        data = request.get_json()
        
        # Check if user exists
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
        if not cursor.fetchone():
            return jsonify({
                "success": False,
                "error": "User not found"
            }), 404
        
        # Build update query
        allowed_fields = ['first_name', 'last_name', 'phone', 'role', 'date_of_birth', 'gender', 'is_active']
        updates = []
        params = []
        
        for field in allowed_fields:
            if field in data:
                updates.append(f"{field} = %s")
                params.append(data[field])
        
        if not updates:
            return jsonify({
                "success": False,
                "error": "No valid fields to update"
            }), 400
        
        # Add user_id to params
        params.append(user_id)
        
        # Execute update
        query = f"UPDATE users SET {', '.join(updates)} WHERE user_id = %s"
        cursor.execute(query, params)
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "User updated successfully"
        }), 200
        
    except psycopg2.Error as e:
        conn.rollback()
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# DELETE /api/v1/admin/users/<user_id>
# Deactivate user (soft delete)
@admin_bp.route('/users/<int:user_id>', methods=['DELETE'])
@token_required
@role_required(['admin'])
def delete_user(current_user, user_id):
    """
    Deactivate a user (soft delete)
    
    Returns:
    {
        "success": true,
        "message": "User deactivated successfully"
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Prevent admin from deactivating themselves
        if user_id == current_user['user_id']:
            return jsonify({
                "success": False,
                "error": "You cannot deactivate your own account"
            }), 400
        
        # Check if user exists
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
        if not cursor.fetchone():
            return jsonify({
                "success": False,
                "error": "User not found"
            }), 404
        
        # Deactivate user
        cursor.execute(
            "UPDATE users SET is_active = FALSE WHERE user_id = %s",
            (user_id,)
        )
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "User deactivated successfully"
        }), 200
        
    except psycopg2.Error as e:
        conn.rollback()
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# GET /api/v1/admin/revenue
# Revenue analytics
@admin_bp.route('/revenue', methods=['GET'])
@token_required
@role_required(['admin'])
def get_revenue(current_user):
    """
    Get revenue statistics
    
    Query Parameters:
    - start_date: Start date (YYYY-MM-DD)
    - end_date: End date (YYYY-MM-DD)
    
    Returns:
    {
        "success": true,
        "revenue": {
            "total_revenue": 150000.00,
            "membership_revenue": 120000.00,
            "training_revenue": 20000.00,
            "product_revenue": 10000.00,
            "by_payment_method": {
                "cash": 50000.00,
                "credit_card": 80000.00,
                "online": 20000.00
            },
            "period": {
                "start_date": "2026-01-01",
                "end_date": "2026-02-21"
            }
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        start_date = request.args.get('start_date', '2026-01-01')
        end_date = request.args.get('end_date', datetime.now().strftime('%Y-%m-%d'))
        
        # Total revenue by type
        cursor.execute("""
            SELECT 
                payment_type,
                SUM(amount) as total
            FROM payments
            WHERE status = 'completed'
              AND payment_date >= %s
              AND payment_date <= %s
            GROUP BY payment_type
        """, (start_date, end_date))
        
        revenue_by_type = {}
        total_revenue = 0
        
        for row in cursor.fetchall():
            revenue_by_type[row[0]] = float(row[1])
            total_revenue += float(row[1])
        
        # Revenue by payment method
        cursor.execute("""
            SELECT 
                payment_method,
                SUM(amount) as total
            FROM payments
            WHERE status = 'completed'
              AND payment_date >= %s
              AND payment_date <= %s
            GROUP BY payment_method
        """, (start_date, end_date))
        
        revenue_by_method = {}
        for row in cursor.fetchall():
            revenue_by_method[row[0]] = float(row[1])
        
        return jsonify({
            "success": True,
            "revenue": {
                "total_revenue": total_revenue,
                "membership_revenue": revenue_by_type.get('membership', 0),
                "training_revenue": revenue_by_type.get('training_session', 0),
                "product_revenue": revenue_by_type.get('product', 0),
                "late_fee_revenue": revenue_by_type.get('late_fee', 0),
                "by_payment_method": revenue_by_method,
                "period": {
                    "start_date": start_date,
                    "end_date": end_date
                }
            }
        }), 200
        
    except psycopg2.Error as e:
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# GET /api/v1/admin/analytics
# System-wide analytics using views
@admin_bp.route('/analytics', methods=['GET'])
@token_required
@role_required(['admin'])
def get_analytics(current_user):
    """
    Get comprehensive system analytics
    
    Returns:
    {
        "success": true,
        "analytics": {
            "user_stats": {...},
            "membership_stats": {...},
            "class_stats": {...},
            "equipment_stats": {...}
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        analytics = {}
        
        # User statistics
        cursor.execute("""
            SELECT 
                role,
                COUNT(*) as count,
                SUM(CASE WHEN is_active THEN 1 ELSE 0 END) as active_count
            FROM users
            GROUP BY role
        """)
        
        user_stats = {}
        for row in cursor.fetchall():
            user_stats[row[0]] = {
                "total": row[1],
                "active": row[2]
            }
        
        analytics['user_stats'] = user_stats
        
        # Membership statistics
        cursor.execute("""
            SELECT 
                status,
                COUNT(*) as count
            FROM memberships
            GROUP BY status
        """)
        
        membership_stats = {}
        for row in cursor.fetchall():
            membership_stats[row[0]] = row[1]
        
        analytics['membership_stats'] = membership_stats
        
        # Class statistics
        cursor.execute("""
            SELECT 
                COUNT(DISTINCT schedule_id) as total_schedules,
                COUNT(DISTINCT CASE WHEN status = 'completed' THEN schedule_id END) as completed,
                COUNT(DISTINCT CASE WHEN status = 'scheduled' THEN schedule_id END) as upcoming,
                AVG(current_capacity) as avg_capacity
            FROM class_schedules
        """)
        
        row = cursor.fetchone()
        analytics['class_stats'] = {
            "total_schedules": row[0],
            "completed": row[1],
            "upcoming": row[2],
            "avg_capacity": float(row[3]) if row[3] else 0
        }
        
        # Equipment health from view
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN maintenance_alert = 'OVERDUE' THEN 1 ELSE 0 END) as overdue,
                SUM(CASE WHEN maintenance_alert = 'DUE SOON' THEN 1 ELSE 0 END) as due_soon
            FROM equipment_health_view
        """)
        
        row = cursor.fetchone()
        analytics['equipment_stats'] = {
            "total": row[0],
            "maintenance_overdue": row[1],
            "maintenance_due_soon": row[2]
        }
        
        return jsonify({
            "success": True,
            "analytics": analytics
        }), 200
        
    except psycopg2.Error as e:
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# GET /api/v1/admin/memberships
# Get all memberships with filtering
@admin_bp.route('/memberships', methods=['GET'])
@token_required
@role_required(['admin'])
def get_memberships(current_user):
    """
    Get all memberships with filtering
    
    Query Parameters:
    - status: Filter by status (active, expired, frozen, cancelled)
    - tier_id: Filter by tier
    - page: Page number
    - per_page: Records per page
    
    Returns list of memberships with user and tier details
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        page = int(request.args.get('page', 1))
        per_page = min(int(request.args.get('per_page', 20)), 100)
        status_filter = request.args.get('status')
        tier_filter = request.args.get('tier_id')
        
        # Build query
        query = """
            SELECT 
                m.membership_id, m.user_id,
                u.first_name || ' ' || u.last_name as full_name,
                u.email, mt.tier_name, m.start_date, m.end_date,
                m.status, m.is_frozen, m.auto_renew
            FROM memberships m
            JOIN users u ON m.user_id = u.user_id
            JOIN membership_tiers mt ON m.tier_id = mt.tier_id
            WHERE 1=1
        """
        count_query = """
            SELECT COUNT(*)
            FROM memberships m
            WHERE 1=1
        """
        params = []
        
        if status_filter:
            query += " AND m.status = %s"
            count_query += " AND m.status = %s"
            params.append(status_filter)
        
        if tier_filter:
            query += " AND m.tier_id = %s"
            count_query += " AND m.tier_id = %s"
            params.append(tier_filter)
        
        # Get total
        cursor.execute(count_query, params)
        total = cursor.fetchone()[0]
        
        # Add pagination
        offset = (page - 1) * per_page
        query += " ORDER BY m.start_date DESC LIMIT %s OFFSET %s"
        params.extend([per_page, offset])
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        memberships = []
        for row in results:
            memberships.append({
                "membership_id": row[0],
                "user_id": row[1],
                "member_name": row[2],
                "email": row[3],
                "tier_name": row[4],
                "start_date": row[5].isoformat(),
                "end_date": row[6].isoformat(),
                "status": row[7],
                "is_frozen": row[8],
                "auto_renew": row[9]
            })
        
        return jsonify({
            "success": True,
            "memberships": memberships,
            "pagination": {
                "page": page,
                "per_page": per_page,
                "total": total,
                "total_pages": (total + per_page - 1) // per_page
            }
        }), 200
        
    except psycopg2.Error as e:
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)


# GET /api/v1/admin/equipment-health
# Equipment health report using view
@admin_bp.route('/equipment-health', methods=['GET'])
@token_required
@role_required(['admin'])
def get_equipment_health(current_user):
    """
    Get equipment health report from view
    
    Returns:
    {
        "success": true,
        "equipment": [
            {
                "equipment_id": 1,
                "equipment_name": "Treadmill 01",
                "status": "available",
                "total_usage_hours": 450,
                "maintenance_alert": "OK",
                "total_maintenance_cost": 5000.00
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                equipment_id, equipment_name, equipment_type,
                zone, current_status, total_usage_hours,
                last_maintenance_date, next_maintenance_due,
                maintenance_alert, total_maintenance_records,
                total_maintenance_cost, usage_category
            FROM equipment_health_view
            ORDER BY 
                CASE maintenance_alert
                    WHEN 'OVERDUE' THEN 1
                    WHEN 'DUE SOON' THEN 2
                    ELSE 3
                END,
                equipment_name
        """)
        
        results = cursor.fetchall()
        
        equipment = []
        for row in results:
            equipment.append({
                "equipment_id": row[0],
                "equipment_name": row[1],
                "equipment_type": row[2],
                "zone": row[3],
                "status": row[4],
                "total_usage_hours": row[5],
                "last_maintenance_date": row[6].isoformat() if row[6] else None,
                "next_maintenance_due": row[7].isoformat() if row[7] else None,
                "maintenance_alert": row[8],
                "total_maintenance_records": row[9],
                "total_maintenance_cost": float(row[10]) if row[10] else 0,
                "usage_category": row[11]
            })
        
        return jsonify({
            "success": True,
            "count": len(equipment),
            "equipment": equipment
        }), 200
        
    except psycopg2.Error as e:
        return jsonify({
            "success": False,
            "error": "Database error",
            "details": str(e)
        }), 500
        
    finally:
        cursor.close()
        release_db_connection(conn)