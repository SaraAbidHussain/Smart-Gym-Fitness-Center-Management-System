#!/usr/bin/env python3
"""
test_trainers.py - Step 5 Trainer Endpoint Tests
Smart Gym Management System
Tests all trainer routes with RBAC enforcement
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
section("T1 — AUTHENTICATION & RBAC")
# ─────────────────────────────────────────────────────────────────────────────

# T1.1 — No token rejected
r = requests.get(f"{BASE_URL}/trainers/schedule")
if r.status_code == 401:
    ok("T1.1 No token → 401 Unauthorized")
else:
    fail("T1.1 No token should return 401", f"Got {r.status_code}")

# T1.2 — Member cannot access trainer routes
member_token = login("ahmed.khan@gmail.com", "gym123")
if member_token:
    r = requests.get(f"{BASE_URL}/trainers/schedule",
                     headers={"Authorization": f"Bearer {member_token}"})
    if r.status_code == 403:
        ok("T1.2 Member role → 403 Forbidden on trainer route")
    else:
        fail("T1.2 Member should get 403 on trainer route", f"Got {r.status_code}")

# T1.3 — Trainer login succeeds
trainer_token = login("coach.ali@smartgym.com", "gym123")
if trainer_token:
    ok("T1.3 Trainer login successful")
else:
    fail("T1.3 Trainer login failed")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────────────────────
section("T2 — GET /trainers/clients")
# ─────────────────────────────────────────────────────────────────────────────
headers = {"Authorization": f"Bearer {trainer_token}"}

r = requests.get(f"{BASE_URL}/trainers/clients", headers=headers)
if r.status_code == 200:
    ok("T2.1 GET /trainers/clients → 200")
    d = r.json()
    if d.get("success") and "clients" in d:
        ok(f"T2.2 Response has clients list (count={d['count']})")
    else:
        fail("T2.2 Response missing clients list", str(d))

    if d.get("count", 0) > 0:
        client = d["clients"][0]
        fields = ["user_id", "full_name", "email", "workout_plans", "nutrition_plans"]
        missing = [f for f in fields if f not in client]
        if not missing:
            ok("T2.3 Client object has all required fields")
        else:
            fail("T2.3 Client object missing fields", str(missing))
    else:
        print(f"  {YELLOW}⚠️  T2.3 Skipped — no clients found for this trainer{RESET}")
else:
    fail("T2.1 GET /trainers/clients failed", f"Status {r.status_code}: {r.text}")

# ─────────────────────────────────────────────────────────────────────────────
section("T3 — GET /trainers/performance")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/trainers/performance", headers=headers)
if r.status_code == 200:
    ok("T3.1 GET /trainers/performance → 200")
    d = r.json()
    perf = d.get("performance", {})
    fields = ["trainer_id", "trainer_name", "total_clients",
              "workout_plans_created", "classes_scheduled", "average_rating"]
    missing = [f for f in fields if f not in perf]
    if not missing:
        ok("T3.2 Performance object has all required fields")
    else:
        fail("T3.2 Performance missing fields", str(missing))

    if perf.get("trainer_name"):
        ok(f"T3.3 Trainer name: {perf['trainer_name']} | Rating: {perf.get('average_rating')}")
    else:
        fail("T3.3 Trainer name missing")
else:
    fail("T3.1 GET /trainers/performance failed", f"Status {r.status_code}: {r.text}")

# Different trainer gets different data
trainer2_token = login("coach.sara@smartgym.com", "gym123")
if trainer2_token:
    r2 = requests.get(f"{BASE_URL}/trainers/performance",
                      headers={"Authorization": f"Bearer {trainer2_token}"})
    if r2.status_code == 200:
        d2 = r2.json()
        if d2["performance"]["trainer_id"] != d.get("performance", {}).get("trainer_id"):
            ok("T3.4 Different trainers get different performance data")
        else:
            fail("T3.4 Different trainers returning same trainer_id")
    else:
        print(f"  {YELLOW}⚠️  T3.4 Skipped — coach.sara login issue{RESET}")

# ─────────────────────────────────────────────────────────────────────────────
section("T4 — GET /trainers/schedule")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/trainers/schedule", headers=headers)
if r.status_code == 200:
    ok("T4.1 GET /trainers/schedule → 200")
    d = r.json()
    if "schedules" in d:
        ok(f"T4.2 Schedule list returned (count={d['count']})")
    else:
        fail("T4.2 Missing schedules in response")

    if d.get("count", 0) > 0:
        s = d["schedules"][0]
        fields = ["schedule_id", "class_name", "schedule_date",
                  "start_time", "spots_available", "status"]
        missing = [f for f in fields if f not in s]
        if not missing:
            ok("T4.3 Schedule object has all required fields")
        else:
            fail("T4.3 Schedule missing fields", str(missing))

        # All schedules should be today or future
        from datetime import date
        future = all(s["schedule_date"] >= str(date.today()) for s in d["schedules"])
        if future:
            ok("T4.4 All schedules are today or future dates")
        else:
            fail("T4.4 Some schedules are in the past")
    else:
        print(f"  {YELLOW}⚠️  T4.3/T4.4 Skipped — no upcoming schedules{RESET}")
else:
    fail("T4.1 GET /trainers/schedule failed", f"Status {r.status_code}: {r.text}")

# ─────────────────────────────────────────────────────────────────────────────
section("T5 — GET /trainers/workout-plans")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/trainers/workout-plans", headers=headers)
if r.status_code == 200:
    ok("T5.1 GET /trainers/workout-plans → 200")
    d = r.json()
    if "plans" in d:
        ok(f"T5.2 Workout plans returned (count={d['count']})")
    else:
        fail("T5.2 Missing plans in response")
else:
    fail("T5.1 GET /trainers/workout-plans failed", f"Status {r.status_code}: {r.text}")

# ─────────────────────────────────────────────────────────────────────────────
section("T6 — POST /trainers/workout-plans")
# ─────────────────────────────────────────────────────────────────────────────

# Get a valid member_id from clients
r = requests.get(f"{BASE_URL}/trainers/clients", headers=headers)
clients = r.json().get("clients", [])

if clients:
    test_member_id = clients[0]["user_id"]

    # T6.1 — Create workout plan
    payload = {
        "user_id":       test_member_id,
        "plan_name":     "Test Strength Plan",
        "goal":          "Build muscle mass",
        "duration_weeks": 8
    }
    r = requests.post(f"{BASE_URL}/trainers/workout-plans",
                      headers={**headers, "Content-Type": "application/json"},
                      json=payload)
    if r.status_code == 201:
        ok(f"T6.1 POST workout plan created → 201")
        d = r.json()
        if d.get("plan", {}).get("plan_id"):
            ok(f"T6.2 Plan returned with plan_id={d['plan']['plan_id']}")
        else:
            fail("T6.2 Missing plan_id in response")
    else:
        fail("T6.1 POST workout plan failed", f"Status {r.status_code}: {r.text}")

    # T6.2 — Missing required field
    r = requests.post(f"{BASE_URL}/trainers/workout-plans",
                      headers={**headers, "Content-Type": "application/json"},
                      json={"user_id": test_member_id, "plan_name": "No goal plan"})
    if r.status_code == 400:
        ok("T6.3 Missing goal → 400 Bad Request")
    else:
        fail("T6.3 Missing required field should return 400", f"Got {r.status_code}")

    # T6.3 — Invalid member
    r = requests.post(f"{BASE_URL}/trainers/workout-plans",
                      headers={**headers, "Content-Type": "application/json"},
                      json={"user_id": 99999, "plan_name": "Test", "goal": "Test"})
    if r.status_code == 404:
        ok("T6.4 Invalid member_id → 404 Not Found")
    else:
        fail("T6.4 Invalid member should return 404", f"Got {r.status_code}")
else:
    print(f"  {YELLOW}⚠️  T6 Skipped — no clients found for trainer{RESET}")

# ─────────────────────────────────────────────────────────────────────────────
section("T7 — GET/POST /trainers/nutrition-plans")
# ─────────────────────────────────────────────────────────────────────────────

r = requests.get(f"{BASE_URL}/trainers/nutrition-plans", headers=headers)
if r.status_code == 200:
    ok("T7.1 GET /trainers/nutrition-plans → 200")
else:
    fail("T7.1 GET /trainers/nutrition-plans failed", f"Status {r.status_code}: {r.text}")

if clients:
    payload = {
        "user_id":        test_member_id,
        "plan_name":      "Test Nutrition Plan",
        "daily_calories": 2500,
        "protein_grams":  180,
        "carbs_grams":    250,
        "fat_grams":      70
    }
    r = requests.post(f"{BASE_URL}/trainers/nutrition-plans",
                      headers={**headers, "Content-Type": "application/json"},
                      json=payload)
    if r.status_code == 201:
        ok("T7.2 POST nutrition plan created → 201")
        d = r.json()
        if d.get("plan", {}).get("nutrition_plan_id"):
            ok(f"T7.3 Plan returned with nutrition_plan_id={d['plan']['nutrition_plan_id']}")
        else:
            fail("T7.3 Missing nutrition_plan_id in response")
    else:
        fail("T7.2 POST nutrition plan failed", f"Status {r.status_code}: {r.text}")

    # Missing daily_calories
    r = requests.post(f"{BASE_URL}/trainers/nutrition-plans",
                      headers={**headers, "Content-Type": "application/json"},
                      json={"user_id": test_member_id, "plan_name": "Bad Plan"})
    if r.status_code == 400:
        ok("T7.4 Missing daily_calories → 400 Bad Request")
    else:
        fail("T7.4 Missing required field should return 400", f"Got {r.status_code}")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
total = passed + failed
print(f"\n{BLUE}{'='*55}{RESET}")
print(f"  TRAINER TEST RESULTS: {passed}/{total} passed")
if failed == 0:
    print(f"  {GREEN}🎉 ALL TRAINER TESTS PASSED!{RESET}")
else:
    print(f"  {RED}⚠️  {failed} test(s) failed{RESET}")
print(f"{BLUE}{'='*55}{RESET}\n")