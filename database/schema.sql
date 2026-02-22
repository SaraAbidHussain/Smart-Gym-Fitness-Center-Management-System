
-- SMART GYM MANAGEMENT SYSTEM
-- schema.sql - Complete Database Schema
-- Database: PostgreSQL

-- TABLE 1: USERS
-- Core user authentication and profile management

CREATE TABLE users (
    user_id       SERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name    VARCHAR(100) NOT NULL,
    last_name     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20),
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('member', 'trainer', 'staff', 'admin')),
    date_of_birth DATE,
    gender        VARCHAR(10)  CHECK (gender IN ('male', 'female', 'other')),
    created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    is_active     BOOLEAN      DEFAULT TRUE
);

-- TABLE 2: MEMBERSHIP_TIERS
-- Defines Basic, Premium, VIP tier offerings
CREATE TABLE membership_tiers (
    tier_id                SERIAL PRIMARY KEY,
    tier_name              VARCHAR(50)    NOT NULL UNIQUE,
    monthly_fee            DECIMAL(10, 2) NOT NULL CHECK (monthly_fee >= 0),
    access_sauna           BOOLEAN        DEFAULT FALSE,
    access_pool            BOOLEAN        DEFAULT FALSE,
    access_premium_zone    BOOLEAN        DEFAULT FALSE,
    max_classes_per_month  INTEGER        CHECK (max_classes_per_month >= 0),
    description            TEXT
);

-- TABLE 3: MEMBERSHIPS
-- Tracks active member subscriptions
CREATE TABLE memberships (
    membership_id          SERIAL PRIMARY KEY,
    user_id                INTEGER        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    tier_id                INTEGER        NOT NULL REFERENCES membership_tiers (tier_id),
    start_date             DATE           NOT NULL,
    end_date               DATE           NOT NULL,
    is_frozen              BOOLEAN        DEFAULT FALSE,
    frozen_days_remaining  INTEGER        DEFAULT 0 CHECK (frozen_days_remaining >= 0),
    auto_renew             BOOLEAN        DEFAULT TRUE,
    status                 VARCHAR(20)    DEFAULT 'active' CHECK (status IN ('active', 'expired', 'frozen', 'cancelled')),
    CONSTRAINT valid_dates CHECK (end_date > start_date)
);


-- TABLE 4: TRAINERS
-- Trainer profiles linked 1:1 to Users
CREATE TABLE trainers (
    trainer_id        SERIAL PRIMARY KEY,
    user_id           INTEGER        NOT NULL UNIQUE REFERENCES users (user_id) ON DELETE CASCADE,
    specialization    VARCHAR(100),
    certification     VARCHAR(255),
    hourly_rate       DECIMAL(10, 2) CHECK (hourly_rate >= 0),
    years_experience  INTEGER        CHECK (years_experience >= 0),
    bio               TEXT,
    is_available      BOOLEAN        DEFAULT TRUE,
    rating            DECIMAL(3, 2)  DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5)
);

-- TABLE 5: CLASSES
-- Group class definitions / templates
CREATE TABLE classes (
    class_id         SERIAL PRIMARY KEY,
    class_name       VARCHAR(100) NOT NULL,
    description      TEXT,
    class_type       VARCHAR(50),
    duration_minutes INTEGER      NOT NULL CHECK (duration_minutes > 0),
    difficulty_level VARCHAR(20)  CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced')),
    max_capacity     INTEGER      NOT NULL CHECK (max_capacity > 0)
);

-- TABLE 6: CLASS_SCHEDULES
-- Scheduled instances of classes
CREATE TABLE class_schedules (
    schedule_id       SERIAL PRIMARY KEY,
    class_id          INTEGER     NOT NULL REFERENCES classes (class_id) ON DELETE CASCADE,
    trainer_id        INTEGER     NOT NULL REFERENCES trainers (trainer_id),
    schedule_date     DATE        NOT NULL,
    start_time        TIME        NOT NULL,
    end_time          TIME        NOT NULL,
    room_number       VARCHAR(20),
    current_capacity  INTEGER     DEFAULT 0 CHECK (current_capacity >= 0),
    status            VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'cancelled', 'completed')),
    CONSTRAINT valid_times CHECK (end_time > start_time)
);


