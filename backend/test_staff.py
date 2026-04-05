#!/usr/bin/env python3
"""
test_staff.py - Step 5 Staff Endpoint Tests
Smart Gym Management System
Tests all staff routes with RBAC enforcement
"""

import requests
import json
import sys

BASE_URL = "http://localhost:5000/api/v1"

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
BLUE   = "\033[94m"
RESET  = "\033[0m"

passed = 0
failed = 0

def ok(msg):
    global passed
    passed += 1
    print(f"  {GREEN}✅ PASS{RESET} {msg}")

def fail(msg, detail=""):
    global failed
    failed += 1
    print(f"  {RED}❌ FAIL{RESET} {msg}")
    if detail:
        print(f"         {RED}{detail}{RESET}")

def section(title):
    print(f"\n{BLUE}{'='*55}{RESET}")
    print(f"{BLUE}  {title}{RESET}")
    print(f"{BLUE}{'='*55}{RESET}")

def login(email, password):
    r = requests.post(f"{BASE_URL}/auth/login",
                      json={"email": email, "password": password})
    d = r.json()
    if d.get("success"):
        return d["token"]
    print(f"  {RED}Login failed for {email}: {d}{RESET}")
    return None

# ─────────────────────────────────────────────────────────────────────────────
section("S1 — AUTHENTICATION & RBAC")
# ─────────────────────────────────────────────────────────────────────────────

# S1.1 — No token rejected
r = requests.get(f"{BASE_URL}/staff/equipment")
if r.status_code == 401:
    ok("S1.1 No token → 401 Unauthorized")
else:
    fail("S1.1 No token should return 401", f"Got {r.status_code}")

# S1.2 — Member cannot access staff routes
member_token = login("ahmed.khan@gmail.com", "gym123")
if member_token:
    r = requests.get(f"{BASE_URL}/staff/equipment",
                     headers={"Authorization": f"Bearer {member_token}"})
    if r.status_code == 403:
        ok("S1.2 Member role → 403 Forbidden on staff route")
    else:
        fail("S1.2 Member should get 403 on staff route", f"Got {r.status_code}")

# S1.3 — Trainer cannot access staff routes
trainer_token = login("coach.ali@smartgym.com", "gym123")
if trainer_token:
    r = requests.get(f"{BASE_URL}/staff/equipment",
                     headers={"Authorization": f"Bearer {trainer_token}"})
    if r.status_code == 403:
        ok("S1.3 Trainer role → 403 Forbidden on staff route")
    else:
        fail("S1.3 Trainer should get 403 on staff route", f"Got {r.status_code}")

# S1.4 — Staff login succeeds
staff_token = login("staff.hassan@smartgym.com", "gym123")
if staff_token:
    ok("S1.4 Staff login successful")
else:
    fail("S1.4 Staff login failed")
    sys.exit(1)

headers = {"Authorization": f"Bearer {staff_token}"}

# ─────────────────────────────────────────────────────────────────────────────
section("S2 — GET /staff/equipment")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/staff/equipment", headers=headers)
if r.status_code == 200:
    ok("S2.1 GET /staff/equipment → 200")
    d = r.json()

    if "summary" in d and "equipment" in d:
        ok("S2.2 Response has summary and equipment list")
    else:
        fail("S2.2 Missing summary or equipment list")

    summary = d.get("summary", {})
    if "total" in summary and "available" in summary:
        ok(f"S2.3 Summary: total={summary['total']}, operational={summary['available']}")
    else:
        fail("S2.3 Summary missing fields", str(summary))

    if d.get("equipment"):
        eq = d["equipment"][0]
        fields = ["equipment_id", "equipment_name", "equipment_type", "zone", "status"]
        missing = [f for f in fields if f not in eq]
        if not missing:
            ok("S2.4 Equipment object has all required fields")
        else:
            fail("S2.4 Equipment missing fields", str(missing))
else:
    fail("S2.1 GET /staff/equipment failed", f"Status {r.status_code}: {r.text}")

# ─────────────────────────────────────────────────────────────────────────────
section("S3 — PUT /staff/equipment/<id>")
# ─────────────────────────────────────────────────────────────────────────────

# Get first equipment id
r = requests.get(f"{BASE_URL}/staff/equipment", headers=headers)
equipment_list = r.json().get("equipment", [])

