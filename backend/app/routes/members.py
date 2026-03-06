"""
Member Routes
All endpoints for member-specific operations
Protected by JWT authentication and member role
"""

from flask import Blueprint, request, jsonify
import psycopg2
from datetime import datetime, date
from app.middleware import token_required, role_required

# Create Blueprint
members_bp = Blueprint('members', __name__)

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
# GET /api/v1/members/dashboard
# Member dashboard with stats from database view
# ============================================================
@members_bp.route('/dashboard', methods=['GET'])
@token_required
@role_required(['member'])
def get_dashboard(current_user):
    """
    Get member dashboard with statistics
    
    Returns:
    {
        "success": true,
        "dashboard": {
            "user_id": 1,
            "full_name": "John Doe",
            "email": "john@gym.com",
            "membership_tier": "Premium",
            "membership_status": "active",
            "membership_expires": "2027-01-01",
            "total_visits": 15,
            "confirmed_bookings": 5,
            "attended_classes": 10,
            "total_calories_burned": 3500,
            "total_workout_logs": 20
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get data from member_dashboard_view
        cursor.execute("""
            SELECT 
                user_id, full_name, email, membership_tier,
                membership_status, membership_expires, total_visits,
                confirmed_bookings, attended_classes, total_calories_burned,
                total_workout_logs
            FROM member_dashboard_view
            WHERE user_id = %s
        """, (current_user['user_id'],))
        
        result = cursor.fetchone()
        
        if not result:
            return jsonify({
                "success": False,
                "error": "Dashboard data not found"
            }), 404
        
        # Map to dictionary
        dashboard = {
            "user_id": result[0],
            "full_name": result[1],
            "email": result[2],
            "membership_tier": result[3],
            "membership_status": result[4],
            "membership_expires": result[5].isoformat() if result[5] else None,
            "total_visits": result[6],
            "confirmed_bookings": result[7],
            "attended_classes": result[8],
            "total_calories_burned": result[9],
            "total_workout_logs": result[10]
        }
        
        return jsonify({
            "success": True,
            "dashboard": dashboard
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
# GET /api/v1/members/membership
# Get active membership details
# ============================================================
@members_bp.route('/membership', methods=['GET'])
@token_required
@role_required(['member'])
def get_membership(current_user):
    """
    Get member's active membership details
    
    Returns:
    {
        "success": true,
        "membership": {
            "membership_id": 1,
            "tier_name": "Premium",
            "monthly_fee": 8000.00,
            "start_date": "2026-01-01",
            "end_date": "2027-01-01",
            "status": "active",
            "is_frozen": false,
            "auto_renew": true,
            "access_sauna": true,
            "access_pool": true,
            "max_classes_per_month": 8
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                m.membership_id, mt.tier_name, mt.monthly_fee,
                m.start_date, m.end_date, m.status, m.is_frozen,
                m.auto_renew, mt.access_sauna, mt.access_pool,
                mt.max_classes_per_month
            FROM memberships m
            JOIN membership_tiers mt ON m.tier_id = mt.tier_id
            WHERE m.user_id = %s AND m.status = 'active'
            ORDER BY m.start_date DESC
            LIMIT 1
        """, (current_user['user_id'],))
        
        result = cursor.fetchone()
        
        if not result:
            return jsonify({
                "success": False,
                "error": "No active membership found",
                "message": "Please purchase a membership to access gym facilities"
            }), 404
        
        membership = {
            "membership_id": result[0],
            "tier_name": result[1],
            "monthly_fee": float(result[2]),
            "start_date": result[3].isoformat(),
            "end_date": result[4].isoformat(),
            "status": result[5],
            "is_frozen": result[6],
            "auto_renew": result[7],
            "access_sauna": result[8],
            "access_pool": result[9],
            "max_classes_per_month": result[10]
        }
        
        return jsonify({
            "success": True,
            "membership": membership
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
# GET /api/v1/members/bookings
# Get member's class bookings
# ============================================================
@members_bp.route('/bookings', methods=['GET'])
@token_required
@role_required(['member'])
def get_bookings(current_user):
    """
    Get member's class bookings (upcoming and past)
    
    Query Parameters:
    - status: Filter by status (confirmed, waitlist, cancelled, attended)
    - upcoming: true/false (default: true for upcoming only)
    
    Returns:
    {
        "success": true,
        "bookings": [
            {
                "booking_id": 1,
                "class_name": "Yoga",
                "schedule_date": "2026-02-24",
                "start_time": "06:00:00",
                "end_time": "07:00:00",
                "trainer_name": "Sara Nadeem",
                "room_number": "Studio A",
                "status": "confirmed",
                "position_in_waitlist": null,
                "booking_date": "2026-02-20T10:00:00"
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get query parameters
        status_filter = request.args.get('status')
        upcoming_only = request.args.get('upcoming', 'true').lower() == 'true'
        
        # Build query
        query = """
            SELECT 
                cb.booking_id, c.class_name, cs.schedule_date,
                cs.start_time, cs.end_time, 
                u.first_name || ' ' || u.last_name as trainer_name,
                cs.room_number, cb.status, cb.position_in_waitlist,
                cb.booking_date
            FROM class_bookings cb
            JOIN class_schedules cs ON cb.schedule_id = cs.schedule_id
            JOIN classes c ON cs.class_id = c.class_id
            JOIN trainers t ON cs.trainer_id = t.trainer_id
            JOIN users u ON t.user_id = u.user_id
            WHERE cb.user_id = %s
        """
        
        params = [current_user['user_id']]
        
        # Add filters
        if status_filter:
            query += " AND cb.status = %s"
            params.append(status_filter)
        
        if upcoming_only:
            query += " AND cs.schedule_date >= CURRENT_DATE"
        
        query += " ORDER BY cs.schedule_date DESC, cs.start_time DESC"
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        bookings = []
        for row in results:
            bookings.append({
                "booking_id": row[0],
                "class_name": row[1],
                "schedule_date": row[2].isoformat(),
                "start_time": str(row[3]),
                "end_time": str(row[4]),
                "trainer_name": row[5],
                "room_number": row[6],
                "status": row[7],
                "position_in_waitlist": row[8],
                "booking_date": row[9].isoformat()
            })
        
        return jsonify({
            "success": True,
            "count": len(bookings),
            "bookings": bookings
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
# POST /api/v1/members/book-class
# Book a class (trigger handles capacity/waitlist)
# ============================================================
@members_bp.route('/book-class', methods=['POST'])
@token_required
@role_required(['member'])
def book_class(current_user):
    """
    Book a class
    Trigger automatically handles capacity check and waitlist
    
    Request Body:
    {
        "schedule_id": 1
    }
    
    Returns:
    {
        "success": true,
        "message": "Class booked successfully",
        "booking": {
            "booking_id": 15,
            "status": "confirmed",
            "position_in_waitlist": null
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        data = request.get_json()
        
        # Validate input
        if not data.get('schedule_id'):
            return jsonify({
                "success": False,
                "error": "schedule_id is required"
            }), 400
        
        schedule_id = data['schedule_id']
        
        # Check if schedule exists and is not cancelled
        cursor.execute("""
            SELECT cs.status, c.class_name, cs.schedule_date, cs.start_time
            FROM class_schedules cs
            JOIN classes c ON cs.class_id = c.class_id
            WHERE cs.schedule_id = %s
        """, (schedule_id,))
        
        schedule = cursor.fetchone()
        
        if not schedule:
            return jsonify({
                "success": False,
                "error": "Class schedule not found"
            }), 404
        
        if schedule[0] == 'cancelled':
            return jsonify({
                "success": False,
                "error": "This class has been cancelled"
            }), 400
        
        # Check if already booked
        cursor.execute("""
            SELECT booking_id, status
            FROM class_bookings
            WHERE schedule_id = %s AND user_id = %s
        """, (schedule_id, current_user['user_id']))
        
        existing = cursor.fetchone()
        
        if existing:
            return jsonify({
                "success": False,
                "error": "You have already booked this class",
                "existing_status": existing[1]
            }), 409
        
        # Insert booking (trigger handles capacity check)
        cursor.execute("""
            INSERT INTO class_bookings (schedule_id, user_id)
            VALUES (%s, %s)
            RETURNING booking_id, status, position_in_waitlist
        """, (schedule_id, current_user['user_id']))
        
        result = cursor.fetchone()
        conn.commit()
        
        booking_id, status, position = result
        
        message = "Class booked successfully"
        if status == 'waitlist':
            message = f"Class is full. You've been added to the waitlist at position {position}"
        
        return jsonify({
            "success": True,
            "message": message,
            "booking": {
                "booking_id": booking_id,
                "status": status,
                "position_in_waitlist": position,
                "class_name": schedule[1],
                "schedule_date": schedule[2].isoformat(),
                "start_time": str(schedule[3])
            }
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


# ============================================================
# DELETE /api/v1/members/bookings/<booking_id>
# Cancel a class booking
# ============================================================
@members_bp.route('/bookings/<int:booking_id>', methods=['DELETE'])
@token_required
@role_required(['member'])
def cancel_booking(current_user, booking_id):
    """
    Cancel a class booking
    Trigger will automatically promote waitlist
    
    Returns:
    {
        "success": true,
        "message": "Booking cancelled successfully"
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Check if booking exists and belongs to user
        cursor.execute("""
            SELECT booking_id, status, schedule_id
            FROM class_bookings
            WHERE booking_id = %s AND user_id = %s
        """, (booking_id, current_user['user_id']))
        
        booking = cursor.fetchone()
        
        if not booking:
            return jsonify({
                "success": False,
                "error": "Booking not found or does not belong to you"
            }), 404
        
        current_status = booking[1]
        
        if current_status == 'cancelled':
            return jsonify({
                "success": False,
                "error": "Booking is already cancelled"
            }), 400
        
        if current_status == 'attended':
            return jsonify({
                "success": False,
                "error": "Cannot cancel a class you have already attended"
            }), 400
        
        # Update booking status to cancelled
        # Trigger will handle waitlist promotion
        cursor.execute("""
            UPDATE class_bookings
            SET status = 'cancelled'
            WHERE booking_id = %s
        """, (booking_id,))
        
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "Booking cancelled successfully"
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


# ============================================================
# GET /api/v1/members/workouts
# Get workout logs
# ============================================================
@members_bp.route('/workouts', methods=['GET'])
@token_required
@role_required(['member'])
def get_workouts(current_user):
    """
    Get member's workout logs
    
    Query Parameters:
    - start_date: Filter from date (YYYY-MM-DD)
    - end_date: Filter to date (YYYY-MM-DD)
    - limit: Number of records (default 50)
    
    Returns:
    {
        "success": true,
        "workouts": [
            {
                "log_id": 1,
                "workout_date": "2026-02-15",
                "exercise_name": "Bench Press",
                "muscle_group": "Chest",
                "sets": 3,
                "reps": 8,
                "weight_kg": 60.0,
                "calories_burned": 150,
                "difficulty": "moderate",
                "notes": "Form improving"
            }
        ]
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        limit = int(request.args.get('limit', 50))
        
        # Build query
        query = """
            SELECT 
                log_id, workout_date, exercise_name, muscle_group,
                sets, reps, weight_kg, duration_minutes,
                calories_burned, difficulty, notes
            FROM workout_logs
            WHERE user_id = %s
        """
        
        params = [current_user['user_id']]
        
        if start_date:
            query += " AND workout_date >= %s"
            params.append(start_date)
        
        if end_date:
            query += " AND workout_date <= %s"
            params.append(end_date)
        
        query += " ORDER BY workout_date DESC, created_at DESC LIMIT %s"
        params.append(limit)
        
        cursor.execute(query, params)
        results = cursor.fetchall()
        
        workouts = []
        for row in results:
            workouts.append({
                "log_id": row[0],
                "workout_date": row[1].isoformat(),
                "exercise_name": row[2],
                "muscle_group": row[3],
                "sets": row[4],
                "reps": row[5],
                "weight_kg": float(row[6]) if row[6] else None,
                "duration_minutes": row[7],
                "calories_burned": row[8],
                "difficulty": row[9],
                "notes": row[10]
            })
        
        return jsonify({
            "success": True,
            "count": len(workouts),
            "workouts": workouts
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
# POST /api/v1/members/workouts
# Log a workout
# ============================================================
@members_bp.route('/workouts', methods=['POST'])
@token_required
@role_required(['member'])
def log_workout(current_user):
    """
    Log a workout
    
    Request Body:
    {
        "workout_date": "2026-02-21",
        "exercise_name": "Deadlift",
        "muscle_group": "Back",
        "sets": 3,
        "reps": 6,
        "weight_kg": 100.0,
        "duration_minutes": null,
        "calories_burned": 200,
        "difficulty": "hard",
        "notes": "New PR!"
    }
    
    Returns:
    {
        "success": true,
        "message": "Workout logged successfully",
        "log_id": 41
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        data = request.get_json()
        
        # Validate required fields
        required = ['exercise_name']
        for field in required:
            if field not in data:
                return jsonify({
                    "success": False,
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Validate difficulty if provided
        if data.get('difficulty') and data['difficulty'] not in ['easy', 'moderate', 'hard']:
            return jsonify({
                "success": False,
                "error": "Invalid difficulty. Must be: easy, moderate, or hard"
            }), 400
        
        # Use today's date if not provided
        workout_date = data.get('workout_date', date.today().isoformat())
        
        # Insert workout log
        cursor.execute("""
            INSERT INTO workout_logs (
                user_id, workout_date, exercise_name, muscle_group,
                sets, reps, weight_kg, duration_minutes,
                calories_burned, difficulty, notes
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING log_id
        """, (
            current_user['user_id'],
            workout_date,
            data['exercise_name'],
            data.get('muscle_group'),
            data.get('sets'),
            data.get('reps'),
            data.get('weight_kg'),
            data.get('duration_minutes'),
            data.get('calories_burned'),
            data.get('difficulty'),
            data.get('notes')
        ))
        
        log_id = cursor.fetchone()[0]
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "Workout logged successfully",
            "log_id": log_id
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


# ============================================================
# GET /api/v1/members/profile
# Get member profile
# ============================================================
@members_bp.route('/profile', methods=['GET'])
@token_required
@role_required(['member'])
def get_profile(current_user):
    """
    Get member's profile information
    
    Returns:
    {
        "success": true,
        "profile": {
            "user_id": 1,
            "email": "john@gym.com",
            "first_name": "John",
            "last_name": "Doe",
            "phone": "0300-1234567",
            "date_of_birth": "1990-01-01",
            "gender": "male",
            "created_at": "2026-01-01T10:00:00"
        }
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            SELECT 
                user_id, email, first_name, last_name, phone,
                date_of_birth, gender, created_at
            FROM users
            WHERE user_id = %s
        """, (current_user['user_id'],))
        
        result = cursor.fetchone()
        
        if not result:
            return jsonify({
                "success": False,
                "error": "Profile not found"
            }), 404
        
        profile = {
            "user_id": result[0],
            "email": result[1],
            "first_name": result[2],
            "last_name": result[3],
            "phone": result[4],
            "date_of_birth": result[5].isoformat() if result[5] else None,
            "gender": result[6],
            "created_at": result[7].isoformat()
        }
        
        return jsonify({
            "success": True,
            "profile": profile
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
# PUT /api/v1/members/profile
# Update member profile
# ============================================================
@members_bp.route('/profile', methods=['PUT'])
@token_required
@role_required(['member'])
def update_profile(current_user):
    """
    Update member profile
    
    Request Body (all optional):
    {
        "first_name": "John",
        "last_name": "Doe",
        "phone": "0300-1234567",
        "date_of_birth": "1990-01-01",
        "gender": "male"
    }
    
    Note: Email and role cannot be changed
    
    Returns:
    {
        "success": true,
        "message": "Profile updated successfully"
    }
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        data = request.get_json()
        
        # Fields that can be updated
        allowed_fields = ['first_name', 'last_name', 'phone', 'date_of_birth', 'gender']
        
        # Build update query dynamically
        update_fields = []
        params = []
        
        for field in allowed_fields:
            if field in data:
                update_fields.append(f"{field} = %s")
                params.append(data[field])
        
        if not update_fields:
            return jsonify({
                "success": False,
                "error": "No valid fields to update",
                "allowed_fields": allowed_fields
            }), 400
        
        # Add user_id to params
        params.append(current_user['user_id'])
        
        # Execute update
        query = f"""
            UPDATE users
            SET {', '.join(update_fields)}
            WHERE user_id = %s
        """
        
        cursor.execute(query, params)
        conn.commit()
        
        return jsonify({
            "success": True,
            "message": "Profile updated successfully"
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