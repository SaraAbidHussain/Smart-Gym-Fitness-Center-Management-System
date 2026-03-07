# app/routes/trainers.py
# STEP 5 - Trainer Endpoints

from flask import Blueprint, request, jsonify
from app.middleware import token_required, role_required
from app.db import get_db_connection as get_connection, release_connection
import psycopg2
import psycopg2.extras

trainers_bp = Blueprint('trainers', __name__)


def get_trainer_id(cursor, user_id):
    cursor.execute("SELECT trainer_id FROM trainers WHERE user_id = %s", (user_id,))
    row = cursor.fetchone()
    return row['trainer_id'] if row else None


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/trainers/clients
# ─────────────────────────────────────────────────────────────────────────────
@trainers_bp.route('/clients', methods=['GET'])
@token_required
@role_required('trainer')
def get_clients(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        trainer_id = get_trainer_id(cursor, current_user['user_id'])
        if not trainer_id:
            return jsonify({'success': False, 'error': 'Trainer profile not found'}), 404

        cursor.execute("""
            SELECT
                u.user_id,
                u.first_name || ' ' || u.last_name AS full_name,
                u.email,
                u.phone,
                mt.tier_name AS membership_tier,
                m.status     AS membership_status,
                m.end_date   AS membership_expires,
                COUNT(DISTINCT wp.plan_id)           AS workout_plans,
                COUNT(DISTINCT np.nutrition_plan_id) AS nutrition_plans
            FROM   users u
            LEFT JOIN memberships      m  ON u.user_id = m.user_id
                AND m.status = 'active' AND m.end_date >= CURRENT_DATE
            LEFT JOIN membership_tiers mt ON m.tier_id = mt.tier_id
            LEFT JOIN workout_plans    wp ON wp.user_id = u.user_id
                AND wp.trainer_id = %s
            LEFT JOIN nutrition_plans  np ON np.user_id = u.user_id
                AND np.trainer_id = %s
            WHERE (wp.trainer_id = %s OR np.trainer_id = %s)
            GROUP  BY u.user_id, u.first_name, u.last_name,
                      u.email, u.phone, mt.tier_name,
                      m.status, m.end_date
            ORDER  BY u.first_name, u.last_name
        """, (trainer_id, trainer_id, trainer_id, trainer_id))
        clients = cursor.fetchall()

        return jsonify({'success': True, 'count': len(clients),
                        'clients': [dict(c) for c in clients]}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor: 
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# GET /api/v1/trainers/performance
# ─────────────────────────────────────────────────────────────────────────────
@trainers_bp.route('/performance', methods=['GET'])
@token_required
@role_required('trainer')
def get_performance(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT * FROM trainer_performance_view
            WHERE trainer_id = (SELECT trainer_id FROM trainers WHERE user_id = %s)
        """, (current_user['user_id'],))
        row = cursor.fetchone()

        if not row:
            return jsonify({'success': False, 'error': 'Performance data not found'}), 404

        return jsonify({'success': True, 'performance': dict(row)}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)


# ─────────────────────────────────────────────────────────────────────────────
# GET/POST /api/v1/trainers/workout-plans
# workout_plans columns: plan_id, user_id, trainer_id, plan_name, description,
#                        goal, start_date, end_date, is_active, created_at
# ─────────────────────────────────────────────────────────────────────────────
@trainers_bp.route('/workout-plans', methods=['GET', 'POST'])
@token_required
@role_required('trainer')
def workout_plans(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        trainer_id = get_trainer_id(cursor, current_user['user_id'])
        if not trainer_id:
            return jsonify({'success': False, 'error': 'Trainer profile not found'}), 404

        if request.method == 'GET':
            cursor.execute("""
                SELECT
                    wp.plan_id,
                    wp.plan_name,
                    wp.goal,
                    wp.description,
                    wp.start_date,
                    wp.end_date,
                    wp.is_active,
                    wp.created_at,
                    u.first_name || ' ' || u.last_name AS member_name
                FROM   workout_plans wp
                JOIN   users         u ON wp.user_id = u.user_id
                WHERE  wp.trainer_id = %s
                ORDER  BY wp.created_at DESC
            """, (trainer_id,))
            plans = cursor.fetchall()
            return jsonify({
                'success': True,
                'count':   len(plans),
                'plans':   [{
                    **dict(p),
                    'start_date': str(p['start_date']) if p['start_date'] else None,
                    'end_date':   str(p['end_date'])   if p['end_date']   else None,
                } for p in plans]
            }), 200

        # POST
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400

        for field in ['user_id', 'plan_name', 'goal']:
            if not data.get(field):
                return jsonify({'success': False, 'error': f'{field} is required'}), 400

        cursor.execute("SELECT user_id FROM users WHERE user_id = %s AND role = 'member'",
                       (data['user_id'],))
        if not cursor.fetchone():
            return jsonify({'success': False, 'error': 'Member not found'}), 404

        cursor.execute("""
            INSERT INTO workout_plans (
                trainer_id, user_id, plan_name, goal, description,
                start_date, end_date, is_active
            )
            VALUES (%s, %s, %s, %s, %s, CURRENT_DATE,
                    CURRENT_DATE + INTERVAL '4 weeks', TRUE)
            RETURNING plan_id, plan_name, goal, start_date, created_at
        """, (
            trainer_id,
            data['user_id'],
            data['plan_name'],
            data['goal'],
            data.get('description', '')
        ))
        plan = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success': True,
            'message': 'Workout plan created successfully',
            'plan': {**dict(plan), 'start_date': str(plan['start_date'])}
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
# GET/POST /api/v1/trainers/nutrition-plans
# nutrition_plans columns: nutrition_plan_id, user_id, trainer_id, plan_name,
#   daily_calories_target, protein_grams, carbs_grams, fats_grams,
#   meals_plan, start_date (NOT NULL), end_date, is_active, created_at
# ─────────────────────────────────────────────────────────────────────────────
@trainers_bp.route('/nutrition-plans', methods=['GET', 'POST'])
@token_required
@role_required('trainer')
def nutrition_plans(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        trainer_id = get_trainer_id(cursor, current_user['user_id'])
        if not trainer_id:
            return jsonify({'success': False, 'error': 'Trainer profile not found'}), 404

        if request.method == 'GET':
            cursor.execute("""
                SELECT
                    np.nutrition_plan_id,
                    np.plan_name,
                    np.daily_calories_target,
                    np.protein_grams,
                    np.carbs_grams,
                    np.fats_grams,
                    np.start_date,
                    np.end_date,
                    np.is_active,
                    np.created_at,
                    u.first_name || ' ' || u.last_name AS member_name
                FROM   nutrition_plans np
                JOIN   users           u ON np.user_id = u.user_id
                WHERE  np.trainer_id = %s
                ORDER  BY np.created_at DESC
            """, (trainer_id,))
            plans = cursor.fetchall()
            return jsonify({
                'success': True,
                'count':   len(plans),
                'plans':   [{
                    **dict(p),
                    'start_date': str(p['start_date']) if p['start_date'] else None,
                    'end_date':   str(p['end_date'])   if p['end_date']   else None,
                } for p in plans]
            }), 200

        # POST
        data = request.get_json()
        if not data:
            return jsonify({'success': False, 'error': 'No data provided'}), 400

        for field in ['user_id', 'plan_name', 'daily_calories']:
            if not data.get(field):
                return jsonify({'success': False, 'error': f'{field} is required'}), 400

        cursor.execute("SELECT user_id FROM users WHERE user_id = %s AND role = 'member'",
                       (data['user_id'],))
        if not cursor.fetchone():
            return jsonify({'success': False, 'error': 'Member not found'}), 404

        cursor.execute("""
            INSERT INTO nutrition_plans (
                trainer_id, user_id, plan_name,
                daily_calories_target, protein_grams, carbs_grams,
                fats_grams, start_date, end_date, is_active
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s,
                    CURRENT_DATE, CURRENT_DATE + INTERVAL '4 weeks', TRUE)
            RETURNING nutrition_plan_id, plan_name, daily_calories_target, start_date, created_at
        """, (
            trainer_id,
            data['user_id'],
            data['plan_name'],
            data['daily_calories'],
            data.get('protein_grams'),
            data.get('carbs_grams'),
            data.get('fat_grams')
        ))
        plan = cursor.fetchone()
        conn.commit()

        return jsonify({
            'success': True,
            'message': 'Nutrition plan created successfully',
            'plan': {**dict(plan), 'start_date': str(plan['start_date'])}
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
# GET /api/v1/trainers/schedule
# ─────────────────────────────────────────────────────────────────────────────
@trainers_bp.route('/schedule', methods=['GET'])
@token_required
@role_required('trainer')
def get_schedule(current_user):
    conn = cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        trainer_id = get_trainer_id(cursor, current_user['user_id'])
        if not trainer_id:
            return jsonify({'success': False, 'error': 'Trainer profile not found'}), 404

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
                COUNT(cb.booking_id) AS confirmed_bookings
            FROM   class_schedules  cs
            JOIN   classes          c  ON cs.class_id   = c.class_id
            LEFT JOIN class_bookings cb ON cb.schedule_id = cs.schedule_id
                AND cb.status = 'confirmed'
            WHERE  cs.trainer_id    = %s
              AND  cs.schedule_date >= CURRENT_DATE
            GROUP  BY cs.schedule_id, c.class_name, c.class_type,
                      c.difficulty_level, c.duration_minutes,
                      cs.schedule_date, cs.start_time, cs.end_time,
                      cs.room_number, cs.current_capacity,
                      c.max_capacity, cs.status
            ORDER  BY cs.schedule_date, cs.start_time
        """, (trainer_id,))
        schedules = cursor.fetchall()

        return jsonify({
            'success':   True,
            'count':     len(schedules),
            'schedules': [{
                **dict(s),
                'schedule_date': str(s['schedule_date']),
                'start_time':    str(s['start_time']),
                'end_time':      str(s['end_time'])
            } for s in schedules]
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if cursor:
            try: cursor.close()
            except: pass
        if conn: release_connection(conn)