if equipment_list:
    eq_id = equipment_list[0]["equipment_id"]
    eq_name = equipment_list[0]["equipment_name"]

    # S3.1 — Valid status update
    r = requests.put(f"{BASE_URL}/staff/equipment/{eq_id}",
                     headers={**headers, "Content-Type": "application/json"},
                     json={"status": "maintenance"})
    if r.status_code == 200:
        ok(f"S3.1 PUT equipment status → under_repair (id={eq_id})")
    else:
        fail("S3.1 PUT equipment update failed", f"Status {r.status_code}: {r.text}")

    # Restore to operational
    requests.put(f"{BASE_URL}/staff/equipment/{eq_id}",
                 headers={**headers, "Content-Type": "application/json"},
                 json={"status": "available"})

    # S3.2 — Invalid status
    r = requests.put(f"{BASE_URL}/staff/equipment/{eq_id}",
                     headers={**headers, "Content-Type": "application/json"},
                     json={"status": "flying"})
    if r.status_code == 400:
        ok("S3.2 Invalid status → 400 Bad Request")
    else:
        fail("S3.2 Invalid status should return 400", f"Got {r.status_code}")

    # S3.3 — Non-existent equipment
    r = requests.put(f"{BASE_URL}/staff/equipment/99999",
                     headers={**headers, "Content-Type": "application/json"},
                     json={"status": "available"})
    if r.status_code == 404:
        ok("S3.3 Non-existent equipment → 404 Not Found")
    else:
        fail("S3.3 Non-existent equipment should return 404", f"Got {r.status_code}")

    # S3.4 — No fields to update
    r = requests.put(f"{BASE_URL}/staff/equipment/{eq_id}",
                     headers={**headers, "Content-Type": "application/json"},
                     json={"unknown_field": "value"})
    if r.status_code == 400:
        ok("S3.4 No valid fields → 400 Bad Request")
    else:
        fail("S3.4 No valid fields should return 400", f"Got {r.status_code}")
else:
    print(f"  {YELLOW}⚠️  S3 Skipped — no equipment found{RESET}")

# ─────────────────────────────────────────────────────────────────────────────
section("S4 — POST /staff/checkin")
# ─────────────────────────────────────────────────────────────────────────────

# Use member user_id=2 (sara.malik) — unlikely to be already checked in
TEST_MEMBER_ID = 2

# S4.1 — Successful check-in
r = requests.post(f"{BASE_URL}/staff/checkin",
                  headers={**headers, "Content-Type": "application/json"},
                  json={"member_id": TEST_MEMBER_ID})

if r.status_code in [201, 409]:
    if r.status_code == 201:
        ok(f"S4.1 POST /staff/checkin → 201 Created")
        d = r.json()
        if d.get("attendance_id") and d.get("member"):
            ok(f"S4.2 Check-in response has attendance_id and member name")
        else:
            fail("S4.2 Missing attendance_id or member in response")
        if d.get("membership_tier"):
            ok(f"S4.3 Membership tier shown: {d['membership_tier']}")
        else:
            fail("S4.3 Missing membership_tier in response")
    else:
        print(f"  {YELLOW}⚠️  S4.1 Member already checked in (409) — skipping checkin tests{RESET}")
else:
    fail("S4.1 POST /staff/checkin failed", f"Status {r.status_code}: {r.text}")

# S4.4 — Double check-in prevention
r2 = requests.post(f"{BASE_URL}/staff/checkin",
                   headers={**headers, "Content-Type": "application/json"},
                   json={"member_id": TEST_MEMBER_ID})
if r2.status_code == 409:
    ok("S4.4 Double check-in prevented → 409 Conflict")
else:
    fail("S4.4 Double check-in should return 409", f"Got {r2.status_code}")

# S4.5 — Invalid member
r = requests.post(f"{BASE_URL}/staff/checkin",
                  headers={**headers, "Content-Type": "application/json"},
                  json={"member_id": 99999})
if r.status_code == 404:
    ok("S4.5 Invalid member_id → 404 Not Found")
else:
    fail("S4.5 Invalid member should return 404", f"Got {r.status_code}")

# S4.6 — Missing member_id
r = requests.post(f"{BASE_URL}/staff/checkin",
                  headers={**headers, "Content-Type": "application/json"},
                  json={})
if r.status_code == 400:
    ok("S4.6 Missing member_id → 400 Bad Request")
else:
    fail("S4.6 Missing member_id should return 400", f"Got {r.status_code}")

