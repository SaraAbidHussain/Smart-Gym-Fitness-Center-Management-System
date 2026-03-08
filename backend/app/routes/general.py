"""
General/Public Routes
Endpoints accessible without authentication or by all authenticated users
"""

from flask import Blueprint, request, jsonify
import psycopg2
from datetime import datetime, timedelta

# Create Blueprint
general_bp = Blueprint('general', __name__)

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


# ============================================================
# GET /api/v1/classes
# Get all class types (public)
# ============================================================
@general_bp.route('/classes', methods=['GET'])
def get_classes():
    """
    Get all available class types
    
    Returns:
    {
        "success": true,
        "classes": [
            {
                "class_id": 1,
                "class_name": "Morning Yoga",
                "description": "Relaxing yoga session",
                "class_type": "Mind & Body",
                "duration_minutes": 60,
                "difficulty_level": "beginner",
                "max_capacity": 15
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                class_id, class_name, description, class_type,
                duration_minutes, difficulty_level, max_capacity
            FROM classes
            ORDER BY class_name
        """)
        
        results = cursor.fetchall()
        
        classes = []
        for row in results:
            classes.append({
                "class_id": row[0],
                "class_name": row[1],
                "description": row[2],
                "class_type": row[3],
                "duration_minutes": row[4],
                "difficulty_level": row[5],
                "max_capacity": row[6]
            })
        
        return jsonify({
            "success": True,
            "count": len(classes),
            "classes": classes
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


# ============================================================
# GET /api/v1/classes/schedule
# Get upcoming class schedules (public)
# ============================================================
@general_bp.route('/classes/schedule', methods=['GET'])
def get_class_schedule():
    """
    Get upcoming class schedules
    
    Query Parameters:
    - days: Number of days ahead to fetch (default: 7)
    - class_id: Filter by class type
    - date: Specific date (YYYY-MM-DD)
    
    Returns:
    {
        "success": true,
        "schedules": [
            {
                "schedule_id": 1,
                "class_name": "Morning Yoga",
                "schedule_date": "2026-02-24",
                "start_time": "06:00:00",
                "end_time": "07:00:00",
                "trainer_name": "Sara Nadeem",
                "room_number": "Studio A",
                "current_capacity": 10,
                "max_capacity": 15,
                "available_spots": 5,
                "status": "scheduled"
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get query parameters
        days = int(request.args.get('days', 7))
        class_filter = request.args.get('class_id')
        date_filter = request.args.get('date')
        
        # Build query
        query = """
            SELECT 
                cs.schedule_id, c.class_name, cs.schedule_date,
                cs.start_time, cs.end_time,
                u.first_name || ' ' || u.last_name as trainer_name,
                cs.room_number, cs.current_capacity, c.max_capacity,
                (c.max_capacity - cs.current_capacity) as available_spots,
                cs.status, c.difficulty_level, c.class_type
            FROM class_schedules cs
            JOIN classes c ON cs.class_id = c.class_id
            JOIN trainers t ON cs.trainer_id = t.trainer_id
            JOIN users u ON t.user_id = u.user_id
            WHERE cs.status = 'scheduled'
        """
        
        params = []
        
        if date_filter:
            query += " AND cs.schedule_date = %s"
            params.append(date_filter)
        else:
            # Default: upcoming days
            end_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
            query += " AND cs.schedule_date >= CURRENT_DATE AND cs.schedule_date <= %s"
            params.append(end_date)
        
        if class_filter:
            query += " AND cs.class_id = %s"
            params.append(class_filter)
        
        query += " ORDER BY cs.schedule_date, cs.start_time"
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        schedules = []
        for row in results:
            schedules.append({
                "schedule_id": row[0],
                "class_name": row[1],
                "schedule_date": row[2].isoformat(),
                "start_time": str(row[3]),
                "end_time": str(row[4]),
                "trainer_name": row[5],
                "room_number": row[6],
                "current_capacity": row[7],
                "max_capacity": row[8],
                "available_spots": row[9],
                "status": row[10],
                "difficulty_level": row[11],
                "class_type": row[12]
            })
        
        return jsonify({
            "success": True,
            "count": len(schedules),
            "schedules": schedules
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


# ============================================================
# GET /api/v1/membership-tiers
# Get all membership tiers (public)
# ============================================================
@general_bp.route('/membership-tiers', methods=['GET'])
def get_membership_tiers():
    """
    Get all membership tier options
    
    Returns:
    {
        "success": true,
        "tiers": [
            {
                "tier_id": 1,
                "tier_name": "Basic",
                "monthly_fee": 5000.00,
                "access_sauna": false,
                "access_pool": false,
                "access_premium_zone": false,
                "max_classes_per_month": 4,
                "description": "Entry-level membership..."
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                tier_id, tier_name, monthly_fee, access_sauna,
                access_pool, access_premium_zone, max_classes_per_month,
                description
            FROM membership_tiers
            ORDER BY monthly_fee
        """)
        
        results = cursor.fetchall()
        
        tiers = []
        for row in results:
            tiers.append({
                "tier_id": row[0],
                "tier_name": row[1],
                "monthly_fee": float(row[2]),
                "access_sauna": row[3],
                "access_pool": row[4],
                "access_premium_zone": row[5],
                "max_classes_per_month": row[6],
                "description": row[7]
            })
        
        return jsonify({
            "success": True,
            "count": len(tiers),
            "tiers": tiers
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


# ============================================================
# GET /api/v1/trainers
# Get all trainers (public)
# ============================================================
@general_bp.route('/trainers', methods=['GET'])
def get_trainers():
    """
    Get all available trainers
    
    Query Parameters:
    - available: Filter by availability (true/false)
    
    Returns:
    {
        "success": true,
        "trainers": [
            {
                "trainer_id": 1,
                "name": "Ali Rehman",
                "specialization": "Weight Loss, Cardio",
                "certification": "NASM Certified",
                "hourly_rate": 2000.00,
                "years_experience": 8,
                "rating": 4.8,
                "is_available": true
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        available_filter = request.args.get('available')
        
        query = """
            SELECT 
                t.trainer_id,
                u.first_name || ' ' || u.last_name as name,
                t.specialization, t.certification, t.hourly_rate,
                t.years_experience, t.bio, t.is_available, t.rating
            FROM trainers t
            JOIN users u ON t.user_id = u.user_id
            WHERE u.is_active = TRUE
        """
        
        params = []
        
        if available_filter is not None:
            is_available = available_filter.lower() == 'true'
            query += " AND t.is_available = %s"
            params.append(is_available)
        
        query += " ORDER BY t.rating DESC, t.years_experience DESC"
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        trainers = []
        for row in results:
            trainers.append({
                "trainer_id": row[0],
                "name": row[1],
                "specialization": row[2],
                "certification": row[3],
                "hourly_rate": float(row[4]) if row[4] else None,
                "years_experience": row[5],
                "bio": row[6],
                "is_available": row[7],
                "rating": float(row[8]) if row[8] else 0
            })
        
        return jsonify({
            "success": True,
            "count": len(trainers),
            "trainers": trainers
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