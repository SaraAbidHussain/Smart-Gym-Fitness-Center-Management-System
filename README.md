Smart Gym & Fitness Center Management System
1. Project overview:
Managing a gym is surprisingly complicated. You've got members checking in and out, trainers juggling multiple clients and schedules, staff tracking equipment, and admins who need revenue insights  all happening at the same time. A simple spreadsheet won't cut it.
This system brings all of that under one roof. Members can browse and book classes, trainers can create workout and nutrition plans for their clients, staff can manage check-ins and equipment, and admins can see the full picture through analytics and revenue dashboards.
The project was specifically built to demonstrate real-world database concepts: ACID transactions, triggers, views, indexing, and role-based access control — not just as theory, but as working code you can actually run.
2. Tech Stack
Layer
Technology
Frontend
Flutter Web (Dart)
Backend
Python 3.9+ with Flask
Database
PostgreSQL 16
Authentication
JWT (JSON Web Tokens) + bcrypt password hashing
HTTP Client
Flutter http package
Charts
fl_chart (Admin dashboard)
Local Storage
shared_preferences (token persistence)
API Docs
Swagger / OpenAPI (swagger.yaml)
Environment Config
flutter_dotenv (frontend), python-dotenv (backend)




3. System Architecture
┌─────────────────────────────────────────────────┐
│               Flutter Web Frontend               │
│  (Runs in browser via flutter run -d chrome)     │
│                                                  │
│  Screens → ApiService → HTTP requests            │
│  TokenStorage (SharedPreferences) → JWT token    │
└──────────────────┬──────────────────────────────┘
                   │  REST API calls (JSON)
                   │  Authorization: Bearer <token>
                   ▼
┌─────────────────────────────────────────────────┐
│           Flask Backend (Port 5000)              │
│  (Runs inside WSL Ubuntu on Windows)             │
│                                                  │
│  middleware.py → JWT validation + RBAC           │
│  routes/ → members, trainers, staff, admin...    │
│  db.py → Connection pool (psycopg2)              │
└──────────────────┬──────────────────────────────┘
                   │  SQL queries (psycopg2)
                   ▼
┌─────────────────────────────────────────────────┐
│         PostgreSQL 16 (Port 5432)                │
│  (Runs on Windows, accessible from WSL via IP)   │
│                                                  │
│  15 tables, 3 views, 3 triggers, 3 indexes       │
│  240+ seed records for testing                   │
└─────────────────────────────────────────────────┘


 The Flutter frontend runs in Chrome and makes HTTP requests to the Flask backend at localhost:5000. Every request (except login/register) carries a JWT token in the Authorization header. Flask validates this token using middleware before passing the request to the appropriate route handler. The backend then queries PostgreSQL using a connection pool and returns JSON. The frontend parses this JSON and updates the UI.
Note for WSL users: PostgreSQL runs on Windows but Flask runs inside WSL. The backend connects to PostgreSQL using the Windows host IP (172.24.96.1) rather than localhost.
4. UI Examples
4.1 Login Screen
The login screen is the entry point for all four user roles. It uses a single form the backend determines the role from the database and returns it in the JWT payload. The frontend then routes the user to their role-specific dashboard automatically. There's no separate login page per role, which keeps the UX clean.
Credentials for testing are shown below the login button during development.


4.2 Trainer Dashboard
The trainer dashboard has three tabs: Overview, Clients, and Schedule. The Overview tab shows key stats (total clients, average rating, sessions, upcoming classes) and provides quick action buttons to create workout or nutrition plans. The Clients tab lists all members who have an active plan with this trainer. The Schedule tab shows upcoming class assignments.
This screen is important because it's where the trainer-to-member relationship is established creating a plan for a member is what makes that member show up as a "client."

4.3 Member Dashboard
Members see their personal stats (total gym visits, classes booked, calories burned, workout logs) along with their active membership status. From here they can browse and book classes or log a workout. If their membership has expired, a "Purchase Membership" button appears that triggers the ACID transaction flow.
This is the most frequently used screen in the system and demonstrates the member-facing side of every major feature.

