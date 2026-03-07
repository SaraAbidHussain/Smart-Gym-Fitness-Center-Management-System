# app/routes/payments.py
# STEP 4 - Transaction Implementation
# Scenario 1: Membership Purchase (ACID Compliant)

from flask import Blueprint, request, jsonify
from app.middleware import token_required, role_required
from app.db import get_db_connection as get_connection, release_connection
import psycopg2
import psycopg2.extras

payments_bp = Blueprint('payments', __name__)


@payments_bp.route('/purchase-membership', methods=['POST'])
@token_required
@role_required('member')
def purchase_membership(current_user):
    """
    ACID Transaction: Membership Purchase
    BEGIN
      1. Validate tier_id exists
      2. Check no active membership already
      3. INSERT payment record
      4. INSERT membership record
      5. If Premium/VIP: SELECT FOR UPDATE locker → assign
    COMMIT or ROLLBACK on any failure
    """
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    tier_id        = data.get('tier_id')
    payment_method = data.get('payment_method')

    if not tier_id:
        return jsonify({'success': False, 'error': 'tier_id is required'}), 400
    if not payment_method:
        return jsonify({'success': False, 'error': 'payment_method is required'}), 400

    allowed_methods = ['cash', 'credit_card', 'debit_card', 'online']
    if payment_method not in allowed_methods:
        return jsonify({
            'success': False,
            'error': f'payment_method must be one of: {allowed_methods}'
        }), 400

    conn   = None
    cursor = None

    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # ── PRE-TRANSACTION READS ─────────────────────────────────────────────

        # 1. Validate tier exists
        cursor.execute("""
            SELECT tier_id, tier_name, monthly_fee
            FROM   membership_tiers
            WHERE  tier_id = %s
        """, (tier_id,))
        tier = cursor.fetchone()

        if not tier:
            return jsonify({
                'success': False,
                'error': f'Membership tier {tier_id} does not exist'
            }), 404

        # 2. Check user has no active membership
        cursor.execute("""
            SELECT membership_id
            FROM   memberships
            WHERE  user_id  = %s
              AND  status   = 'active'
              AND  end_date >= CURRENT_DATE
        """, (current_user['user_id'],))
        existing = cursor.fetchone()

        if existing:
            return jsonify({
                'success': False,
                'error': 'You already have an active membership',
                'existing_membership_id': existing['membership_id']
            }), 409

        # ── BEGIN TRANSACTION ─────────────────────────────────────────────────
        conn.rollback()
        conn.autocommit = False

        # Step 3: INSERT payment record
        cursor.execute("""
            INSERT INTO payments (
                user_id, payment_type, amount,
                payment_method, status, description
            )
            VALUES (%s, 'membership', %s, %s, 'completed', %s)
            RETURNING payment_id, amount, payment_date
        """, (
            current_user['user_id'],
            float(tier['monthly_fee']),
            payment_method,
            f"{tier['tier_name']} membership purchase"
        ))
        payment = cursor.fetchone()

        # Step 4: INSERT membership record
        # trg_auto_expire_memberships fires here automatically
        cursor.execute("""
            INSERT INTO memberships (
                user_id, tier_id,
                start_date, end_date,
                status, auto_renew
            )
            VALUES (
                %s, %s,
                CURRENT_DATE,
                CURRENT_DATE + INTERVAL '1 month',
                'active',
                TRUE
            )
            RETURNING membership_id, start_date, end_date, status
        """, (current_user['user_id'], tier_id))
        membership = cursor.fetchone()

        # Step 5: Assign locker for Premium (2) or VIP (3)
        # SELECT FOR UPDATE prevents two users getting same locker (race condition)
        assigned_locker = None
        if int(tier_id) in [2, 3]:
            cursor.execute("""
                SELECT locker_id, locker_number, location
                FROM   lockers
                WHERE  status = 'available'
                ORDER  BY locker_id
                LIMIT  1
                FOR UPDATE SKIP LOCKED
            """)
            locker = cursor.fetchone()

            if not locker:
                conn.rollback()
                conn.autocommit = True
                return jsonify({
                    'success': False,
                    'error': 'No lockers available for Premium/VIP. '
                             'Transaction rolled back — you were not charged.',
                    'hint': 'Please contact staff or try again later'
                }), 409

            cursor.execute("""
                UPDATE lockers
                SET    status          = 'occupied',
                       current_user_id = %s,
                       assigned_at     = CURRENT_TIMESTAMP
                WHERE  locker_id = %s
            """, (current_user['user_id'], locker['locker_id']))

            assigned_locker = {
                'locker_id':     locker['locker_id'],
                'locker_number': locker['locker_number'],
                'location':      locker['location']
            }

        # ── COMMIT ────────────────────────────────────────────────────────────
        conn.commit()
        conn.autocommit = True

        return jsonify({
            'success': True,
            'message': 'Membership purchased successfully',
            'transaction': {
                'payment': {
                    'payment_id':   payment['payment_id'],
                    'amount':       float(payment['amount']),
                    'payment_date': str(payment['payment_date']),
                    'method':       payment_method,
                    'status':       'completed'
                },
                'membership': {
                    'membership_id': membership['membership_id'],
                    'tier':          tier['tier_name'],
                    'start_date':    str(membership['start_date']),
                    'end_date':      str(membership['end_date']),
                    'status':        membership['status']
                },
                'locker': assigned_locker
            }
        }), 201

    except psycopg2.Error as db_err:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except:
                pass
        return jsonify({
            'success': False,
            'error':   'Database error — transaction rolled back',
            'details': str(db_err)
        }), 500

    except Exception as e:
        if conn:
            try:
                conn.rollback()
                conn.autocommit = True
            except:
                pass
        return jsonify({
            'success': False,
            'error':   'Unexpected error — transaction rolled back',
            'details': str(e)
        }), 500

    finally:
        if cursor:
            try:
                cursor.close()
            except:
                pass
        if conn:
            release_connection(conn)


@payments_bp.route('/history', methods=['GET'])
@token_required
@role_required('member')
def payment_history(current_user):
    """Get payment history for the logged-in member"""
    conn   = None
    cursor = None
    try:
        conn   = get_connection()
        cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cursor.execute("""
            SELECT payment_id, payment_type, amount,
                   payment_method, payment_date,
                   description, status
            FROM   payments
            WHERE  user_id = %s
            ORDER  BY payment_date DESC
        """, (current_user['user_id'],))
        rows = cursor.fetchall()

        return jsonify({
            'success':  True,
            'count':    len(rows),
            'payments': [dict(r) for r in rows]
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

    finally:
        if cursor:
            try:
                cursor.close()
            except:
                pass
        if conn:
            release_connection(conn)