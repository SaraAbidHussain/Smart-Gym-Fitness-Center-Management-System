




. System Architecture
┌─────────────────────────────────────────────────────────┐
│              FLUTTER FRONTEND (Chrome Browser)           │
│                                                         │
│  main.dart → SplashScreen                               │
│       ↓ checks JWT in SharedPreferences                 │
│  LoginScreen ←→ RegisterScreen                          │
│       ↓ POST /auth/login → receives JWT token           │
│  DashboardRouter (routes by role)                       │
│  ├── MemberDashboard                                    │
│  │   ├── BrowseClassesScreen (search + filters)        │
│  │   ├── BookingsScreen                                 │
│  │   ├── WorkoutsScreen                                 │
│  │   └── PurchaseMembershipScreen (ACID demo)           │
│  ├── TrainerDashboard                                   │
│  │   ├── Clients Tab                                    │
│  │   ├── Overview Tab (performance metrics)             │
│  │   └── Schedule Tab                                   │
│  ├── StaffDashboard                                     │
│  │   ├── Check-In Tab                                   │
│  │   ├── Attendance Tab                                 │
│  │   └── Equipment Tab                                  │
│  └── AdminDashboard                                     │
│      ├── Overview Tab (charts)                          │
│      ├── Users Tab                                      │
│      └── Revenue Tab                                    │
│                                                         │
│  Services Layer:                                        │
│  ├── ApiService — HTTP GET/POST/PUT/DELETE              │
│  ├── AuthService — login/register/logout                │
│  └── TokenStorage — SharedPreferences CRUD             │
└──────────────────┬──────────────────────────────────────┘
                   │ HTTP requests with Bearer JWT token
                   │ Content-Type: application/json
                   ▼