5. Setup & Installation
Prerequisites
Make sure you have all of these installed before starting:
Tool
Minimum Version
Notes
Python
3.9+
Use python3 in WSL
PostgreSQL
16+
Install on Windows (not inside WSL)
Flutter
3.x
Run frontend from Windows PowerShell
Git
Any
For cloning
WSL (Ubuntu)
20.04+
Windows users only


Step 1 : Clone the Repository
git clone https://github.com/SaraAbidHussain/Smart-Gym-Fitness-Center-Management-System.git
cd Smart-Gym-Fitness-Center-Management-System

Step 2 : Set Up the Database
Open PostgreSQL (Windows users: open pgAdmin or psql as the postgres user):
Create the database
CREATE DATABASE gymdb;

 Connect to it
\c gymdb

 Run schema (creates all 15 tables, triggers, views, indexes)
\i database/schema.sql

 Seed test data (240+ records across all tables)
\i database/seed.sql

 Load performance indexes and test queries
\i database/performance.sql
Step 3 : Set Up the Backend
Open a WSL terminal:
cd "/mnt/c/Users/User/Desktop/smart_gym_and _fitness_project/Smart-Gym-Fitness-Center-Management-System/backend"

 Create virtual environment
python3 -m venv venv

 Activate it
source venv/bin/activate

 Install dependencies
pip install -r requirements.txt

Step 4 : Configure Backend Environment
Create a .env file in the backend/ folder:
cp .env.example .env
nano .env

Fill it in like this:
# PostgreSQL connection — use Windows IP if running from WSL
DB_HOST=172.24.96.1      # Your Windows machine's IP (run `cat /etc/resolv.conf` in WSL to find it)
DB_PORT=5432             # Default PostgreSQL port
DB_NAME=gymdb            # Name of the database you created
DB_USER=postgres         # PostgreSQL username
DB_PASSWORD=your_password_here   # Your PostgreSQL password

# JWT secret — any long random string, keep it secret
JWT_SECRET=your_random_secret_key_here
SECRET_KEY=same_or_different_secret_here

Finding your Windows IP from WSL: Run cat /etc/resolv.conf | grep nameserver — the IP shown is your Windows host IP.

Step 5 — Start the Backend Server
# Make sure you're in the backend folder with venv activated
cd "/mnt/c/Users/User/Desktop/smart_gym_and _fitness_project/Smart-Gym-Fitness-Center-Management-System/backend"
source venv/bin/activate
python3 run.py

You should see: Running on http://0.0.0.0:5000
Quick test (in a new terminal):
curl http://localhost:5000/api/v1/membership-tiers

If you get JSON back, the backend is working.

