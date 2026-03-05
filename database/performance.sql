-- This file demonstrates performance improvement through
-- 3 strategic indexes using EXPLAIN ANALYZE

-- TEST 1: PAYMENT HISTORY BY USER AND DATE RANGE
-- Business Case: Generate billing reports for members
-- Index: idx_payments_user_date (composite)

-- Drop the index if it exists (to simulate "before indexing")
DROP INDEX IF EXISTS idx_payments_user_date;

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT
    p.payment_id,
    p.payment_type,
    p.amount,
    p.payment_method,
    p.payment_date,
    p.description,
    p.status
FROM payments p
WHERE p.user_id = 1
  AND p.payment_date >= '2026-01-01 00:00:00'
  AND p.payment_date <= '2026-12-31 23:59:59'
ORDER BY p.payment_date DESC;

-- Expected BEFORE results:
-- - Seq Scan on payments with Filter
-- - Planning Time: ~0.1-0.2 ms
-- - Execution Time: ~0.3-1 ms (small dataset)
-- Note: With 100,000 payments → 50-100ms


-- CREATE THE INDEX
CREATE INDEX idx_payments_user_date ON payments (user_id, payment_date);


-- AFTER INDEX
EXPLAIN ANALYZE
SELECT
    p.payment_id,
    p.payment_type,
    p.amount,
    p.payment_method,
    p.payment_date,
    p.description,
    p.status
FROM payments p
WHERE p.user_id = 1
  AND p.payment_date >= '2026-01-01 00:00:00'
  AND p.payment_date <= '2026-12-31 23:59:59'
ORDER BY p.payment_date DESC;

-- Expected AFTER results:
-- - Index Scan Backward using idx_payments_user_date
-- - Planning Time: ~0.1-0.3 ms
-- - Execution Time: ~0.1-0.5 ms
-- Note: With 100,000 payments → 2-5ms (10x-50x faster)

-- IMPROVEMENT EXPLANATION:
-- Composite index (user_id, payment_date) is optimal because:
-- 1. First filters by user_id (high selectivity)
-- 2. Then scans date range within that user's payments
-- 3. Backward index scan eliminates need for separate sort (ORDER BY DESC)
-- Real-world: 100,000 payments → 50ms becomes 2ms


-- TEST 2: ATTENDANCE LOOKUP BY TIMESTAMP
-- Business Case: Staff needs to find who checked in during
-- a specific time range for attendance verification
-- Index: idx_attendance_checkin (single-column)

-- Drop the index if it exists
DROP INDEX IF EXISTS idx_attendance_checkin;

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT
    a.attendance_id,
    u.first_name,
    u.last_name,
    u.email,
    a.check_in_time,
    a.check_out_time,
    a.duration_minutes
FROM attendance a
JOIN users u ON a.user_id = u.user_id
WHERE a.check_in_time >= '2026-02-15 00:00:00'
  AND a.check_in_time <= '2026-02-21 23:59:59'
ORDER BY a.check_in_time DESC;

-- Expected BEFORE results:
-- - Seq Scan on attendance (sequential scan through all rows)
-- - Hash Join with users table
-- - Planning Time: ~0.1-0.3 ms
-- - Execution Time: ~0.5-2 ms (small dataset)
-- Note: With 10,000+ attendance records → 50-100ms


-- CREATE THE INDEX
CREATE INDEX idx_attendance_checkin ON attendance (check_in_time);


-- AFTER INDEX
EXPLAIN ANALYZE
SELECT
    a.attendance_id,
    u.first_name,
    u.last_name,
    u.email,
    a.check_in_time,
    a.check_out_time,
    a.duration_minutes
FROM attendance a
JOIN users u ON a.user_id = u.user_id
WHERE a.check_in_time >= '2026-02-15 00:00:00'
  AND a.check_in_time <= '2026-02-21 23:59:59'
ORDER BY a.check_in_time DESC;

