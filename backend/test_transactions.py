# test_transactions.py
# STEP 4 - Transaction Tests with AUTO-CLEANUP
# Member 1: ahmed.khan@gmail.com  (password: gym123)       — seed user, has active membership
# Member 2: test.member@gym.com   (password: SecurePass123) — created by test_auth.py, no membership

import requests
import json
import psycopg2

BASE_URL = "http://localhost:5000"

DB_CONFIG = {
    "host":     "172.24.96.1",
    "port":     5432,
    "database": "gymdb",
    "user":     "postgres",
    "password": "ak1234"
}

def pretty(resp):
    try:
        return json.dumps(resp.json(), indent=2, default=str)
    except:
        return resp.text[:300]

def header(title):
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60)

def test(label, expected, resp):
    got  = resp.status_code
    icon = "" if got == expected else "❌"
    print(f"\n{icon} {label}")
    print(f"   Expected: {expected} | Got: {got}")
    print(f"   {pretty(resp)}")
    return got == expected

# ── AUTO CLEANUP ──────────────────────────────────────────────────────────────
def cleanup():
    """
    Removes test data created by previous runs.
    Keeps all original seed data safe.
    """
    print("\n Auto-cleaning test data from previous runs...")
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cur = conn.cursor()

        # Get user_id for test.member dynamically (created by test_auth.py)
        cur.execute("SELECT user_id FROM users WHERE email = 'test.member@gym.com'")
        row = cur.fetchone()
        test_member_id = row[0] if row else None

        # 1. Remove ahmed's test bookings on future schedules
        cur.execute("""
            DELETE FROM class_bookings
            WHERE user_id = 1 AND schedule_id IN (12, 16, 17, 18, 19)
        """)
        print(f"   Removed {cur.rowcount} test booking(s) for ahmed")

        # 2. Reset schedule 12 capacity back to 0
        cur.execute("UPDATE class_schedules SET current_capacity = 0 WHERE schedule_id = 12")

        # 3. Remove test.member's memberships and payments
        if test_member_id:
            cur.execute("DELETE FROM memberships WHERE user_id = %s", (test_member_id,))
            print(f"   Removed {cur.rowcount} test membership(s) for test.member")
            cur.execute("DELETE FROM payments WHERE user_id = %s AND payment_type = 'membership'", (test_member_id,))
            print(f"   Removed {cur.rowcount} test payment(s) for test.member")
            cur.execute("""
                UPDATE lockers SET status='available', current_user_id=NULL, assigned_at=NULL
                WHERE current_user_id = %s
            """, (test_member_id,))
        else:
            print("   test.member@gym.com not found — run test_auth.py first!")

        # 4. Remove ahmed's waitlist entries on schedule 19
        cur.execute("DELETE FROM class_bookings WHERE schedule_id = 19 AND user_id = 1")

        cur.close()
        conn.close()
        print(" Cleanup done — starting fresh!\n")

    except Exception as e:
        print(f"  Cleanup warning (tests will still run): {e}\n")

# ─────────────────────────────────────────────────────────────────────────────
print("\n SMART GYM — STEP 4 TRANSACTION TESTS")
print(" Make sure you ran test_auth.py first to create test.member@gym.com")
input("Make sure Flask is running (python run.py). Press Enter...\n")

cleanup()

# ── GET TOKENS ────────────────────────────────────────────────────────────────
header("SETUP: Getting tokens")

# Member 1 — ahmed.khan (seed user, password: gym123, HAS active membership)
r = requests.post(f"{BASE_URL}/api/v1/auth/login",
                  json={"email": "ahmed.khan@gmail.com", "password": "gym123"})
token1 = r.json().get('token')
if not token1:
    print(f" Login failed: {pretty(r)}")
    exit()
h1 = {"Authorization": f"Bearer {token1}"}
print(f" Member 1 (ahmed.khan) logged in")

# Member 2 — test.member (created by test_auth.py, password: SecurePass123, NO membership)
r = requests.post(f"{BASE_URL}/api/v1/auth/login",
                  json={"email": "test.member@gym.com", "password": "SecurePass123"})
token2 = r.json().get('token')
if not token2:
    print(f" Login failed for test.member — run test_auth.py first!")
    exit()
h2 = {"Authorization": f"Bearer {token2}"}
print(f" Member 2 (test.member) logged in")

# ═════════════════════════════════════════════════════════════════════════════
header("SCENARIO 1: MEMBERSHIP PURCHASE TRANSACTION")
print("Testing: Atomicity, Consistency, SELECT FOR UPDATE (locker), Durability\n")

test("T01 | Missing tier_id → 400",
     400,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"payment_method": "cash"}, headers=h1))

test("T02 | Invalid payment_method → 400",
     400,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"tier_id": 1, "payment_method": "bitcoin"}, headers=h1))

test("T03 | Invalid tier_id=999 → 404 (transaction rolled back)",
     404,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"tier_id": 999, "payment_method": "cash"}, headers=h1))

test("T04 | No token → 401",
     401,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"tier_id": 1, "payment_method": "cash"}))

test("T05 | Member 1 already has membership → 409",
     409,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"tier_id": 1, "payment_method": "cash"}, headers=h1))

print("\n T06 | Member 2 (test.member) purchases Basic membership...")
r = requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                  json={"tier_id": 1, "payment_method": "credit_card"}, headers=h2)
t06_ok = test("T06 | Purchase Basic membership → 201", 201, r)
if t06_ok:
    t = r.json()['transaction']
    print(f"    Payment ID  : {t['payment']['payment_id']}")
    print(f"    Membership  : {t['membership']['membership_id']} ({t['membership']['tier']})")
    print(f"    Valid until : {t['membership']['end_date']}")
    print(f"    Locker      : {t['locker']} (None for Basic — correct)")

