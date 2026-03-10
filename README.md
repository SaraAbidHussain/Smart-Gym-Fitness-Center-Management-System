# Smart Gym Management System

A full-stack gym management platform built for our Database Management course project.

## Tech Stack

- **Backend:** Python Flask
- **Database:** PostgreSQL
- **Frontend:** Flutter Web (Phase 3)
- **Auth:** JWT + bcrypt

## Features

- Member dashboard with workout tracking
- Class booking with automatic waitlist
- Trainer and staff portals
- Admin analytics and user management
- ACID-compliant transactions
- Role-based access control (4 roles)

## Database

- 15 normalized tables (3NF)
- 3 strategic indexes
- 3 triggers for business rules
- 3 analytical views
- 240+ test records

## Quick Setup

### Prerequisites

- PostgreSQL 16+
- Python 3.9+

### Installation

```bash
# 1. Clone repository
git clone https://github.com/SaraAbidHussain/smart-gym-management.git
cd smart-gym-management

# 2. Setup database
sudo -u postgres psql
CREATE DATABASE smart_gym;
\c smart_gym
\i database/schema.sql
\i database/seed.sql
\i database/performance.sql
\q

# 3. Setup backend
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
nano .env  # Update DB_PASSWORD

# 5. Run server
python run.py
```

Server runs at: http://localhost:5000

## API Documentation

see: `swagger.yaml`

## Testing

```bash
# Test authentication
curl -X POST http://localhost:5000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@gym.com","password":"Pass1234","first_name":"Test","last_name":"User","role":"member"}'

curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@gym.com","password":"Pass1234"}'

# Use returned token for protected endpoints
curl http://localhost:5000/api/v1/members/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Project Structure

```
smart-gym-management/
├── backend/
│   ├── app/
│   │   ├── auth.py              # Authentication
│   │   ├── middleware.py        # JWT & RBAC
│   │   └── routes/              # API endpoints
│   ├── run.py                   # Entry point
│   └── requirements.txt
├── database/
│   ├── schema.sql               # Database schema
│   ├── seed.sql                 # Test data
│   └── performance.sql          # Index tests
├── docs/
│   ├── ER_Diagram.pdf
│   ├── Schema_Documentation.pdf
│   └── ACID_Documentation.pdf
└── README.md
└── BACKEND EXPLANATION DOCUMENT.pdf
└── swagger.yaml

```

## API Endpoints

### Authentication
- POST `/api/v1/auth/register` - Register
- POST `/api/v1/auth/login` - Login

### Members (requires member role)
- GET `/api/v1/members/dashboard` - Stats
- GET `/api/v1/members/bookings` - Class bookings
- POST `/api/v1/members/book-class` - Book class
- POST `/api/v1/members/workouts` - Log workout
- GET/PUT `/api/v1/members/profile` - Profile

### Admin (requires admin role)
- GET `/api/v1/admin/users` - List users
- GET `/api/v1/admin/revenue` - Revenue reports
- GET `/api/v1/admin/analytics` - System stats

### Public (no auth required)
- GET `/api/v1/classes` - Browse classes
- GET `/api/v1/classes/schedule` - View schedule
- GET `/api/v1/membership-tiers` - Pricing
- GET `/api/v1/trainers` - Browse trainers

**Total:** 30+ endpoints

## User Roles

| Role | Access Level |
|------|--------------|
| **Member** | Personal data, bookings, workouts |
| **Trainer** | Client management, plans, schedules |
| **Staff** | Check-ins, lockers, equipment |
| **Admin** | Full system access, analytics, user management |

## ACID Transactions

1. **Membership Purchase:** Payment + membership + locker assignment (atomic)
2. **Class Booking:** Capacity check + booking + waitlist (with trigger)

See `Backend_Explanation.pdf` for details.

## Development Team

- **Group:** [Your Group Number]
- **Members:** [Your Names]
- **Course:** Advanced Database Management
- **Semester:** 4th Semester
- **Institution:** [Your University]

## Phase Status

- Phase 1: Database Design (Complete)
- Phase 2: Backend API (Complete)
- Phase 3: Frontend (In Progress)

## Troubleshooting

**Database connection failed**
```bash
sudo systemctl start postgresql
sudo systemctl status postgresql
```

**Port 5000 already in use**
```bash
# Change PORT in .env or kill process
sudo lsof -t -i:5000 | xargs kill -9
```

**Module not found errors**
```bash
pip install -r requirements.txt
# Ensure virtual environment is activated
```

## License

Academic project - All rights reserved.

## Contact

For questions: [saraabidhussain12@gmail.com] or [anayafatima00008@gmail.com]

---

**Note:** This is an academic project demonstrating database design, ACID compliance, and full-stack development skills.