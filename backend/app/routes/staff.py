# app/routes/staff.py
# STEP 5 - Staff Endpoints

from flask import Blueprint, request, jsonify
from app.middleware import token_required, role_required
from app.db import get_db_connection as get_connection, release_connection
import psycopg2
import psycopg2.extras
import datetime

staff_bp = Blueprint('staff', __name__)


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/v1/staff/checkin
# attendance columns: attendance_id, user_id, check_in_time, check_out_time,
#                     duration_minutes, locker_assigned, access_areas
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/checkin', methods=['POST'])
@token_required
@role_required('staff')
def checkin_member(current_user):
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    member_id = data.get('member_id')
    if not member_id:
        return jsonify({'success': False, 'error': 'member_id is required'}), 400

    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # Verify member exists
        cursor.execute("""
            SELECT user_id, first_name || ' ' || last_name AS full_name
            FROM users WHERE user_id = %s AND role = 'member'
        """, (member_id,))
        member = cursor.fetchone()
        if not member:
            return jsonify({'success': False, 'error': 'Member not found'}), 404

        # Check active membership
        cursor.execute("""
            SELECT m.membership_id, mt.tier_name
            FROM   memberships m
            JOIN   membership_tiers mt ON m.tier_id = mt.tier_id
            WHERE  m.user_id = %s AND m.status = 'active'
              AND  m.end_date >= CURRENT_DATE
        """, (member_id,))
        membership = cursor.fetchone()
        if not membership:
            return jsonify({
                'success': False,
                'error':   'Member does not have an active membership',
                'member':  member['full_name']
            }), 403

        # Prevent double check-in
        cursor.execute("""
            SELECT attendance_id FROM attendance
            WHERE  user_id        = %s
              AND  check_in_time  >= CURRENT_DATE
              AND  check_out_time IS NULL
        """, (member_id,))
        if cursor.fetchone():
            return jsonify({'success': False, 'error': 'Member is already checked in'}), 409

        # Record check-in
        cursor.execute("""
            INSERT INTO attendance (user_id, check_in_time)
            VALUES (%s, CURRENT_TIMESTAMP)
            RETURNING attendance_id, check_in_time
        """, (member_id,))
        attendance = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success':         True,
            'message':         f"{member['full_name']} checked in successfully",
            'attendance_id':   attendance['attendance_id'],
            'member':          member['full_name'],
            'membership_tier': membership['tier_name'],
            'check_in_time':   str(attendance['check_in_time'])
        }), 201

    except Exception as e:
        if conn:
            try: conn.rollback()
            except: pass
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/v1/staff/checkout
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/checkout', methods=['POST'])
@token_required
@role_required('staff')
def checkout_member(current_user):
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    member_id = data.get('member_id')
    if not member_id:
        return jsonify({'success': False, 'error': 'member_id is required'}), 400

    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT a.attendance_id, a.check_in_time,
                   u.first_name || ' ' || u.last_name AS full_name
            FROM   attendance a
            JOIN   users      u ON a.user_id = u.user_id
            WHERE  a.user_id        = %s
              AND  a.check_in_time  >= CURRENT_DATE
              AND  a.check_out_time IS NULL
        """, (member_id,))
        attendance = cursor.fetchone()

        if not attendance:
            return jsonify({'success': False,
                            'error': 'No active check-in found for this member today'}), 404

        cursor.execute("""
            UPDATE attendance
            SET    check_out_time = CURRENT_TIMESTAMP
            WHERE  attendance_id  = %s
            RETURNING check_out_time,
                EXTRACT(EPOCH FROM (check_out_time - check_in_time))/60 AS duration_minutes
        """, (attendance['attendance_id'],))
        result = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success':          True,
            'message':          f"{attendance['full_name']} checked out successfully",
            'attendance_id':    attendance['attendance_id'],
            'member':           attendance['full_name'],
            'check_in_time':    str(attendance['check_in_time']),
            'check_out_time':   str(result['check_out_time']),
            'duration_minutes': round(float(result['duration_minutes'] or 0), 1)
        }), 200

    except Exception as e:
        if conn:
            try: conn.rollback()
            except: pass
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/staff/attendance/today
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/attendance/today', methods=['GET'])
@token_required
@role_required('staff')
def today_attendance(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT
                a.attendance_id,
                u.first_name || ' ' || u.last_name AS member_name,
                u.email,
                mt.tier_name AS membership_tier,
                a.check_in_time,
                a.check_out_time,
                a.duration_minutes,
                CASE WHEN a.check_out_time IS NULL THEN 'present' ELSE 'left' END AS status
            FROM   attendance     a
            JOIN   users          u  ON a.user_id = u.user_id
            LEFT JOIN memberships m  ON u.user_id = m.user_id
                AND m.status = 'active' AND m.end_date >= CURRENT_DATE
            LEFT JOIN membership_tiers mt ON m.tier_id = mt.tier_id
            WHERE  a.check_in_time >= CURRENT_DATE
            ORDER  BY a.check_in_time DESC
        """)
        records = cursor.fetchall()
        currently_in = sum(1 for r in records if r['status'] == 'present')

        return jsonify({
            'success':      True,
            'date':         str(datetime.date.today()),
            'total_visits': len(records),
            'currently_in': currently_in,
            'attendance':   [{
                **dict(r),
                'check_in_time':  str(r['check_in_time']),
                'check_out_time': str(r['check_out_time']) if r['check_out_time'] else None
            } for r in records]
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# PUT /api/v1/staff/lockers/<id>
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/lockers/<int:locker_id>', methods=['PUT'])
@token_required
@role_required('staff')
def manage_locker(current_user, locker_id):
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    action = data.get('action')
    if action not in ['assign', 'release']:
        return jsonify({'success': False, 'error': 'action must be assign or release'}), 400

    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT locker_id, locker_number, status, current_user_id, location
            FROM lockers WHERE locker_id = %s
        """, (locker_id,))
        locker = cursor.fetchone()
        if not locker:
            return jsonify({'success': False, 'error': 'Locker not found'}), 404

        if action == 'assign':
            member_id = data.get('member_id')
            if not member_id:
                return jsonify({'success': False, 'error': 'member_id is required for assign'}), 400
            if locker['status'] == 'occupied':
                return jsonify({'success': False, 'error': 'Locker is already occupied'}), 409

            cursor.execute("""
                UPDATE lockers
                SET    status = 'occupied', current_user_id = %s,
                       assigned_at = CURRENT_TIMESTAMP
                WHERE  locker_id = %s
                RETURNING locker_number, status, location
            """, (member_id, locker_id))
            updated = cursor.fetchone()
            conn.commit()
            return jsonify({
                'success': True,
                'message': f"Locker {updated['locker_number']} assigned successfully",
                'locker':  dict(updated)
            }), 200

        else:  # release
            if locker['status'] == 'available':
                return jsonify({'success': False, 'error': 'Locker is already available'}), 400

            cursor.execute("""
                UPDATE lockers
                SET    status = 'available', current_user_id = NULL, assigned_at = NULL
                WHERE  locker_id = %s
                RETURNING locker_number, status, location
            """, (locker_id,))
            updated = cursor.fetchone()
            conn.commit()
            return jsonify({
                'success': True,
                'message': f"Locker {updated['locker_number']} released successfully",
                'locker':  dict(updated)
            }), 200

    except Exception as e:
        if conn:
            try: conn.rollback()
            except: pass
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/staff/equipment
# equipment status values: available, in_use, maintenance, broken
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/equipment', methods=['GET'])
@token_required
@role_required('staff')
def get_equipment(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT equipment_id, equipment_name, equipment_type,
                   zone, manufacturer, model_number, status,
                   total_usage_hours, last_maintenance_date,
                   next_maintenance_due, purchase_date, purchase_cost
            FROM   equipment
            ORDER  BY zone, equipment_name
        """)
        equipment = cursor.fetchall()

        summary = {
            'total':       len(equipment),
            'available':   sum(1 for e in equipment if e['status'] == 'available'),
            'in_use':      sum(1 for e in equipment if e['status'] == 'in_use'),
            'maintenance': sum(1 for e in equipment if e['status'] == 'maintenance'),
            'broken':      sum(1 for e in equipment if e['status'] == 'broken'),
        }

        return jsonify({
            'success':   True,
            'summary':   summary,
            'equipment': [{
                **dict(e),
                'last_maintenance_date': str(e['last_maintenance_date']) if e['last_maintenance_date'] else None,
                'next_maintenance_due':  str(e['next_maintenance_due'])  if e['next_maintenance_due']  else None,
                'purchase_date':         str(e['purchase_date'])         if e['purchase_date']         else None,
            } for e in equipment]
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# PUT /api/v1/staff/equipment/<id>
# valid status: available, in_use, maintenance, broken
# ─────────────────────────────────────────────────────────────────────────────
@staff_bp.route('/equipment/<int:equipment_id>', methods=['PUT'])
@token_required
@role_required('staff')
def update_equipment(current_user, equipment_id):
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    allowed_statuses = ['available', 'in_use', 'maintenance', 'broken']

    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("SELECT equipment_id, equipment_name FROM equipment WHERE equipment_id = %s",
                       (equipment_id,))
        equipment = cursor.fetchone()
        if not equipment:
            return jsonify({'success': False, 'error': 'Equipment not found'}), 404

        new_status = data.get('status')
        if new_status and new_status not in allowed_statuses:
            return jsonify({'success': False,
                            'error': f'status must be one of: {allowed_statuses}'}), 400

        updates = []
        values  = []
        if new_status:
            updates.append("status = %s")
            values.append(new_status)
        if data.get('last_maintenance_date'):
            updates.append("last_maintenance_date = %s")
            values.append(data['last_maintenance_date'])
        if data.get('next_maintenance_due'):
            updates.append("next_maintenance_due = %s")
            values.append(data['next_maintenance_due'])
        if data.get('total_usage_hours') is not None:
            updates.append("total_usage_hours = %s")
            values.append(data['total_usage_hours'])

        if not updates:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        values.append(equipment_id)
        cursor.execute(f"""
            UPDATE equipment SET {', '.join(updates)}
            WHERE equipment_id = %s
            RETURNING equipment_id, equipment_name, status,
                      last_maintenance_date, next_maintenance_due
        """, values)
        updated = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success':   True,
            'message':   f"Equipment '{updated['equipment_name']}' updated successfully",
            'equipment': {
                **dict(updated),
                'last_maintenance_date': str(updated['last_maintenance_date']) if updated['last_maintenance_date'] else None,
                'next_maintenance_due':  str(updated['next_maintenance_due'])  if updated['next_maintenance_due']  else None,
            }
        }), 200

    except Exception as e:
        if conn:
            try: conn.rollback()
            except: pass
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)