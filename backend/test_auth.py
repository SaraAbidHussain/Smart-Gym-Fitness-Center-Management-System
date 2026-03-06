"""
Authentication Testing Script
Tests register, login, and token validation
"""

import requests
import json

# API base URL
BASE_URL = "http://localhost:5000/api/v1"

def print_response(title, response):
    """Pretty print API response"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    print(f"Response:")
    print(json.dumps(response.json(), indent=2))


def test_register():
    """Test user registration"""
    print("\n\n🧪 TEST 1: User Registration")
    
    # Test data for different roles
    users = [
        {
            "email": "test.member@gym.com",
            "password": "SecurePass123",
            "first_name": "Test",
            "last_name": "Member",
            "phone": "0300-9999999",
            "role": "member",
            "date_of_birth": "1995-05-15",
            "gender": "male"
        },
        {
            "email": "test.trainer@gym.com",
            "password": "SecurePass123",
            "first_name": "Test",
            "last_name": "Trainer",
            "phone": "0301-9999999",
            "role": "trainer",
            "date_of_birth": "1988-08-20",
            "gender": "female"
        },
        {
            "email": "test.staff@gym.com",
            "password": "SecurePass123",
            "first_name": "Test",
            "last_name": "Staff",
            "phone": "0302-9999999",
            "role": "staff",
            "gender": "male"
        },
        {
            "email": "test.admin@gym.com",
            "password": "SecurePass123",
            "first_name": "Test",
            "last_name": "Admin",
            "role": "admin"
        }
    ]
    
    for user in users:
        response = requests.post(f"{BASE_URL}/auth/register", json=user)
        print_response(f"Register {user['role'].upper()}", response)


def test_register_duplicate():
    """Test registering with duplicate email"""
    print("\n\n🧪 TEST 2: Duplicate Email (Should Fail)")
    
    user_data = {
        "email": "test.member@gym.com",  # Already registered
        "password": "SecurePass123",
        "first_name": "Duplicate",
        "last_name": "User",
        "role": "member"
    }
    
    response = requests.post(f"{BASE_URL}/auth/register", json=user_data)
    print_response("Duplicate Registration", response)


def test_register_invalid():
    """Test registration with invalid data"""
    print("\n\n🧪 TEST 3: Invalid Registration Data")
    
    # Missing required field
    print("\n--- Missing Password ---")
    response = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "invalid@gym.com",
        "first_name": "Invalid",
        "last_name": "User",
        "role": "member"
    })
    print_response("Missing Password", response)
    
    # Invalid role
    print("\n--- Invalid Role ---")
    response = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "invalid2@gym.com",
        "password": "SecurePass123",
        "first_name": "Invalid",
        "last_name": "User",
        "role": "superuser"  # Invalid role
    })
    print_response("Invalid Role", response)
    
    # Weak password
    print("\n--- Weak Password ---")
    response = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "invalid3@gym.com",
        "password": "123",  # Too short
        "first_name": "Invalid",
        "last_name": "User",
        "role": "member"
    })
    print_response("Weak Password", response)


def test_login():
    """Test user login"""
    print("\n\n🧪 TEST 4: User Login (All Roles)")
    
    credentials = [
        {"email": "test.member@gym.com", "password": "SecurePass123"},
        {"email": "test.trainer@gym.com", "password": "SecurePass123"},
        {"email": "test.staff@gym.com", "password": "SecurePass123"},
        {"email": "test.admin@gym.com", "password": "SecurePass123"}
    ]
    
    tokens = {}
    
    for cred in credentials:
        response = requests.post(f"{BASE_URL}/auth/login", json=cred)
        print_response(f"Login: {cred['email']}", response)
        
        if response.status_code == 200:
            role = response.json()['user']['role']
            tokens[role] = response.json()['token']
    
    return tokens


def test_login_invalid():
    """Test login with invalid credentials"""
    print("\n\n🧪 TEST 5: Invalid Login Credentials")
    
    # Wrong password
    print("\n--- Wrong Password ---")
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "test.member@gym.com",
        "password": "WrongPassword"
    })
    print_response("Wrong Password", response)
    
    # Non-existent email
    print("\n--- Non-existent Email ---")
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "nonexistent@gym.com",
        "password": "SecurePass123"
    })
    print_response("Non-existent Email", response)
    
    # Missing fields
    print("\n--- Missing Password ---")
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "test.member@gym.com"
    })
    print_response("Missing Password", response)


def test_protected_route(tokens):
    """Test accessing protected route with token"""
    print("\n\n🧪 TEST 6: Protected Route Access")
    
    # This will be implemented after we create the /me endpoint
    # For now, we'll just show how to send the token
    
    for role, token in tokens.items():
        headers = {
            "Authorization": f"Bearer {token}"
        }
        
        print(f"\n--- {role.upper()} Token ---")
        print(f"Token: {token[:50]}...")
        print(f"Headers: {headers}")
        
        # Once /me endpoint is protected, you can test it like this:
        # response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
        # print_response(f"Access with {role} token", response)


def test_invalid_token():
    """Test with invalid token"""
    print("\n\n🧪 TEST 7: Invalid Token")
    
    # This will be tested once we have a protected endpoint
    # For now, showing the concept
    
    print("\n--- Missing Token ---")
    print("Request without Authorization header should return 401")
    
    print("\n--- Invalid Token Format ---")
    print("Token without 'Bearer ' prefix should return 401")
    
    print("\n--- Expired Token ---")
    print("Expired token should return 401 with 'Token expired' message")


def main():
    """Run all tests"""
    print("="*60)
    print("SMART GYM API - AUTHENTICATION TESTS")
    print("="*60)
    print("\nMake sure the Flask server is running on http://localhost:5000")
    input("\nPress Enter to start tests...")
    
    # Run tests
    test_register()
    test_register_duplicate()
    test_register_invalid()
    tokens = test_login()
    test_login_invalid()
    test_protected_route(tokens)
    test_invalid_token()
    
    print("\n\n" + "="*60)
    print("✅ ALL TESTS COMPLETED")
    print("="*60)
    print("\nNext steps:")
    print("1. Review the test results above")
    print("2. Test the /me endpoint once it's protected with @token_required")
    print("3. Use the tokens above to test other protected endpoints")


if __name__ == "__main__":
    main()