-- TABLE 7: CLASS_BOOKINGS
-- M:M Junction table: Users <-> ClassSchedules
CREATE TABLE class_bookings (
    booking_id            SERIAL PRIMARY KEY,
    schedule_id           INTEGER     NOT NULL REFERENCES class_schedules (schedule_id) ON DELETE CASCADE,
    user_id               INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    booking_date          TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    status                VARCHAR(20) DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'waitlist', 'cancelled', 'attended')),
    position_in_waitlist  INTEGER,
    CONSTRAINT unique_booking UNIQUE (schedule_id, user_id)
);


-- TABLE 8: WORKOUT_PLANS
-- Trainer-created workout templates for members
CREATE TABLE workout_plans (
    plan_id      SERIAL PRIMARY KEY,
    user_id      INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    trainer_id   INTEGER     NOT NULL REFERENCES trainers (trainer_id),
    plan_name    VARCHAR(100) NOT NULL,
    description  TEXT,
    goal         VARCHAR(100),
    start_date   DATE        NOT NULL,
    end_date     DATE,
    is_active    BOOLEAN     DEFAULT TRUE,
    created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 9: WORKOUT_LOGS
-- Individual exercise logging by members
CREATE TABLE workout_logs (
    log_id           SERIAL PRIMARY KEY,
    user_id          INTEGER        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    plan_id          INTEGER        REFERENCES workout_plans (plan_id) ON DELETE SET NULL,
    workout_date     DATE           NOT NULL,
    exercise_name    VARCHAR(100)   NOT NULL,
    muscle_group     VARCHAR(50),
    sets             INTEGER        CHECK (sets > 0),
    reps             INTEGER        CHECK (reps > 0),
    weight_kg        DECIMAL(6, 2)  CHECK (weight_kg >= 0),
    duration_minutes INTEGER        CHECK (duration_minutes > 0),
    calories_burned  INTEGER        CHECK (calories_burned >= 0),
    difficulty       VARCHAR(20)    CHECK (difficulty IN ('easy', 'moderate', 'hard')),
    notes            TEXT,
    created_at       TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 10: EQUIPMENT
-- Gym equipment inventory
CREATE TABLE equipment (
    equipment_id           SERIAL PRIMARY KEY,
    equipment_name         VARCHAR(100)   NOT NULL,
    equipment_type         VARCHAR(50),
    zone                   VARCHAR(50),
    purchase_date          DATE,
    purchase_cost          DECIMAL(10, 2) CHECK (purchase_cost >= 0),
    manufacturer           VARCHAR(100),
    model_number           VARCHAR(100),
    status                 VARCHAR(20)    DEFAULT 'available' CHECK (status IN ('available', 'in_use', 'maintenance', 'broken')),
    total_usage_hours      INTEGER        DEFAULT 0 CHECK (total_usage_hours >= 0),
    last_maintenance_date  DATE,
    next_maintenance_due   DATE
);
-- TABLE 11: EQUIPMENT_MAINTENANCE
-- Maintenance and repair history

CREATE TABLE equipment_maintenance (
    maintenance_id    SERIAL PRIMARY KEY,
    equipment_id      INTEGER        NOT NULL REFERENCES equipment (equipment_id) ON DELETE CASCADE,
    maintenance_date  DATE           NOT NULL,
    maintenance_type  VARCHAR(50)    CHECK (maintenance_type IN ('routine', 'repair', 'inspection')),
    description       TEXT,
    technician_name   VARCHAR(100),
    cost              DECIMAL(10, 2) CHECK (cost >= 0),
    status            VARCHAR(20)    DEFAULT 'completed' CHECK (status IN ('scheduled', 'in_progress', 'completed')),
    created_at        TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 12: LOCKERS
-- Locker inventory and assignments

CREATE TABLE lockers (
    locker_id        SERIAL PRIMARY KEY,
    locker_number    VARCHAR(10)  NOT NULL UNIQUE,
    locker_size      VARCHAR(20)  CHECK (locker_size IN ('small', 'medium', 'large')),
    location         VARCHAR(50),
    status           VARCHAR(20)  DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'maintenance')),
    current_user_id  INTEGER      REFERENCES users (user_id) ON DELETE SET NULL,
    assigned_at      TIMESTAMP
);


-- TABLE 13: ATTENDANCE
-- Member check-in / check-out tracking
CREATE TABLE attendance (
    attendance_id    SERIAL PRIMARY KEY,
    user_id          INTEGER   NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    check_in_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_time   TIMESTAMP,
    duration_minutes INTEGER,
    locker_assigned  INTEGER   REFERENCES lockers (locker_id) ON DELETE SET NULL,
    access_areas     TEXT,
    CONSTRAINT valid_checkout CHECK (check_out_time IS NULL OR check_out_time > check_in_time)
);


-- TABLE 14: PAYMENTS
-- All financial transactions
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    user_id         INTEGER        NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    payment_type    VARCHAR(50)    NOT NULL CHECK (payment_type IN ('membership', 'training_session', 'product', 'late_fee', 'other')),
    amount          DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method  VARCHAR(30)    CHECK (payment_method IN ('cash', 'credit_card', 'debit_card', 'online')),
    payment_date    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    reference_id    INTEGER,
    description     TEXT,
    status          VARCHAR(20)    DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded'))
);