┌─────────────────────────────────────────────────────────┐
│            FLASK BACKEND (localhost:5000)                │
│              /api/v1/* endpoints                        │
└──────────────────┬──────────────────────────────────────┘
                   │ psycopg2 queries
                   ▼
┌─────────────────────────────────────────────────────────┐
│            POSTGRESQL DATABASE (gymdb)                   │
│              15 tables, 3 triggers, 3 views             │
└─────────────────────────────────────────────────────────┘

Flow explanation:
App starts → SplashScreen checks SharedPreferences for saved JWT
If token exists → reads saved role → routes to correct dashboard
If no token → shows LoginScreen
After login → JWT + role saved via TokenStorage → routed to dashboard
Every API call → ApiService reads token → adds Authorization: Bearer <token> header
On logout → TokenStorage.clearAuth() removes all stored data → back to login
4. UI Examples
Note: Replace placeholder descriptions below with actual screenshots once the app is running. Save screenshots to frontend/screenshots/ folder and update image paths.
Screen 1: Login Screen
File: lib/screens/auth/login_screen.dart
What it looks like:
Black gradient background (top-left to bottom-right)
Gold circular logo with fitness icon at the top
"Welcome Back" heading in white
Email field with gold focus border
Password field with show/hide toggle
Gold "Login" button
"Don't have an account? Register" link
Test credentials box at the bottom (blue tinted)
Why it's important: This is the entry point for all 4 roles. After successful login, the JWT token is stored in SharedPreferences and the user is routed to their role-specific dashboard. The DashboardRouter reads the role field from the login response and renders the correct screen.
API used: POST /api/v1/auth/login
File: lib/services/auth_service.dart → login()
Storage: lib/services/token_storage.dart → saveToken() + saveUserData()

Screen 2: Browse Classes (Member)
File: lib/screens/member/browse_classes_screen.dart
What it looks like:
Dark app bar with "Browse Classes" title and filter icon
Search bar with real-time filtering
Quick filter chips: All Dates / Today / Tomorrow / This Week / Available Only
Sort options: Earliest / Latest / Available / Price
Advanced filter panel (slides in): filter by Class Type and Trainer
Class cards grouped by date with colored left border by class type
Each card shows: class name, trainer, time, location, capacity bar, Book Now button
Full classes show greyed-out "Class Full" button
Success dialog with gold check icon on booking
Why it's important: This is the most complex screen — it implements the Complex Feature: Advanced Search & Filtering. All filtering and sorting happens client-side after fetching from the API. It supports 5 simultaneous filters with a live results counter. The booking button calls the ACID-compliant class booking endpoint.
API used: GET /api/v1/classes/schedule (public, no auth)
          POST /api/v1/members/book-class (authenticated)
File: lib/screens/member/browse_classes_screen.dart

Screen 3: Admin Dashboard
File: lib/screens/admin/admin_dashboard.dart
What it looks like:
Black scaffold with gold bottom navigation (Overview / Users / Revenue)
Overview tab: 2x2 stats grid (Total Users, Members, Classes, Revenue)
Pie chart showing user distribution by role (Members / Trainers / Staff / Admins)
Quick stats section (active memberships, schedules, upcoming classes)
Users tab: scrollable list of all users with avatar initials, role badge, active status dot
Revenue tab: revenue cards per type + bar chart (Membership / Training / Products)
Why it's important: This implements the Complex Feature: Analytics Dashboard with Charts. The admin can see the entire gym's financial health and user distribution at a glance. Uses fl_chart PieChart and BarChart. Pulls from 3 different admin endpoints simultaneously on load.
API used: GET /api/v1/admin/analytics
          GET /api/v1/admin/revenue
          GET /api/v1/admin/users
File: lib/screens/admin/admin_dashboard.dart

Step 1 — Clone the Repository
git clone https://github.com/SaraAbidHussain/Smart-Gym-Fitness-Center-Management-System.git
cd Smart-Gym-Fitness-Center-Management-System/frontend

Step 2 — Create Required Asset Folders
These folders are referenced in pubspec.yaml but not committed to git:
# Run in Windows PowerShell inside the frontend/ folder
mkdir assets\images
mkdir assets\icons
mkdir assets\animations

Step 3 — Configure Environment File
copy .env.example .env

Then open .env and set:
# Backend API base URL
# Change this if your Flask backend runs on a different port or host
API_BASE_URL=http://localhost:5000/api/v1

What each variable means:
Variable
Description
Example Value
API_BASE_URL
Full base URL of the Flask backend including /api/v1
http://localhost:5000/api/v1

The ApiConfig class reads this at runtime:
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000/api/v1',
);

Step 4 — Install Flutter Dependencies
flutter pub get

This installs all packages from pubspec.yaml including http, fl_chart, shared_preferences, etc.
Step 5 — Start the Backend First
In a WSL terminal (keep this running):
cd "/mnt/c/Users/User/Desktop/smart_gym_and _fitness_project/Smart-Gym-Fitness-Center-Management-System/backend"
source venv/bin/activate
python3 run.py


Step 6 — Run the Flutter Frontend
In Windows PowerShell:
cd "C:\Users\User\Desktop\smart_gym_and _fitness_project\Smart-Gym-Fitness-Center-Management-System\frontend"
flutter run -d chrome

6. User Roles & Credentials
The app automatically routes each user to their correct dashboard based on the role field in the JWT response. The DashboardRouter handles this:
switch (role.toLowerCase()) {
  case 'member':  return const MemberDashboard();
  case 'trainer': return const TrainerDashboard();
  case 'staff':   return const StaffDashboard();
  case 'admin':   return const AdminDashboard();
}

Test Credentials (from seed data)
Role
Email
Password
What they see
Member
test.member@gym.com
SecurePass123
Dashboard, bookings, workouts, membership purchase
Member
ahmed.khan@gmail.com
gym123
Same as above, has Premium membership
Trainer
coach.ali@smartgym.com
gym123
Clients, performance stats, schedule, create plans
Trainer
coach.sara@smartgym.com
gym123
Same trainer portal
Staff
staff.hassan@smartgym.com
gym123
Check-in/out panel, attendance, equipment management
Admin
admin@smartgym.com
gym123
Full analytics, user list, revenue charts


7. Feature Walkthrough
Login & Register
File: lib/screens/auth/login_screen.dart, register_screen.dart
Service: lib/services/auth_service.dart
Login sends email/password → receives JWT + role → stored in SharedPreferences → routed to dashboard
Register creates account → redirects to login
Form validation: email format check, minimum 6 character password, password confirmation match
Error messages shown as red SnackBars
Auto-Login (Splash Screen)
File: lib/main.dart → SplashScreen
On app start, reads saved JWT from SharedPreferences
If token found → reads saved role → skips login → goes straight to dashboard
If no token → shows login screen
1 second delay for splash animation effect
Member Dashboard
File: lib/screens/member/member_dashboard.dart
Loads from GET /api/v1/members/dashboard
Shows: personalized welcome with name, membership tier, total visits, classes booked, calories burned, workout logs
Quick action buttons: Browse Classes → opens BrowseClassesScreen, Log Workout → opens WorkoutsScreen
Membership card shows active/inactive status with expiry date
If no membership → shows "Purchase Membership" button
Browse Classes with Advanced Filters ⭐ Complex Feature 1
File: lib/screens/member/browse_classes_screen.dart
Loads from GET /api/v1/classes/schedule
5 simultaneous filters: date range, class type, trainer, availability, text search
Sort options: earliest, latest, availability, price
Results grouped by date with date headers
Capacity progress bar per class (green → yellow → red as it fills)
Booking via POST /api/v1/members/book-class
Falls back to demo data if API has no upcoming classes
Class Bookings Management
File: lib/screens/member/bookings_screen.dart
Loads from GET /api/v1/members/bookings?upcoming=true
Shows confirmed bookings in gold border, waitlist in orange border
Each card: class name, date, time, room, status badge
Cancel button with confirmation dialog
Cancellation calls DELETE /api/v1/members/bookings/{id} → backend trigger auto-promotes waitlist
Workout Logging
File: lib/screens/member/workouts_screen.dart
View and log personal workout sessions
Fields: exercise name, muscle group, sets, reps, weight, calories, difficulty, notes
Loads from GET /api/v1/members/workouts
Logs via POST /api/v1/members/workouts
Purchase Membership (ACID Transaction Demo)
File: lib/screens/member/purchase_membership_screen.dart
Loads available tiers from GET /api/v1/membership-tiers
User selects tier and payment method
Submits to POST /api/v1/payments/purchase-membership
Backend atomically creates membership + payment + optional locker
Success shows membership details, failure shows error message
Demonstrates full ACID transaction to the user
Trainer Dashboard
File: lib/screens/trainer/trainer_dashboard.dart
3 tabs: Overview, Clients, Schedule
Overview: 4 stat cards (clients, avg rating, sessions, upcoming) + quick action buttons to create plans
Clients tab: list of all assigned members with name, email, membership type
Schedule tab: upcoming classes with time, date, room, capacity
Create Plan dialog: quick form to create workout or nutrition plan
Staff Dashboard
File: lib/screens/staff/staff_dashboard.dart
3 tabs: Check In, Attendance, Equipment
Check In tab: enter member ID → Check In / Check Out buttons, shows today's stats
Attendance tab: full list of today's check-ins with check-out button for present members
Equipment tab: all equipment with status (operational/maintenance/out_of_order), tap to update via popup menu
Admin Dashboard ⭐ Complex Feature 2
File: lib/screens/admin/admin_dashboard.dart
3 tabs: Overview, Users, Revenue
Overview: stat grid + pie chart (user distribution by role) + quick stats
Users: paginated user list with role badge and active/inactive indicator
Revenue: revenue cards per type + bar chart breaking down membership vs training vs product revenue
All data loaded in parallel on initState()

8. Transaction Scenarios
Transaction 1: Membership Purchase
What triggers it: Member taps "Purchase Membership" → selects tier → taps "Confirm"
UI file: lib/screens/member/purchase_membership_screen.dart
API called: POST /api/v1/payments/purchase-membership
What happens atomically in the backend:
BEGIN TRANSACTION
  1. Validate tier_id exists in membership_tiers table
  2. Check member has no existing active membership
  3. INSERT new membership record
  4. INSERT payment record
  5. If VIP/Premium: SELECT locker FOR UPDATE → assign locker
COMMIT (everything saved)
OR
ROLLBACK (nothing saved if any step fails)

What the user sees:
Success: "Membership purchased!" with tier name, expiry date, payment ID
Failure (tier not found): "Membership tier does not exist" error
Failure (already has membership): "You already have an active membership" with existing ID
Backend file: backend/app/routes/payments.py → purchase_membership()

Transaction 2: Class Booking with Waitlist
What triggers it: Member taps "Book Now" on a class card
UI file: lib/screens/member/browse_classes_screen.dart → _bookClass()
API called: POST /api/v1/members/book-class
What happens atomically in the backend:
BEGIN TRANSACTION
  1. SELECT class_schedule FOR UPDATE (row-level lock prevents race condition)
  2. Check member not already booked
  3. If spots available → INSERT booking (status='confirmed') + UPDATE capacity
  4. If class full → INSERT booking (status='waitlist', position=N)
COMMIT

What the user sees:
Confirmed: Gold success dialog "Booking Confirmed!" with class name and time
Waitlist: "Class is full. Added to waitlist at position 1."
Already booked: "You have already booked this class"
When booking is cancelled:
DELETE booking → trigger fires automatically
  → trg_promote_waitlist promotes first waitlist member to 'confirmed'
  → capacity decremented
  → all in one atomic operation

Backend file: backend/app/routes/members.py → book_class()

9. ACID Compliance
Property
How it's implemented
Where
Atomicity
All payment/booking steps wrapped in BEGIN/COMMIT. On any exception → conn.rollback() ensures nothing partial is saved. Flutter shows success only when backend returns 201.
payments.py, members.py
Consistency
CHECK constraints enforce valid values (equipment status must be available/in_use/maintenance/broken). UNIQUE on users.email prevents duplicate accounts. NOT NULL on critical fields like nutrition_plans.start_date.
database/schema.sql
Isolation
SELECT FOR UPDATE on class schedules during booking locks the row — prevents two simultaneous requests from double-booking the last spot.
members.py → book_class()
Durability
PostgreSQL WAL (Write-Ahead Logging) active by default. Once conn.commit() returns and backend sends 201, the data survives any subsequent crash. Flutter only updates UI on 201 response.
PostgreSQL default

How Flutter enforces this from the frontend side:
All buttons are disabled during API calls (_isLoading = true)
UI only updates on response.success — never on error responses
Error messages displayed via SnackBar without modifying any local state
On 401 Unauthorized → TokenStorage.clearAuth() → redirect to login
10. Indexing & Performance
The database has 3 strategic indexes that directly benefit the Flutter frontend's most frequent queries:
Index
Table
Column(s)
Frontend query that benefits
idx_users_email
users
email
Login screen — email lookup on every login
idx_memberships_user_status
memberships
user_id, status
Member dashboard — checks active membership on every load
idx_attendance_user_date
attendance
user_id, check_in_time
Staff check-in — validates no duplicate check-in today

Performance impact on Flutter: Without indexes, each of these queries would do a full sequential scan across 240+ rows. With indexes, they use direct index lookups. The member dashboard and class booking screens both benefit from faster response times, reducing the time the gold CircularProgressIndicator is visible.
To run performance tests on the database:
psql -U postgres -d gymdb -f database/performance.sql

11. API Reference
Full OpenAPI documentation is in swagger.yaml. The Flutter ApiConfig class maps every endpoint:
Auth
Method
Route
Auth
Flutter constant
POST
/auth/register
None
ApiConfig.register
POST
/auth/login
None
ApiConfig.login
GET
/auth/me
JWT
ApiConfig.me
POST
/auth/logout
JWT
ApiConfig.logout

Member
Method
Route
Auth
Flutter constant
GET
/members/dashboard
Member
ApiConfig.memberDashboard
GET
/members/membership
Member
ApiConfig.memberMembership
GET
/members/bookings
Member
ApiConfig.memberBookings
POST
/members/book-class
Member
ApiConfig.memberBookClass
DELETE
/members/bookings/{id}
Member
ApiConfig.memberCancelBooking(id)
GET
/members/workouts
Member
ApiConfig.memberWorkouts
POST
/members/workouts
Member
ApiConfig.memberWorkouts
GET
/members/profile
Member
ApiConfig.memberProfile

Trainer
Method
Route
Auth
Flutter constant
GET
/trainers/clients
Trainer
ApiConfig.trainerClients
GET
/trainers/performance
Trainer
ApiConfig.trainerPerformance
GET
/trainers/schedule
Trainer
ApiConfig.trainerSchedule
GET/POST
/trainers/workout-plans
Trainer
ApiConfig.trainerWorkoutPlans
GET/POST
/trainers/nutrition-plans
Trainer
ApiConfig.trainerNutritionPlans

Staff
Method
Route
Auth
Flutter constant
POST
/staff/checkin
Staff
ApiConfig.staffCheckin
POST
/staff/checkout
Staff
ApiConfig.staffCheckout
GET
/staff/attendance/today
Staff
ApiConfig.staffAttendanceToday
PUT
/staff/lockers/{id}
Staff
ApiConfig.staffLocker(id)
GET
/staff/equipment
Staff
ApiConfig.staffEquipment
PUT
/staff/equipment/{id}
Staff
ApiConfig.staffEquipmentUpdate(id)

Admin
Method
Route
Auth
Flutter constant
GET
/admin/users
Admin
ApiConfig.adminUsers
GET
/admin/analytics
Admin
ApiConfig.adminAnalytics
GET
/admin/revenue
Admin
ApiConfig.adminRevenue
GET
/admin/memberships
Admin
ApiConfig.adminMemberships
GET
/admin/equipment-health
Admin
ApiConfig.adminEquipmentHealth

Payments
Method
Route
Auth
Flutter constant
POST
/payments/purchase-membership
Member
ApiConfig.purchaseMembership
GET
/payments/history
Member
ApiConfig.paymentHistory

Public (no auth)
Method
Route
Auth
Flutter constant
GET
/classes
None
ApiConfig.classes
GET
/classes/schedule
None
ApiConfig.classSchedule
GET
/membership-tiers
None
ApiConfig.membershipTiers
GET
/trainers
None
ApiConfig.trainers