Step 6 — Set Up the Frontend
Open Windows PowerShell (not WSL — Flutter doesn't run well in WSL):
cd "C:\Users\User\Desktop\smart_gym_and _fitness_project\Smart-Gym-Fitness-Center-Management-System\frontend"

# Create .env file for Flutter
copy .env.example .env

# Install Flutter dependencies
flutter pub get

# Create required asset folders if they don't exist
mkdir assets\images -ErrorAction SilentlyContinue
mkdir assets\icons -ErrorAction SilentlyContinue
mkdir assets\animations -ErrorAction SilentlyContinue


Step 7 — Configure Frontend Environment
Edit frontend/.env:
API_BASE_URL=http://localhost:5000/api/v1


Step 8 — Run the Frontend
flutter run -d chrome

The app will open in Chrome at localhost:<port>.

Troubleshooting
"flutter: No such file or directory" in WSL
 → Flutter must be run from Windows PowerShell, not WSL.
"connection refused" from backend
 → Make sure PostgreSQL is running on Windows. Check with: pg_ctl status
"DB_HOST connection failed"
 → Your WSL IP may have changed. Run cat /etc/resolv.conf to get the current one and update .env.
Port 5000 already in use
sudo lsof -t -i:5000 | xargs kill -9

.env file missing after git pull
 → Sara deleted the .env in a commit — always recreate it manually using the values above.

6. User Roles
The system has four distinct roles. Each role sees a completely different dashboard after login.
Member
Can view their own stats, book gym classes, log personal workouts, check membership status, and purchase a membership. Cannot see other members' data or access admin/staff features.
Test credentials:
Email
Password
Notes
ahmed.khan@gmail.com
gym123
user_id = 1, has existing data
test.member@gym.com
SecurePass123
user_id = 25


Trainer
Can view their assigned clients, create workout and nutrition plans for members, check their own performance metrics, and see their class schedule. Cannot access staff or admin features.
Test credentials:
Email
Password
Notes
coach.ali@smartgym.com
gym123
trainer_id = 1, has clients
coach.sara@smartgym.com
gym123
trainer_id = 2
sara@gmail.com
gym123
trainer_id = 6, registered via UI
fatima@gmail.com
gym123
trainer_id = 7, registered via UI

Important: test.trainer@gym.com does NOT have a trainer profile in the trainers table — logging in with it will fail to load trainer-specific features. Use coach.ali@smartgym.com for reliable testing.
Staff
Can check members in and out of the gym, view today's attendance, update equipment status, and manage lockers. Cannot see financial data or user management.
Test credentials:
Email
Password
staff.hassan@smartgym.com
gym123
staff.amna@smartgym.com
gym123
test.staff@gym.com
gym123


Admin
Has full system access. Can view and manage all users, see revenue reports, check system analytics, and monitor equipment health. The admin dashboard includes charts for user distribution and revenue breakdown.
Test credentials:
Email
Password
admin@smartgym.com
gym123
test.admin@gym.com
gym123


7. Feature Walkthrough
Authentication (/api/v1/auth/)
Every user registers and logs in through the same form. On login, the backend returns a JWT token and the user's role. The Flutter TokenStorage service saves this token to SharedPreferences so the user stays logged in across sessions. On the next app launch, SplashScreen reads the saved role and routes directly to the correct dashboard.
Member Dashboard (GET /api/v1/members/dashboard)
Shows total gym visits, confirmed bookings, calories burned, and workout logs — all pulled from a single optimized view (member_dashboard_view). Also shows membership status and expiry date. Accessible only to members.
Class Booking (POST /api/v1/members/book-class)
Members browse available classes with filters (date, type, trainer, availability). When they book, an ACID transaction runs: it checks capacity, creates the booking, and if the class is full, automatically places the member on a waitlist. A database trigger handles the waitlist promotion when someone cancels.
Workout Logging (POST /api/v1/members/workouts)
Members can log individual exercises including sets, reps, weight, calories burned, and difficulty. Logs are stored in workout_logs and feed into the dashboard stats.
Trainer Client Management (GET /api/v1/trainers/clients)
Shows all members who have at least one workout or nutrition plan assigned by this trainer. The query joins users, workout_plans, nutrition_plans, and memberships to give a complete picture of each client.
Workout Plan Creation (POST /api/v1/trainers/workout-plans)
Trainers create plans assigned to a specific member (user_id). Required fields: plan_name, goal, user_id. The plan is stored in workout_plans linked to both the trainer and the member. Once created, the member appears in the trainer's client list.
Nutrition Plan Creation (POST /api/v1/trainers/nutrition-plans)
Similar to workout plans but includes macros: daily_calories, protein_grams, carbs_grams, fat_grams. The start_date field is NOT NULL in the schema — the backend sets it to the current date automatically.
Staff Check-In/Out (POST /api/v1/staff/checkin, POST /api/v1/staff/checkout)
Staff enter a member's user_id to check them in. The system records check_in_time in the attendance table. Check-out records check_out_time and calculates duration_minutes. Today's full attendance list is available at GET /api/v1/staff/attendance/today.
Equipment Management (GET/PUT /api/v1/staff/equipment)
Staff see all equipment with current status. They can update status to available, in_use, maintenance, or broken using the three-dot menu on each card. Changes are reflected immediately.
Membership Purchase — ACID Transaction (POST /api/v1/payments/purchase-membership)
The most complex feature in the system. Described in detail in Section 8.
Admin Analytics (GET /api/v1/admin/analytics)
Returns aggregated data: user counts by role, class statistics, membership stats. Powers the pie chart and stats grid on the admin overview tab.
Admin Revenue (GET /api/v1/admin/revenue)
Breaks down total revenue by category (membership, training, products). Powers the bar chart on the admin revenue tab.
Admin User Management (GET/POST/PUT/DELETE /api/v1/admin/users)
Admins can list all users, create new ones, update existing ones, and deactivate accounts. Includes pagination (per_page parameter).
8. Transaction Scenarios
Transaction 1 : Membership Purchase
What triggers it: A member selects a membership tier and payment method on the PurchaseMembershipScreen and taps "Complete Purchase."
What happens atomically:
BEGIN transaction
Insert a record into payments (payment_id, amount, method, status='completed')
Insert a record into memberships (user_id, tier_id, start_date, end_date, status='active')
If the tier is Premium or VIP: find an available locker, assign it in lockers, update current_user_id
COMMIT
What causes a rollback:
Member already has an active membership → rollback, payment not created
No lockers available for Premium/VIP tier → rollback, nothing is saved
Any database error during any step → full rollback
Code location: backend/app/routes/payments.py → purchase_membership() function
 Endpoint: POST /api/v1/payments/purchase-membership
Transaction 2 : Class Booking
What triggers it: A member taps "Book Now" on any class in BrowseClassesScreen.
What happens atomically:
BEGIN transaction
Check current capacity vs max capacity (with row-level lock)
If space available: insert confirmed booking into class_bookings
If full: insert waitlist booking with position_in_waitlist
Update current_capacity in class_schedules
COMMIT
What causes a rollback:
Member already has a booking for this schedule → rollback with "already booked" error
Concurrent booking fills the last spot between check and insert → rollback
Database trigger: A trigger on class_bookings automatically promotes the first waitlisted member when a confirmed booking is cancelled.
Code location: backend/app/routes/classes.py
 Endpoint: POST /api/v1/members/book-class
9. ACID Compliance
Property
How It's Implemented
Atomicity
Every transaction uses explicit BEGIN / COMMIT / ROLLBACK in Python. If any step throws an exception, conn.rollback() is called in the except block — nothing is partially saved.
Consistency
Database constraints enforce consistency: NOT NULL on critical fields, FOREIGN KEY constraints between tables, CHECK constraints on status enums, and UNIQUE constraints prevent duplicate bookings.
Isolation
psycopg2 uses READ COMMITTED isolation by default. The class booking transaction uses SELECT ... FOR UPDATE to lock the schedule row and prevent double-booking under concurrent load.
Durability
PostgreSQL writes committed transactions to its WAL (Write-Ahead Log) before acknowledging success. Even if the server crashes after a commit, the data survives. This is handled by PostgreSQL internally — no application code needed.


10. Indexing & Performance
Three strategic indexes were created in database/performance.sql:
Index 1 : idx_attendance_user_date
CREATE INDEX idx_attendance_user_date ON attendance(user_id, check_in_time DESC);

Why: The member dashboard queries attendance filtered by user_id and ordered by date. Without this index, PostgreSQL does a full sequential scan of the entire attendance table for every dashboard load.
 Result: Query time dropped from ~45ms to ~3ms on 240 records. The improvement grows significantly at scale.

Index 2 : idx_class_bookings_schedule
CREATE INDEX idx_class_bookings_schedule ON class_bookings(schedule_id, status);

Why: Capacity checks during booking query class_bookings filtered by schedule_id and status = 'confirmed'. This runs inside an ACID transaction where speed matters.
 Result: Capacity check query dropped from sequential scan to index scan — roughly 10x faster.
Index 3 — idx_memberships_user_status
CREATE INDEX idx_memberships_user_status ON memberships(user_id, status, end_date);

Why: Almost every authenticated request checks if a member has an active membership. This index makes that lookup near-instant instead of scanning the whole memberships table.
 Result: Membership validation query consistently uses index scan rather than sequential scan.
11. API Reference
Full documentation is in swagger.yaml. This is a quick-reference summary:
Authentication
Method
Route
Auth
Purpose
POST
/api/v1/auth/register
No
Register new user
POST
/api/v1/auth/login
No
Login, get JWT token
GET
/api/v1/auth/me
Yes
Get current user info
POST
/api/v1/auth/logout
Yes
Logout

Member Endpoints
Method
Route
Auth
Purpose
GET
/api/v1/members/dashboard
Member
Stats overview
GET
/api/v1/members/membership
Member
Membership details
GET
/api/v1/members/bookings
Member
View bookings
POST
/api/v1/members/book-class
Member
Book a class (ACID)
DELETE
/api/v1/members/bookings/{id}
Member
Cancel booking
GET
/api/v1/members/workouts
Member
Workout history
POST
/api/v1/members/workouts
Member
Log a workout
GET/PUT
/api/v1/members/profile
Member
View/update profile

Trainer Endpoints
Method
Route
Auth
Purpose
GET
/api/v1/trainers/clients
Trainer
List assigned clients
GET
/api/v1/trainers/performance
Trainer
Performance metrics
GET
/api/v1/trainers/schedule
Trainer
Upcoming classes
GET/POST
/api/v1/trainers/workout-plans
Trainer
Manage workout plans
GET/POST
/api/v1/trainers/nutrition-plans
Trainer
Manage nutrition plans

Staff Endpoints
Method
Route
Auth
Purpose
POST
/api/v1/staff/checkin
Staff
Check member in
POST
/api/v1/staff/checkout
Staff
Check member out
GET
/api/v1/staff/attendance/today
Staff
Today's attendance
PUT
/api/v1/staff/lockers/{id}
Staff
Update locker
GET
/api/v1/staff/equipment
Staff
View equipment
PUT
/api/v1/staff/equipment/{id}
Staff
Update equipment status

Admin Endpoints
Method
Route
Auth
Purpose
GET
/api/v1/admin/users
Admin
List all users
POST
/api/v1/admin/users
Admin
Create user
PUT
/api/v1/admin/users/{id}
Admin
Update user
DELETE
/api/v1/admin/users/{id}
Admin
Delete user
GET
/api/v1/admin/revenue
Admin
Revenue report
GET
/api/v1/admin/analytics
Admin
System analytics
GET
/api/v1/admin/memberships
Admin
All memberships
GET
/api/v1/admin/equipment-health
Admin
Equipment health

Payments & Public
Method
Route
Auth
Purpose
POST
/api/v1/payments/purchase-membership
Member
Buy membership (ACID)
GET
/api/v1/payments/history
Member
Payment history
GET
/api/v1/classes
No
Browse classes
GET
/api/v1/classes/schedule
No
Class schedule
GET
/api/v1/membership-tiers
No
Available tiers
GET
/api/v1/trainers
No
Browse trainers


12. Known Issues & Limitations
Trainer Workout Plan : Member Selection
The trainer's GET /trainers/clients endpoint only returns members who already have a plan with that trainer. This means a brand-new trainer with zero plans sees an empty client list and can't assign plans to anyone. This is a chicken-and-egg problem in the current schema. Workaround: Use coach.ali@smartgym.com who already has clients, or add a separate endpoint that lists all members. This is noted as a known limitation.
test.trainer@gym.com Has No Trainer Profile
Users who registered with the trainer role via the UI (like test.trainer@gym.com, sara@gmail.com, fatima@gmail.com) don't automatically get a row in the trainers table — the registration endpoint only inserts into users. This requires a manual insert. The fix script is documented in the project notes.
test_staff.py : 2 Test Failures
These are test bugs, not code bugs:
S2.3: Test expects operational status but returns available (valid status value mismatch in test)
S3.2: Test sends broken as an invalid status but the backend actually accepts it as valid
Flutter — Missing Asset Folders
The assets/images, assets/icons, and assets/animations folders aren't committed to the repo (they're empty). Flutter will throw an error on first run if they don't exist. Create them manually with mkdir before running (see Setup section).
backend/venv Committed to Git
The virtual environment folder is checked into the repository, which inflates the repo size unnecessarily. It's listed in .gitignore but was committed before the ignore rule was added. Safe to delete locally — just re-run pip install -r requirements.txt.
Nutrition Plan — start_date is NOT NULL
The nutrition_plans.start_date column is NOT NULL in the schema. The backend handles this by defaulting to CURRENT_DATE, but if you're calling the API directly without the backend's logic, you must provide it manually.
No Real Payment Integration
The payment system is a demonstration of ACID transactions. No actual money moves — it just inserts records into the payments table. In a production system, you'd integrate a payment gateway (Stripe, etc.) before calling the membership purchase endpoint.
Admin Dashboard Charts Require fl_chart
The AdminDashboard uses fl_chart for pie and bar charts. If you get a "package not found" error, run flutter pub get again.

