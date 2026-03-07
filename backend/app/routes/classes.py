# app/routes/classes.py
# STEP 4 - Transaction Implementation
# Scenario 2: Class Booking with Capacity Control (ACID Compliant)
#
# TRIGGERS WORKING WITH THIS CODE:
#   trg_prevent_overbooking  → BEFORE INSERT on class_bookings
#   trg_promote_waitlist     → AFTER UPDATE on class_bookings

from flask import Blueprint, request, jsonify
from app.middleware import token_required, role_required
from app.db import get_db_connection as get_connection, release_connection
import psycopg2
import psycopg2.extras

classes_bp = Blueprint('classes', __name__)


@classes_bp.route('/', methods=['GET'])
def get_classes():
    """Public endpoint — list all class types"""
    conn   = None
    cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute("""
            SELECT class_id, class_name, description,
                   class_type, duration_minutes,
                   difficulty_level, max_capacity
            FROM   classes
            ORDER  BY class_name
        """)
        rows = cursor.fetchall()
        return jsonify({'success': True, 'count': len(rows), 'classes': [{k: str(v) if hasattr(v, 'strftime') else v for k, v in r.items()} for r in rows]}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn:
            release_connection(conn)


@classes_bp.route('/schedule', methods=['GET'])
def get_schedule():
    """Public endpoint — upcoming class schedules"""
    conn   = None
    cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute("""
            SELECT
                cs.schedule_id,
                c.class_name,
                c.class_type,
                c.difficulty_level,
                c.duration_minutes,
                cs.schedule_date,
                cs.start_time,
                cs.end_time,
                cs.room_number,
                cs.current_capacity,
                c.max_capacity,
                (c.max_capacity - cs.current_capacity) AS spots_available,
                cs.status,
                u.first_name || ' ' || u.last_name AS trainer_name
            FROM   class_schedules cs
            JOIN   classes         c  ON cs.class_id   = c.class_id
            JOIN   trainers        t  ON cs.trainer_id = t.trainer_id
            JOIN   users           u  ON t.user_id     = u.user_id
            WHERE  cs.schedule_date >= CURRENT_DATE
              AND  cs.status = 'scheduled'
            ORDER  BY cs.schedule_date, cs.start_time
        """)
        rows = cursor.fetchall()
        return jsonify({'success': True, 'count': len(rows), 'schedules': [{k: str(v) if hasattr(v, 'strftime') else v for k, v in r.items()} for r in rows]}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn:
            release_connection(conn)


@classes_bp.route('/book', methods=['POST'])
@token_required
@role_required('member')
def book_class(current_user):
    """
    ACID Transaction: Class Booking with Capacity Control
    BEGIN
      1. Check active membership
      2. Check schedule exists and is 'scheduled'
      3. Check no duplicate booking
      4. SELECT FOR UPDATE on class_schedules  ← locks row, prevents race condition
      5a. spots available → INSERT confirmed + UPDATE capacity
      5b. class full      → INSERT waitlist with sequential position
    COMMIT or ROLLBACK
    trg_prevent_overbooking fires on INSERT as database-level safety net
    """
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    schedule_id = data.get('schedule_id')
    if not schedule_id:
        return jsonify({'success': False, 'error': 'schedule_id is required'}), 400

    conn   = None
    cursor = None

    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # ── PRE-TRANSACTION VALIDATION ────────────────────────────────────────

        # 1. Check active membership
        cursor.execute("""
            SELECT m.membership_id, mt.tier_name
            FROM   memberships      m
            JOIN   membership_tiers mt ON m.tier_id  = mt.tier_id
            WHERE  m.user_id  = %s
              AND  m.status   = 'active'
              AND  m.end_date >= CURRENT_DATE
        """, (current_user['user_id'],))
        membership = cursor.fetchone()

        if not membership:
            return jsonify({
                'success': False,
                'error':   'Active membership required to book classes',
                'message': 'Please purchase a membership first'
            }), 403

        # 2. Check schedule exists
        cursor.execute("""
            SELECT cs.schedule_id, cs.status, cs.schedule_date,
                   c.class_name, c.max_capacity
            FROM   class_schedules cs
            JOIN   classes         c ON cs.class_id = c.class_id
            WHERE  cs.schedule_id = %s
        """, (schedule_id,))
        pre_check = cursor.fetchone()

        if not pre_check:
            return jsonify({'success': False, 'error': f'Schedule {schedule_id} not found'}), 404

        if pre_check['status'] != 'scheduled':
            return jsonify({
                'success': False,
                'error':   f"Class is '{pre_check['status']}' — cannot book"
            }), 400

        # 3. Check duplicate booking
        cursor.execute("""
            SELECT booking_id, status
            FROM   class_bookings
            WHERE  schedule_id = %s
              AND  user_id     = %s
              AND  status     != 'cancelled'
        """, (schedule_id, current_user['user_id']))
        duplicate = cursor.fetchone()

        if duplicate:
            return jsonify({
                'success':         False,
                'error':           'You have already booked this class',
                'existing_status': duplicate['status']
            }), 409

        # ── BEGIN TRANSACTION ─────────────────────────────────────────────────
        conn.rollback()
        conn.autocommit = False

        # Step 4: SELECT FOR UPDATE — locks this schedule row
        # Critical for concurrency: other transactions booking this class WAIT here
        cursor.execute("""
            SELECT
                cs.schedule_id,
                cs.current_capacity,
                c.max_capacity,
                c.class_name,
                cs.schedule_date,
                cs.start_time
            FROM   class_schedules cs
            JOIN   classes         c ON cs.class_id = c.class_id
            WHERE  cs.schedule_id = %s
            FOR UPDATE
        """, (schedule_id,))
        schedule = cursor.fetchone()

        current_cap     = schedule['current_capacity']
        max_cap         = schedule['max_capacity']
        spots_available = max_cap - current_cap

        if spots_available > 0:
            # ── CONFIRMED BOOKING ─────────────────────────────────────────────
            # trg_prevent_overbooking fires here as extra safety net
            cursor.execute("""
                INSERT INTO class_bookings (
                    schedule_id, user_id, status,
                    booking_date, position_in_waitlist
                )
                VALUES (%s, %s, 'confirmed', CURRENT_TIMESTAMP, NULL)
                RETURNING booking_id, status, booking_date
            """, (schedule_id, current_user['user_id']))
            booking = cursor.fetchone()

            # Update capacity
            cursor.execute("""
                UPDATE class_schedules
                SET    current_capacity = current_capacity + 1
                WHERE  schedule_id = %s
            """, (schedule_id,))

            conn.commit()
            conn.autocommit = True

            return jsonify({
                'success': True,
                'message': 'Class booked successfully — confirmed!',
                'booking': {
                    'booking_id':           booking['booking_id'],
                    'class_name':           schedule['class_name'],
                    'schedule_date':        str(schedule['schedule_date']),
                    'start_time':           str(schedule['start_time']),
                    'status':               'confirmed',
                    'position_in_waitlist': None,
                    'spots_remaining':      spots_available - 1
                }
            }), 201

        else:
            # ── WAITLIST BOOKING ──────────────────────────────────────────────
            cursor.execute("""
                SELECT COALESCE(MAX(position_in_waitlist), 0) + 1 AS next_position
                FROM   class_bookings
                WHERE  schedule_id = %s AND status = 'waitlist'
            """, (schedule_id,))
            result       = cursor.fetchone()
            waitlist_pos = result['next_position']

            cursor.execute("""
                INSERT INTO class_bookings (
                    schedule_id, user_id, status,
                    booking_date, position_in_waitlist
                )
                VALUES (%s, %s, 'waitlist', CURRENT_TIMESTAMP, %s)
                RETURNING booking_id, status, booking_date, position_in_waitlist
            """, (schedule_id, current_user['user_id'], waitlist_pos))
            booking = cursor.fetchone()

            conn.commit()
            conn.autocommit = True

            return jsonify({
                'success': True,
                'message': f"Class is full. Added to waitlist at position {waitlist_pos}.",
                'booking': {
                    'booking_id':           booking['booking_id'],
                    'class_name':           schedule['class_name'],
                    'schedule_date':        str(schedule['schedule_date']),
                    'start_time':           str(schedule['start_time']),
                    'status':               'waitlist',
                    'position_in_waitlist': waitlist_pos
                }
            }), 201

    except psycopg2.Error as db_err:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except: pass
        error_msg = str(db_err)
        if 'capacity' in error_msg.lower() or 'overbook' in error_msg.lower():
            return jsonify({
                'success': False,
                'error':   'Class is full — prevented by database trigger',
                'details': error_msg
            }), 409
        return jsonify({
            'success': False,
            'error':   'Database error — transaction rolled back',
            'details': error_msg
        }), 500

    except Exception as e:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except: pass
        return jsonify({
            'success': False,
            'error':   'Unexpected error — transaction rolled back',
            'details': str(e)
        }), 500

    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn:
            release_connection(conn)


@classes_bp.route('/cancel/<int:booking_id>', methods=['DELETE'])
@token_required
@role_required('member')
def cancel_booking(current_user, booking_id):
    """
    Cancel booking.
    If confirmed: decrease capacity.
    trg_promote_waitlist fires AFTER UPDATE → auto-promotes first waitlist member.
    """
    conn   = None
    cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT b.booking_id, b.schedule_id, b.status,
                   c.class_name, cs.schedule_date
            FROM   class_bookings  b
            JOIN   class_schedules cs ON b.schedule_id = cs.schedule_id
            JOIN   classes         c  ON cs.class_id   = c.class_id
            WHERE  b.booking_id = %s AND b.user_id = %s
        """, (booking_id, current_user['user_id']))
        booking = cursor.fetchone()

        if not booking:
            return jsonify({'success': False, 'error': 'Booking not found or does not belong to you'}), 404

        if booking['status'] == 'cancelled':
            return jsonify({'success': False, 'error': 'Booking is already cancelled'}), 400

        # ── BEGIN TRANSACTION ─────────────────────────────────────────────────
        conn.rollback()
        conn.autocommit = False

        was_confirmed = booking['status'] == 'confirmed'

        # Cancel booking — trg_promote_waitlist fires AFTER this UPDATE
        cursor.execute("""
            UPDATE class_bookings
            SET    status = 'cancelled'
            WHERE  booking_id = %s
        """, (booking_id,))

        if was_confirmed:
            cursor.execute("""
                UPDATE class_schedules
                SET    current_capacity = current_capacity - 1
                WHERE  schedule_id = %s
            """, (booking['schedule_id'],))

        conn.commit()
        conn.autocommit = True

        return jsonify({
            'success':              True,
            'message':              'Booking cancelled successfully',
            'cancelled_booking_id': booking_id,
            'note':                 'If confirmed, first waitlist member was automatically promoted'
        }), 200

    except psycopg2.Error as db_err:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except: pass
        return jsonify({'success': False, 'error': 'Database error — rolled back', 'details': str(db_err)}), 500

    except Exception as e:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except: pass
        return jsonify({'success': False, 'error': 'Unexpected error — rolled back', 'details': str(e)}), 500

    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn:
            release_connection(conn)