test("T07 | Duplicate membership → 409",
     409,
     requests.post(f"{BASE_URL}/api/v1/payments/purchase-membership",
                   json={"tier_id": 2, "payment_method": "cash"}, headers=h2))

test("T08 | Payment history → 200",
     200,
     requests.get(f"{BASE_URL}/api/v1/payments/history", headers=h1))

# ═════════════════════════════════════════════════════════════════════════════
header("SCENARIO 2: CLASS BOOKING TRANSACTION")
print("Testing: SELECT FOR UPDATE, trigger integration, waitlist logic\n")

print(" Fetching class schedules...")
r = requests.get(f"{BASE_URL}/api/v1/classes/schedule")
schedules = r.json().get('schedules', [])
print(f"   Found {len(schedules)} upcoming schedules")

if not schedules:
    print(" No schedules found.")
    exit()

open_sched = [s for s in schedules if s.get('spots_available', 0) > 0]
full_sched  = [s for s in schedules if s.get('spots_available', 0) <= 0]
print(f"   Open: {len(open_sched)} | Full: {len(full_sched)}")
for s in schedules[:3]:
    print(f"   → ID:{s['schedule_id']} {s['class_name']} "
          f"{s['schedule_date']} ({s['spots_available']}/{s['max_capacity']} spots)")

test("T09 | Get classes list → 200",
     200, requests.get(f"{BASE_URL}/api/v1/classes/"))

test("T10 | Get schedule → 200",
     200, requests.get(f"{BASE_URL}/api/v1/classes/schedule"))

test("T11 | Book without token → 401",
     401,
     requests.post(f"{BASE_URL}/api/v1/classes/book",
                   json={"schedule_id": schedules[0]['schedule_id']}))

r_admin = requests.post(f"{BASE_URL}/api/v1/auth/login",
                        json={"email": "admin@smartgym.com", "password": "gym123"})
admin_token = r_admin.json().get('token')
if admin_token:
    test("T12 | Non-member role → 403",
         403,
         requests.post(f"{BASE_URL}/api/v1/classes/book",
                       json={"schedule_id": schedules[0]['schedule_id']},
                       headers={"Authorization": f"Bearer {admin_token}"}))

booking_id = None
if open_sched:
    s = open_sched[0]
    print(f"\n T13 | Booking: {s['class_name']} on {s['schedule_date']} ({s['spots_available']} spots)")
    r = requests.post(f"{BASE_URL}/api/v1/classes/book",
                      json={"schedule_id": s['schedule_id']}, headers=h1)
    t13_ok = test("T13 | Confirmed booking → 201", 201, r)
    if t13_ok:
        booking_id = r.json()['booking']['booking_id']
        print(f"   Booking ID : {booking_id}")
        print(f"   Status        : {r.json()['booking']['status']}")
        print(f"   Spots left    : {r.json()['booking'].get('spots_remaining')}")

if open_sched:
    test("T14 | Duplicate booking → 409",
         409,
         requests.post(f"{BASE_URL}/api/v1/classes/book",
                       json={"schedule_id": open_sched[0]['schedule_id']}, headers=h1))

if full_sched:
    s = full_sched[0]
    print(f"\n T15 | Full class: {s['class_name']} (0 spots)")
    r = requests.post(f"{BASE_URL}/api/v1/classes/book",
                      json={"schedule_id": s['schedule_id']}, headers=h1)
    t15_ok = test("T15 | Full class → waitlist → 201", 201, r)
    if t15_ok:
        print(f"   Waitlist position: {r.json()['booking'].get('position_in_waitlist')}")
else:
    print("\n  T15 | No full classes found")

test("T16 | Invalid schedule_id=99999 → 404",
     404,
     requests.post(f"{BASE_URL}/api/v1/classes/book",
                   json={"schedule_id": 99999}, headers=h1))

test("T17 | Missing schedule_id → 400",
     400,
     requests.post(f"{BASE_URL}/api/v1/classes/book",
                   json={}, headers=h1))

if booking_id:
    test("T18 | Cancel booking → 200",
         200,
         requests.delete(f"{BASE_URL}/api/v1/classes/cancel/{booking_id}", headers=h1))

if booking_id:
    test("T19 | Cancel already cancelled → 400",
         400,
         requests.delete(f"{BASE_URL}/api/v1/classes/cancel/{booking_id}", headers=h1))

header("EXPECTED RESULTS SUMMARY")
print("""
  SCENARIO 1 - Membership Purchase:
  T01: 400 — missing tier_id (validation)
  T02: 400 — invalid payment method (validation)
  T03: 404 — tier not found (transaction rolled back)
  T04: 401 — no token (auth)
  T05: 409 — already has membership (consistency)
  T06: 201 — membership purchased (ACID commit)
  T07: 409 — duplicate blocked (consistency)
  T08: 200 — payment history

  SCENARIO 2 - Class Booking:
  T09: 200 — public classes list
  T10: 200 — public schedule
  T11: 401 — no token
  T12: 403 — wrong role
  T13: 201 — confirmed booking (SELECT FOR UPDATE)
  T14: 409 — duplicate booking blocked
  T15: 201 — waitlist position (class full)
  T16: 404 — invalid schedule
  T17: 400 — missing schedule_id
  T18: 200 — cancellation (trigger promotes waitlist)
  T19: 400 — already cancelled
""")