13. Project Structure
Smart-Gym-Fitness-Center-Management-System/
│
├── backend/
│   ├── app/
│   │   ├── __init__.py          # Blueprint registration
│   │   ├── auth.py              # Login & register logic
│   │   ├── middleware.py        # JWT validation + role-based access
│   │   ├── db.py                # PostgreSQL connection pool
│   │   ├── config.py            # App configuration
│   │   └── routes/
│   │       ├── members.py       # Member endpoints
│   │       ├── trainers.py      # Trainer endpoints
│   │       ├── staff.py         # Staff endpoints
│   │       ├── payments.py      # ACID payment transactions
│   │       ├── classes.py       # Class booking (ACID)
│   │       ├── admin.py         # Admin endpoints
│   │       └── general.py       # Public endpoints
│   ├── test_auth.py
│   ├── test_members.py
│   ├── test_trainers.py         # 24/24 passing
│   ├── test_staff.py            # 29/31 passing (2 test bugs)
│   ├── test_transactions.py     # 19/19 passing
│   ├── run.py                   # Flask entry point
│   ├── .env                     # Environment variables (not in git)
│   ├── .env.example             # Template for .env
│   └── requirements.txt
│
├── database/
│   ├── schema.sql               # All 15 tables, triggers, views, indexes
│   ├── seed.sql                 # 240+ test records
│   └── performance.sql          # Index creation + before/after benchmarks
│
├── frontend/
│   ├── lib/
│   │   ├── main.dart            # App entry, splash screen, routing
│   │   ├── config/
│   │   │   ├── api_config.dart  # All endpoint URLs in one place
│   │   │   └── app_theme.dart   # Dark gold theme
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── member/
│   │   │   │   ├── member_dashboard.dart
│   │   │   │   ├── bookings_screen.dart
│   │   │   │   ├── browse_classes_screen.dart
│   │   │   │   ├── purchase_membership_screen.dart
│   │   │   │   └── workouts_screen.dart
│   │   │   ├── trainer/
│   │   │   │   └── trainer_dashboard.dart
│   │   │   ├── staff/
│   │   │   │   └── staff_dashboard.dart
│   │   │   ├── admin/
│   │   │   │   └── admin_dashboard.dart
│   │   │   └── dashboard_router.dart  # Role → screen routing
│   │   └── services/
│   │       ├── api_service.dart       # HTTP client wrapper
│   │       ├── auth_service.dart      # Login/logout/register
│   │       └── token_storage.dart     # JWT persistence
│   ├── assets/
│   │   ├── fonts/               # Poppins font family
│   │   ├── images/              # (create manually)
│   │   ├── icons/               # (create manually)
│   │   └── animations/          # (create manually)
│   ├── pubspec.yaml
│   └── .env                     # API base URL (not in git)
│
├── docs/
│   ├── ER_Diagram.pdf
│   ├── Schema_Documentation.pdf
│   └── ACID_Documentation.pdf
│
├── swagger.yaml                 # Full API documentation
├── BACKEND_EXPLANATION.pdf
└── README.md


14. Running the Test Suite
All tests live in the backend folder. With the venv activated and backend running:
cd backend
source venv/bin/activate

# Run all test files
python3 test_auth.py
python3 test_members.py
python3 test_trainers.py      # Should show 24/24 passed
python3 test_staff.py         # Should show 29/31 passed (2 known test bugs)
python3 test_transactions.py  # Should show 19/19 passed


Contact
Sara Abid Hussain: saraabidhussain12@gmail.com
Partner: anayafatima00008@gmail.com

Academic project — All rights reserved. Built to demonstrate database design, ACID compliance, and full-stack development.

