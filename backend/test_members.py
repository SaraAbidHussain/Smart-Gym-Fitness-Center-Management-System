"""
Member Endpoints Testing Script
Tests all member API endpoints with authentication
"""

import requests
import json

BASE_URL = "http://localhost:5000/api/v1"

def print_response(title, response):
    """Pretty print API response"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    print(f"Response:")
    print(json.dumps(response.json(), indent=2))


def get_member_token():
    """Login and get member token"""
    # Use existing test member from seed data
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "ahmed.khan@gmail.com",  # From seed.sql
        "password": "$2b$12$/YucUdbGVq3pDbAUN91VuOHL/NAJrtGUtKd5SuAc4sPkBEhiLNCjy"
    })
    
    # If doesn't work, try with test user
    if response.status_code != 200:
        response = requests.post(f"{BASE_URL}/auth/login", json={
            "email": "test.member@gym.com",
            "password": "SecurePass123"
        })
    
    if response.status_code == 200:
        return response.json()['token']
    else:
        print("❌ Could not login. Please ensure test user exists.")
        print("Run: python test_auth.py first to create test users")
        return None


def test_dashboard(token):
    """Test GET /members/dashboard"""
    print("\n\n🧪 TEST 1: Get Member Dashboard")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/members/dashboard", headers=headers)
    print_response("Member Dashboard", response)


def test_membership(token):
    """Test GET /members/membership"""
    print("\n\n🧪 TEST 2: Get Active Membership")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/members/membership", headers=headers)
    print_response("Active Membership", response)


def test_get_bookings(token):
    """Test GET /members/bookings"""
    print("\n\n🧪 TEST 3: Get Class Bookings")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Get all bookings
    print("\n--- All Bookings ---")
    response = requests.get(f"{BASE_URL}/members/bookings", headers=headers)
    print_response("All Bookings", response)
    
    # Get only upcoming
    print("\n--- Upcoming Bookings ---")
    response = requests.get(
        f"{BASE_URL}/members/bookings?upcoming=true",
        headers=headers
    )
    print_response("Upcoming Bookings", response)
    
    # Get confirmed only
    print("\n--- Confirmed Bookings ---")
    response = requests.get(
        f"{BASE_URL}/members/bookings?status=confirmed",
        headers=headers
    )
    print_response("Confirmed Bookings", response)


def test_book_class(token):
    """Test POST /members/book-class"""
    print("\n\n🧪 TEST 4: Book a Class")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Try to book schedule_id 7 (from seed data)
    response = requests.post(
        f"{BASE_URL}/members/book-class",
        headers=headers,
        json={"schedule_id": 7}
    )
    print_response("Book Class (schedule_id: 7)", response)
    
    # Try to book same class again (should fail)
    print("\n--- Try Duplicate Booking ---")
    response = requests.post(
        f"{BASE_URL}/members/book-class",
        headers=headers,
        json={"schedule_id": 7}
    )
    print_response("Duplicate Booking (Should Fail)", response)


def test_cancel_booking(token):
    """Test DELETE /members/bookings/:id"""
    print("\n\n🧪 TEST 5: Cancel a Booking")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # First get bookings to find a booking_id
    response = requests.get(f"{BASE_URL}/members/bookings", headers=headers)
    
    if response.status_code == 200:
        bookings = response.json().get('bookings', [])
        
        if bookings:
            booking_id = bookings[0]['booking_id']
            
            # Cancel the booking
            response = requests.delete(
                f"{BASE_URL}/members/bookings/{booking_id}",
                headers=headers
            )
            print_response(f"Cancel Booking (ID: {booking_id})", response)
        else:
            print("No bookings found to cancel. Book a class first.")
    else:
        print("Could not fetch bookings")


def test_get_workouts(token):
    """Test GET /members/workouts"""
    print("\n\n🧪 TEST 6: Get Workout Logs")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    # Get all workouts
    print("\n--- All Workouts ---")
    response = requests.get(f"{BASE_URL}/members/workouts", headers=headers)
    print_response("All Workouts", response)
    
    # Get with date filter
    print("\n--- Workouts (Last 7 days) ---")
    response = requests.get(
        f"{BASE_URL}/members/workouts?start_date=2026-02-15&limit=10",
        headers=headers
    )
    print_response("Recent Workouts", response)


def test_log_workout(token):
    """Test POST /members/workouts"""
    print("\n\n🧪 TEST 7: Log a Workout")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    workout_data = {
        "workout_date": "2026-02-21",
        "exercise_name": "Squats",
        "muscle_group": "Legs",
        "sets": 4,
        "reps": 10,
        "weight_kg": 80.0,
        "calories_burned": 250,
        "difficulty": "hard",
        "notes": "Testing from API - Great session!"
    }
    
    response = requests.post(
        f"{BASE_URL}/members/workouts",
        headers=headers,
        json=workout_data
    )
    print_response("Log Workout", response)
    
    # Try with minimal data
    print("\n--- Minimal Workout Log ---")
    response = requests.post(
        f"{BASE_URL}/members/workouts",
        headers=headers,
        json={"exercise_name": "Running"}
    )
    print_response("Minimal Workout Log", response)


def test_get_profile(token):
    """Test GET /members/profile"""
    print("\n\n🧪 TEST 8: Get Profile")
    
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/members/profile", headers=headers)
    print_response("Get Profile", response)


def test_update_profile(token):
    """Test PUT /members/profile"""
    print("\n\n🧪 TEST 9: Update Profile")
    
    headers = {"Authorization": f"Bearer {token}"}
    
    update_data = {
        "first_name": "Ahmed",
        "last_name": "Khan",
        "phone": "0300-9999999"
    }
    
    response = requests.put(
        f"{BASE_URL}/members/profile",
        headers=headers,
        json=update_data
    )
    print_response("Update Profile", response)
    
    # Try invalid field (should fail)
    print("\n--- Try Update Invalid Field ---")
    response = requests.put(
        f"{BASE_URL}/members/profile",
        headers=headers,
        json={"role": "admin"}  # Cannot change role
    )
    print_response("Invalid Field Update (Should Be Ignored)", response)


def test_unauthorized_access():
    """Test accessing endpoints without token"""
    print("\n\n🧪 TEST 10: Unauthorized Access")
    
    print("\n--- No Token ---")
    response = requests.get(f"{BASE_URL}/members/dashboard")
    print_response("Access Without Token (Should Fail)", response)
    
    print("\n--- Invalid Token ---")
    headers = {"Authorization": "Bearer invalid-token-12345"}
    response = requests.get(f"{BASE_URL}/members/dashboard", headers=headers)
    print_response("Access With Invalid Token (Should Fail)", response)


def test_wrong_role_access():
    """Test member endpoints with trainer token"""
    print("\n\n🧪 TEST 11: Wrong Role Access")
    
    # Login as trainer
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "test.trainer@gym.com",
        "password": "SecurePass123"
    })
    
    if response.status_code == 200:
        trainer_token = response.json()['token']
        headers = {"Authorization": f"Bearer {trainer_token}"}
        
        # Try to access member endpoint
        response = requests.get(f"{BASE_URL}/members/dashboard", headers=headers)
        print_response("Trainer Accessing Member Endpoint (Should Fail)", response)
    else:
        print("Could not login as trainer")


def main():
    """Run all member endpoint tests"""
    print("="*60)
    print("SMART GYM API - MEMBER ENDPOINTS TESTS")
    print("="*60)
    print("\nMake sure:")
    print("1. Flask server is running (python run.py)")
    print("2. Test users exist (run test_auth.py first)")
    print("3. Database has seed data")
    
    input("\nPress Enter to start tests...")
    
    # Get member token
    print("\n🔐 Getting member authentication token...")
    token = get_member_token()
    
    if not token:
        print("\n❌ Could not get token. Stopping tests.")
        return
    
    print(f"✅ Token obtained: {token[:50]}...")
    
    # Run tests
    test_dashboard(token)
    test_membership(token)
    test_get_bookings(token)
    test_book_class(token)
    test_cancel_booking(token)
    test_get_workouts(token)
    test_log_workout(token)
    test_get_profile(token)
    test_update_profile(token)
    test_unauthorized_access()
    test_wrong_role_access()
    
    print("\n\n" + "="*60)
    print("✅ ALL MEMBER ENDPOINT TESTS COMPLETED")
    print("="*60)
    print("\nReview the results above.")
    print("Expected: Most tests should return 200/201")
    print("Expected failures: unauthorized access, wrong role")


if __name__ == "__main__":
    main()