-- TABLE 15: NUTRITION_PLANS
-- Trainer-created meal plans for members
CREATE TABLE nutrition_plans (
    nutrition_plan_id      SERIAL PRIMARY KEY,
    user_id                INTEGER     NOT NULL REFERENCES users (user_id) ON DELETE CASCADE,
    trainer_id             INTEGER     NOT NULL REFERENCES trainers (trainer_id),
    plan_name              VARCHAR(100) NOT NULL,
    daily_calories_target  INTEGER     CHECK (daily_calories_target > 0),
    protein_grams          INTEGER     CHECK (protein_grams >= 0),
    carbs_grams            INTEGER     CHECK (carbs_grams >= 0),
    fats_grams             INTEGER     CHECK (fats_grams >= 0),
    meals_plan             TEXT,
    start_date             DATE        NOT NULL,
    end_date               DATE,
    is_active              BOOLEAN     DEFAULT TRUE,
    created_at             TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
-- INDEX 1: Composite index for billing reports and payment history queries
-- Justification: Most common query pattern for generating monthly statements
-- Query pattern: SELECT * FROM payments WHERE user_id = X AND payment_date BETWEEN ...
-- Benefit: Combines user filtering with date range scanning, supports ORDER BY payment_date DESC
CREATE INDEX idx_payments_user_date ON payments (user_id, payment_date);

-- INDEX 2: Index on check-in timestamp for attendance tracking
-- Justification: Staff frequently query attendance by time range for reports
-- Query pattern: SELECT * FROM attendance WHERE check_in_time BETWEEN ... ORDER BY check_in_time
-- Benefit: Fast range scans for date-filtered queries, eliminates full table scan
CREATE INDEX idx_attendance_checkin ON attendance (check_in_time);

-- INDEX 3: Composite index for class schedule search
-- Justification: Members search classes by date and need results sorted by time
-- Query pattern: SELECT * FROM class_schedules WHERE schedule_date = '...' ORDER BY start_time
-- Benefit: Pre-sorted results by start_time, eliminates separate sort operation
CREATE INDEX idx_schedules_date_time ON class_schedules (schedule_date, start_time);



-- TRIGGER 1: PREVENT CLASS OVERBOOKING
-- Fires BEFORE INSERT on class_bookings
-- Checks if class is already at max capacity
-- If full, automatically assigns waitlist status
CREATE OR REPLACE FUNCTION prevent_class_overbooking()
RETURNS TRIGGER AS $$
DECLARE
    v_current_capacity  INTEGER;
    v_max_capacity      INTEGER;
    v_max_waitlist_pos  INTEGER;
BEGIN
    -- Get current and max capacity for this schedule
    SELECT
        cs.current_capacity,
        c.max_capacity
    INTO
        v_current_capacity,
        v_max_capacity
    FROM class_schedules cs
    JOIN classes c ON cs.class_id = c.class_id
    WHERE cs.schedule_id = NEW.schedule_id;

    -- If class is full, put member on waitlist
    IF v_current_capacity >= v_max_capacity THEN
        -- Find next waitlist position
        SELECT COALESCE(MAX(position_in_waitlist), 0) + 1
        INTO v_max_waitlist_pos
        FROM class_bookings
        WHERE schedule_id = NEW.schedule_id
          AND status = 'waitlist';

        NEW.status               := 'waitlist';
        NEW.position_in_waitlist := v_max_waitlist_pos;

        RAISE NOTICE 'Class is full. Member added to waitlist at position %', v_max_waitlist_pos;
    ELSE
        -- Class has space: confirm booking and increment capacity
        NEW.status               := 'confirmed';
        NEW.position_in_waitlist := NULL;

        UPDATE class_schedules
        SET current_capacity = current_capacity + 1
        WHERE schedule_id = NEW.schedule_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_overbooking
    BEFORE INSERT ON class_bookings
    FOR EACH ROW
    EXECUTE FUNCTION prevent_class_overbooking();



-- TRIGGER 2: AUTO-PROMOTE WAITLIST WHEN BOOKING CANCELLED
-- Fires AFTER UPDATE on class_bookings
-- When a confirmed booking is cancelled, promotes first
-- person on waitlist to confirmed status
CREATE OR REPLACE FUNCTION promote_waitlist_on_cancel()
RETURNS TRIGGER AS $$
DECLARE
    v_next_in_waitlist  INTEGER;
    v_next_booking_id   INTEGER;
BEGIN
    -- Only fire when status changes TO 'cancelled' FROM 'confirmed'
    IF NEW.status = 'cancelled' AND OLD.status = 'confirmed' THEN

        -- Decrement the class capacity
        UPDATE class_schedules
        SET current_capacity = current_capacity - 1
        WHERE schedule_id = NEW.schedule_id;

        -- Find the first person on the waitlist
        SELECT booking_id
        INTO v_next_booking_id
        FROM class_bookings
        WHERE schedule_id = NEW.schedule_id
          AND status = 'waitlist'
        ORDER BY position_in_waitlist ASC
        LIMIT 1;

        -- If someone is waiting, promote them
        IF v_next_booking_id IS NOT NULL THEN
            UPDATE class_bookings
            SET status               = 'confirmed',
                position_in_waitlist = NULL
            WHERE booking_id = v_next_booking_id;

            -- Increment capacity again for the promoted member
            UPDATE class_schedules
            SET current_capacity = current_capacity + 1
            WHERE schedule_id = NEW.schedule_id;

            -- Shift remaining waitlist positions up by 1
            UPDATE class_bookings
            SET position_in_waitlist = position_in_waitlist - 1
            WHERE schedule_id = NEW.schedule_id
              AND status = 'waitlist'
              AND position_in_waitlist > 1;

            RAISE NOTICE 'Waitlist member (booking_id: %) promoted to confirmed', v_next_booking_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_promote_waitlist
    AFTER UPDATE ON class_bookings
    FOR EACH ROW
    EXECUTE FUNCTION promote_waitlist_on_cancel();



-- TRIGGER 3: AUTO-EXPIRE MEMBERSHIPS PAST END DATE
-- Fires BEFORE INSERT OR UPDATE on memberships
-- Automatically sets status to 'expired' if end_date has passed
CREATE OR REPLACE FUNCTION auto_expire_membership()
RETURNS TRIGGER AS $$
BEGIN
    -- If end_date is in the past and status is still 'active', expire it
    IF NEW.end_date < CURRENT_DATE AND NEW.status = 'active' THEN
        NEW.status := 'expired';
        RAISE NOTICE 'Membership % auto-expired (end_date: %)', NEW.membership_id, NEW.end_date;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_expire_membership
    BEFORE INSERT OR UPDATE ON memberships
    FOR EACH ROW
    EXECUTE FUNCTION auto_expire_membership();


-- VIEW 1: MEMBER DASHBOARD VIEW
-- Shows each member's visit count, class bookings,
-- total calories burned, and active membership info
CREATE OR REPLACE VIEW member_dashboard_view AS
SELECT
    u.user_id,
    u.first_name || ' ' || u.last_name        AS full_name,
    u.email,
    mt.tier_name                               AS membership_tier,
    m.status                                   AS membership_status,
    m.end_date                                 AS membership_expires,
    COUNT(DISTINCT a.attendance_id)            AS total_visits,
    COUNT(DISTINCT cb.booking_id)
        FILTER (WHERE cb.status = 'confirmed') AS confirmed_bookings,
    COUNT(DISTINCT cb.booking_id)
        FILTER (WHERE cb.status = 'attended')  AS attended_classes,
    COALESCE(SUM(wl.calories_burned), 0)       AS total_calories_burned,
    COUNT(DISTINCT wl.log_id)                  AS total_workout_logs
FROM users u
LEFT JOIN memberships m
    ON u.user_id = m.user_id AND m.status = 'active'
LEFT JOIN membership_tiers mt
    ON m.tier_id = mt.tier_id
LEFT JOIN attendance a
    ON u.user_id = a.user_id
LEFT JOIN class_bookings cb
    ON u.user_id = cb.user_id
LEFT JOIN workout_logs wl
    ON u.user_id = wl.user_id
WHERE u.role = 'member'
GROUP BY
    u.user_id, u.first_name, u.last_name,
    u.email, mt.tier_name, m.status, m.end_date;


-- VIEW 2: TRAINER PERFORMANCE VIEW
-- Shows trainer stats: total clients, classes conducted,
-- average rating, booking rate
CREATE OR REPLACE VIEW trainer_performance_view AS
SELECT
    t.trainer_id,
    u.first_name || ' ' || u.last_name         AS trainer_name,
    t.specialization,
    t.rating                                    AS average_rating,
    t.years_experience,
    t.hourly_rate,
    COUNT(DISTINCT wp.user_id)                  AS total_clients,
    COUNT(DISTINCT wp.plan_id)                  AS workout_plans_created,
    COUNT(DISTINCT np.nutrition_plan_id)        AS nutrition_plans_created,
    COUNT(DISTINCT cs.schedule_id)              AS classes_scheduled,
    COUNT(DISTINCT cs.schedule_id)
        FILTER (WHERE cs.status = 'completed')  AS classes_completed,
    COALESCE(AVG(cs.current_capacity * 100.0
        / NULLIF(cl.max_capacity, 0)), 0)       AS avg_class_fill_rate
FROM trainers t
JOIN users u ON t.user_id = u.user_id
LEFT JOIN workout_plans wp    ON t.trainer_id = wp.trainer_id
LEFT JOIN nutrition_plans np  ON t.trainer_id = np.trainer_id
LEFT JOIN class_schedules cs  ON t.trainer_id = cs.trainer_id
LEFT JOIN classes cl          ON cs.class_id = cl.class_id
GROUP BY
    t.trainer_id, u.first_name, u.last_name,
    t.specialization, t.rating,
    t.years_experience, t.hourly_rate;



-- VIEW 3: EQUIPMENT HEALTH REPORT VIEW
-- Shows equipment status, usage hours, maintenance history,
-- and predicted maintenance needs
CREATE OR REPLACE VIEW equipment_health_view AS
SELECT
    e.equipment_id,
    e.equipment_name,
    e.equipment_type,
    e.zone,
    e.status                                    AS current_status,
    e.total_usage_hours,
    e.last_maintenance_date,
    e.next_maintenance_due,
    CASE
        WHEN e.next_maintenance_due < CURRENT_DATE THEN 'OVERDUE'
        WHEN e.next_maintenance_due <= CURRENT_DATE + INTERVAL '7 days' THEN 'DUE SOON'
        ELSE 'OK'
    END                                         AS maintenance_alert,
    COUNT(em.maintenance_id)                    AS total_maintenance_records,
    COALESCE(SUM(em.cost), 0)                   AS total_maintenance_cost,
    MAX(em.maintenance_date)                    AS last_serviced,
    CASE
        WHEN e.total_usage_hours > 500 THEN 'HIGH USAGE'
        WHEN e.total_usage_hours > 200 THEN 'MODERATE USAGE'
        ELSE 'LOW USAGE'
    END                                         AS usage_category
FROM equipment e
LEFT JOIN equipment_maintenance em
    ON e.equipment_id = em.equipment_id
    AND em.status = 'completed'
GROUP BY
    e.equipment_id, e.equipment_name, e.equipment_type,
    e.zone, e.status, e.total_usage_hours,
    e.last_maintenance_date, e.next_maintenance_due;



-- END OF SCHEMA
-- Summary:
-- Tables  : 15
-- Indexes : 3 
-- Triggers: 3
-- Views   : 3

