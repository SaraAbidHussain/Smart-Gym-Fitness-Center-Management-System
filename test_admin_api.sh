#!/bin/bash

BASE_URL="http://localhost:5000/api/v1"
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyNSwiZW1haWwiOiJhZG1pbkBneW0uY29tIiwicm9sZSI6ImFkbWluIiwiZXhwIjoxNzczMDE0NDM0LCJpYXQiOjE3NzI5MjgwMzR9.nDL553N52zcqFntNPohNKYOwQHG7S-cxv9-joqzZe8A"

echo "---- Get all users ----"
curl "$BASE_URL/admin/users?page=1&per_page=10" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Search users ----"
curl "$BASE_URL/admin/users?search=ahmed" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Filter by role ----"
curl "$BASE_URL/admin/users?role=member" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Create new user ----"
curl -X POST "$BASE_URL/admin/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@gym.com",
    "password": "TempPass123",
    "first_name": "New",
    "last_name": "User",
    "role": "member"
}'

echo -e "\n\n---- Update user ----"
curl -X PUT "$BASE_URL/admin/users/5" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Updated",
    "is_active": false
}'

echo -e "\n\n---- Deactivate user ----"
curl -X DELETE "$BASE_URL/admin/users/5" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Revenue report ----"
curl "$BASE_URL/admin/revenue?start_date=2026-01-01&end_date=2026-02-21" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- System analytics ----"
curl "$BASE_URL/admin/analytics" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Memberships ----"
curl "$BASE_URL/admin/memberships?status=active" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Equipment health ----"
curl "$BASE_URL/admin/equipment-health" \
  -H "Authorization: Bearer $TOKEN"

echo -e "\n\n---- Class types ----"
curl "$BASE_URL/classes"

echo -e "\n\n---- Class schedule ----"
curl "$BASE_URL/classes/schedule"

echo -e "\n\n---- Schedule for specific date ----"
curl "$BASE_URL/classes/schedule?date=2026-02-24"

echo -e "\n\n---- Membership tiers ----"
curl "$BASE_URL/membership-tiers"

echo -e "\n\n---- Trainers ----"
curl "$BASE_URL/trainers"

echo -e "\n\n---- Available trainers ----"
curl "$BASE_URL/trainers?available=true"