# ─────────────────────────────────────────────────────────────────────────────
section("S5 — GET /staff/attendance/today")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/staff/attendance/today", headers=headers)
if r.status_code == 200:
    ok("S5.1 GET /staff/attendance/today → 200")
    d = r.json()

    if "date" in d and "total_visits" in d and "currently_in" in d:
        ok(f"S5.2 Response has date, total_visits, currently_in")
    else:
        fail("S5.2 Missing required fields in attendance response")

    if d.get("currently_in", 0) > 0:
        ok(f"S5.3 Currently in gym: {d['currently_in']} member(s)")
    else:
        print(f"  {YELLOW}⚠️  S5.3 No members currently checked in{RESET}")

    if "attendance" in d:
        ok(f"S5.4 Attendance list returned (total={d['total_visits']})")
        if d["attendance"]:
            record = d["attendance"][0]
            if "member_name" in record and "check_in_time" in record:
                ok("S5.5 Attendance record has member_name and check_in_time")
            else:
                fail("S5.5 Attendance record missing fields", str(record.keys()))
    else:
        fail("S5.4 Missing attendance list in response")
else:
    fail("S5.1 GET /staff/attendance/today failed", f"Status {r.status_code}: {r.text}")

# ─────────────────────────────────────────────────────────────────────────────
section("S6 — POST /staff/checkout")
# ─────────────────────────────────────────────────────────────────────────────

# S6.1 — Successful checkout (member we checked in at S4)
r = requests.post(f"{BASE_URL}/staff/checkout",
                  headers={**headers, "Content-Type": "application/json"},
                  json={"member_id": TEST_MEMBER_ID})
if r.status_code == 200:
    ok("S6.1 POST /staff/checkout → 200")
    d = r.json()
    if d.get("duration_minutes") is not None:
        ok(f"S6.2 Duration calculated: {d['duration_minutes']} minutes")
    else:
        fail("S6.2 Missing duration_minutes in checkout response")
    if d.get("check_out_time"):
        ok("S6.3 Check-out time recorded")
    else:
        fail("S6.3 Missing check_out_time in response")
else:
    fail("S6.1 POST /staff/checkout failed", f"Status {r.status_code}: {r.text}")

# S6.2 — Double checkout (no active check-in)
r = requests.post(f"{BASE_URL}/staff/checkout",
                  headers={**headers, "Content-Type": "application/json"},
                  json={"member_id": TEST_MEMBER_ID})
if r.status_code == 404:
    ok("S6.4 Double checkout → 404 No active check-in")
else:
    fail("S6.4 Double checkout should return 404", f"Got {r.status_code}")

# S6.3 — Invalid member
r = requests.post(f"{BASE_URL}/staff/checkout",
                  headers={**headers, "Content-Type": "application/json"},
                  json={"member_id": 99999})
if r.status_code == 404:
    ok("S6.5 Invalid member checkout → 404")
else:
    fail("S6.5 Invalid member checkout should return 404", f"Got {r.status_code}")

# ─────────────────────────────────────────────────────────────────────────────
section("S7 — PUT /staff/lockers/<id>")
# ─────────────────────────────────────────────────────────────────────────────

# S7.1 — Invalid locker
r = requests.put(f"{BASE_URL}/staff/lockers/99999",
                 headers={**headers, "Content-Type": "application/json"},
                 json={"action": "release"})
if r.status_code == 404:
    ok("S7.1 Non-existent locker → 404 Not Found")
else:
    fail("S7.1 Non-existent locker should return 404", f"Got {r.status_code}")

# S7.2 — Invalid action
r = requests.put(f"{BASE_URL}/staff/lockers/1",
                 headers={**headers, "Content-Type": "application/json"},
                 json={"action": "steal"})
if r.status_code == 400:
    ok("S7.2 Invalid locker action → 400 Bad Request")
else:
    fail("S7.2 Invalid action should return 400", f"Got {r.status_code}")

# S7.3 — Assign without member_id
r = requests.put(f"{BASE_URL}/staff/lockers/1",
                 headers={**headers, "Content-Type": "application/json"},
                 json={"action": "assign"})
if r.status_code == 400:
    ok("S7.3 Assign without member_id → 400 Bad Request")
else:
    fail("S7.3 Assign without member_id should return 400", f"Got {r.status_code}")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
total = passed + failed
print(f"\n{BLUE}{'='*55}{RESET}")
print(f"  STAFF TEST RESULTS: {passed}/{total} passed")
if failed == 0:
    print(f"  {GREEN}🎉 ALL STAFF TESTS PASSED!{RESET}")
else:
    print(f"  {RED}⚠️  {failed} test(s) failed{RESET}")
print(f"{BLUE}{'='*55}{RESET}\n")