-- Expected AFTER results:
-- - Index Scan using idx_attendance_checkin
-- - Hash Join with users table
-- - Planning Time: ~0.2-0.4 ms
-- - Execution Time: ~0.3-1 ms
-- Note: With 10,000+ records → 5-10ms (10x faster)

-- IMPROVEMENT EXPLANATION:
-- B-tree index on check_in_time allows PostgreSQL to:
-- 1. Quickly locate rows within timestamp range
-- 2. Avoid scanning entire table
-- 3. Return pre-sorted results (matching ORDER BY)
-- Performance gain scales with table size


-- TEST 3: CLASS AVAILABILITY SEARCH BY DATE AND TIME
-- Business Case: Members search for available classes on
-- a specific date, results must be sorted by time
-- Index: idx_schedules_date_time (composite)

-- Drop the index if it exists
DROP INDEX IF EXISTS idx_schedules_date_time;

-- BEFORE INDEX
EXPLAIN ANALYZE
SELECT
    cs.schedule_id,
    c.class_name,
    c.class_type,
    c.difficulty_level,
    cs.schedule_date,
    cs.start_time,
    cs.end_time,
    cs.room_number,
    cs.current_capacity,
    c.max_capacity,
    (c.max_capacity - cs.current_capacity) AS available_spots,
    u.first_name || ' ' || u.last_name AS trainer_name
FROM class_schedules cs
JOIN classes c ON cs.class_id = c.class_id
JOIN trainers t ON cs.trainer_id = t.trainer_id
JOIN users u ON t.user_id = u.user_id
WHERE cs.schedule_date >= '2026-02-24'
  AND cs.schedule_date <= '2026-03-07'
  AND cs.status = 'scheduled'
ORDER BY cs.schedule_date, cs.start_time;

-- Expected BEFORE results:
-- - Seq Scan on class_schedules with Filter
-- - Multiple Hash Joins
-- - Sort operation for ORDER BY
-- - Planning Time: ~0.2-0.5 ms
-- - Execution Time: ~1-3 ms

-- Note: Without index, PostgreSQL must:
-- 1. Scan entire class_schedules table
-- 2. Filter by date range and status
-- 3. Join with other tables
-- 4. Sort results by date and time


-- CREATE THE INDEX
CREATE INDEX idx_schedules_date_time ON class_schedules (schedule_date, start_time);


-- AFTER INDEX
EXPLAIN ANALYZE
SELECT
    cs.schedule_id,
    c.class_name,
    c.class_type,
    c.difficulty_level,
    cs.schedule_date,
    cs.start_time,
    cs.end_time,
    cs.room_number,
    cs.current_capacity,
    c.max_capacity,
    (c.max_capacity - cs.current_capacity) AS available_spots,
    u.first_name || ' ' || u.last_name AS trainer_name
FROM class_schedules cs
JOIN classes c ON cs.class_id = c.class_id
JOIN trainers t ON cs.trainer_id = t.trainer_id
JOIN users u ON t.user_id = u.user_id
WHERE cs.schedule_date >= '2026-02-24'
  AND cs.schedule_date <= '2026-03-07'
  AND cs.status = 'scheduled'
ORDER BY cs.schedule_date, cs.start_time;

-- Expected AFTER results:
-- - Index Scan using idx_schedules_date_time
-- - Hash Joins (same as before)
-- - NO Sort operation (results already sorted by index)
-- - Planning Time: ~0.2-0.6 ms
-- - Execution Time: ~0.5-2 ms

-- Note: With index, PostgreSQL:
-- 1. Uses index to quickly find date range
-- 2. Results already sorted by (schedule_date, start_time)
-- 3. Eliminates separate sort operation
-- 4. Significantly faster with larger datasets

-- IMPROVEMENT EXPLANATION:
-- Composite index on (schedule_date, start_time) serves dual purpose:
-- 1. Quickly filters rows by date range (WHERE clause)
-- 2. Pre-sorts results by start_time (ORDER BY clause)
-- This is especially powerful for date-range queries with time sorting
-- The sort operation cost is eliminated entirely


