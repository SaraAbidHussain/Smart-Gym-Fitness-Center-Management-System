-- SMART GYM MANAGEMENT SYSTEM
-- seed.sql - Test Data (100+ records)

-- SEED 1: USERS (20 users - 4 roles)
INSERT INTO users (email, password_hash, first_name, last_name, phone, role, date_of_birth, gender, is_active) VALUES
-- Members (12)
('ahmed.khan@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Ahmed', 'Khan', '0300-1234567', 'member', '1995-03-15', 'male', TRUE),
('fatima.ali@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Fatima', 'Ali', '0301-2345678', 'member', '1998-07-22', 'female', TRUE),
('bilal.ahmed@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Bilal', 'Ahmed', '0302-3456789', 'member', '1992-11-10', 'male', TRUE),
('ayesha.malik@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Ayesha', 'Malik', '0303-4567890', 'member', '2000-05-18', 'female', TRUE),
('usman.tariq@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Usman', 'Tariq', '0304-5678901', 'member', '1990-09-25', 'male', TRUE),
('zainab.hassan@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Zainab', 'Hassan', '0305-6789012', 'member', '1997-01-30', 'female', TRUE),
('hamza.raza@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Hamza', 'Raza', '0306-7890123', 'member', '1994-12-05', 'male', TRUE),
('sana.shah@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Sana', 'Shah', '0307-8901234', 'member', '1999-04-12', 'female', TRUE),
('imran.qureshi@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Imran', 'Qureshi', '0308-9012345', 'member', '1991-08-20', 'male', TRUE),
('maria.farooq@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Maria', 'Farooq', '0309-0123456', 'member', '1996-02-28', 'female', TRUE),
('ali.rauf@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Ali', 'Rauf', '0310-1234567', 'member', '1993-06-14', 'male', TRUE),
('hira.iqbal@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Hira', 'Iqbal', '0311-2345678', 'member', '2001-10-08', 'female', TRUE),

-- Trainers (5)
('coach.ali@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Ali', 'Rehman', '0321-1111111', 'trainer', '1988-03-10', 'male', TRUE),
('coach.sara@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Sara', 'Nadeem', '0321-2222222', 'trainer', '1990-07-15', 'female', TRUE),
('coach.kamran@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Kamran', 'Abbas', '0321-3333333', 'trainer', '1985-11-20', 'male', TRUE),
('coach.nida@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Nida', 'Khan', '0321-4444444', 'trainer', '1992-05-25', 'female', TRUE),
('coach.faisal@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Faisal', 'Aziz', '0321-5555555', 'trainer', '1987-09-30', 'male', TRUE),

-- Staff (2)
('staff.hassan@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Hassan', 'Butt', '0331-1111111', 'staff', '1995-01-12', 'male', TRUE),
('staff.amna@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Amna', 'Saeed', '0331-2222222', 'staff', '1998-06-18', 'female', TRUE),

-- Admin (1)
('admin@smartgym.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIxnE6', 'Admin', 'User', '0300-0000000', 'admin', '1980-01-01', 'male', TRUE);


-- SEED 2: MEMBERSHIP TIERS (3 tiers)
INSERT INTO membership_tiers (tier_name, monthly_fee, access_sauna, access_pool, access_premium_zone, max_classes_per_month, description) VALUES
('Basic', 5000.00, FALSE, FALSE, FALSE, 4, 'Entry-level membership with gym access and 4 classes per month'),
('Premium', 8000.00, TRUE, TRUE, FALSE, 8, 'Includes sauna, pool access, and 8 classes per month'),
('VIP', 12000.00, TRUE, TRUE, TRUE, 999, 'Unlimited classes, all facilities, premium zone access');


-- SEED 3: MEMBERSHIPS (18 memberships)
INSERT INTO memberships (user_id, tier_id, start_date, end_date, is_frozen, status, auto_renew) VALUES
-- Active memberships
(1, 2, '2026-01-01', '2026-12-31', FALSE, 'active', TRUE),
(2, 3, '2026-02-01', '2027-01-31', FALSE, 'active', TRUE),
(3, 1, '2025-12-15', '2026-11-15', FALSE, 'active', TRUE),
(4, 2, '2026-01-10', '2027-01-10', FALSE, 'active', TRUE),
(5, 1, '2026-02-01', '2027-01-31', FALSE, 'active', TRUE),
(6, 3, '2025-11-01', '2026-10-31', FALSE, 'active', TRUE),
(7, 2, '2026-01-15', '2027-01-15', FALSE, 'active', TRUE),
(8, 1, '2026-02-10', '2027-02-10', FALSE, 'active', TRUE),
(9, 2, '2025-12-01', '2026-11-30', FALSE, 'active', TRUE),
(10, 3, '2026-01-20', '2027-01-20', FALSE, 'active', TRUE),
(11, 1, '2026-02-05', '2027-02-05', FALSE, 'active', TRUE),
(12, 2, '2026-01-25', '2027-01-25', FALSE, 'active', TRUE),

-- Frozen memberships
(1, 1, '2025-06-01', '2026-05-31', TRUE, 'frozen', TRUE),
(3, 2, '2025-08-01', '2026-07-31', TRUE, 'frozen', TRUE),

-- Expired memberships
(5, 3, '2024-01-01', '2024-12-31', FALSE, 'expired', FALSE),
(7, 1, '2024-06-01', '2025-05-31', FALSE, 'expired', FALSE),
(9, 2, '2023-12-01', '2024-11-30', FALSE, 'expired', FALSE),
(11, 1, '2024-03-01', '2025-02-28', FALSE, 'expired', FALSE);


-- SEED 4: TRAINERS (5 trainers)
INSERT INTO trainers (user_id, specialization, certification, hourly_rate, years_experience, bio, is_available, rating) VALUES
(13, 'Weight Loss, Cardio', 'NASM Certified Personal Trainer', 2000.00, 8, 'Specialized in helping clients lose weight through customized cardio programs.', TRUE, 4.8),
(14, 'Yoga, Flexibility', 'RYT-500 Yoga Alliance', 1800.00, 6, 'Expert in Hatha and Vinyasa yoga, flexibility training.', TRUE, 4.9),
(15, 'Strength Training, Bodybuilding', 'ACE Certified, IFBB Pro', 2500.00, 12, 'Competitive bodybuilder with 12 years of training experience.', TRUE, 4.7),
(16, 'CrossFit, HIIT', 'CrossFit Level 2 Trainer', 2200.00, 5, 'High-intensity interval training and functional fitness specialist.', TRUE, 4.6),
(17, 'Nutrition, Muscle Gain', 'Precision Nutrition Level 1', 2300.00, 10, 'Certified nutritionist focusing on muscle gain and athletic performance.', TRUE, 4.9);

-- SEED 5: CLASSES (6 class types)
INSERT INTO classes (class_name, description, class_type, duration_minutes, difficulty_level, max_capacity) VALUES
('Morning Yoga', 'Relaxing yoga session to start your day', 'Mind & Body', 60, 'beginner', 15),
('HIIT Blast', 'High-intensity interval training for fat loss', 'Cardio', 45, 'advanced', 20),
('Zumba Dance', 'Fun Latin-inspired dance workout', 'Cardio', 50, 'intermediate', 25),
('CrossFit WOD', 'Workout of the Day - functional fitness', 'Strength', 60, 'advanced', 12),
('Spin Cycle', 'Indoor cycling with motivating music', 'Cardio', 45, 'intermediate', 18),
('Beginner Strength', 'Introduction to weight training', 'Strength', 60, 'beginner', 10);

-- SEED 6: CLASS SCHEDULES (15 scheduled classes)
INSERT INTO class_schedules (class_id, trainer_id, schedule_date, start_time, end_time, room_number, current_capacity, status) VALUES
-- Week 1 (Feb 24-28, 2026)
(1, 2, '2026-02-24', '06:00:00', '07:00:00', 'Studio A', 0, 'scheduled'),
(2, 4, '2026-02-24', '18:00:00', '18:45:00', 'Studio B', 0, 'scheduled'),
(3, 2, '2026-02-25', '19:00:00', '19:50:00', 'Studio A', 0, 'scheduled'),
(4, 3, '2026-02-26', '17:00:00', '18:00:00', 'Functional Zone', 0, 'scheduled'),
(5, 4, '2026-02-27', '18:30:00', '19:15:00', 'Spin Room', 0, 'scheduled'),
(6, 1, '2026-02-28', '10:00:00', '11:00:00', 'Studio C', 0, 'scheduled'),

-- Week 2 (Mar 3-7, 2026)
(1, 2, '2026-03-03', '06:00:00', '07:00:00', 'Studio A', 0, 'scheduled'),
(2, 4, '2026-03-03', '18:00:00', '18:45:00', 'Studio B', 0, 'scheduled'),
(3, 2, '2026-03-04', '19:00:00', '19:50:00', 'Studio A', 0, 'scheduled'),
(4, 3, '2026-03-05', '17:00:00', '18:00:00', 'Functional Zone', 0, 'scheduled'),
(5, 4, '2026-03-06', '18:30:00', '19:15:00', 'Spin Room', 0, 'scheduled'),
(6, 1, '2026-03-07', '10:00:00', '11:00:00', 'Studio C', 0, 'scheduled'),

-- Past completed classes
(1, 2, '2026-02-17', '06:00:00', '07:00:00', 'Studio A', 12, 'completed'),
(2, 4, '2026-02-18', '18:00:00', '18:45:00', 'Studio B', 18, 'completed'),
(3, 2, '2026-02-19', '19:00:00', '19:50:00', 'Studio A', 22, 'completed');

-- SEED 7: CLASS BOOKINGS (30 bookings)
INSERT INTO class_bookings (schedule_id, user_id, booking_date, status, position_in_waitlist) VALUES
-- Upcoming classes
(1, 1, '2026-02-20 10:00:00', 'confirmed', NULL),
(1, 2, '2026-02-20 11:00:00', 'confirmed', NULL),
(1, 3, '2026-02-20 12:00:00', 'confirmed', NULL),
(2, 4, '2026-02-20 13:00:00', 'confirmed', NULL),
(2, 5, '2026-02-20 14:00:00', 'confirmed', NULL),
(3, 6, '2026-02-21 09:00:00', 'confirmed', NULL),
(3, 7, '2026-02-21 10:00:00', 'confirmed', NULL),
(4, 8, '2026-02-21 11:00:00', 'confirmed', NULL),
(4, 9, '2026-02-21 12:00:00', 'confirmed', NULL),
(5, 10, '2026-02-21 13:00:00', 'confirmed', NULL),

-- More upcoming bookings
(7, 1, '2026-02-22 10:00:00', 'confirmed', NULL),
(7, 4, '2026-02-22 11:00:00', 'confirmed', NULL),
(8, 2, '2026-02-22 12:00:00', 'confirmed', NULL),
(8, 5, '2026-02-22 13:00:00', 'confirmed', NULL),
(9, 3, '2026-02-22 14:00:00', 'confirmed', NULL),

-- Past attended classes
(13, 1, '2026-02-15 08:00:00', 'attended', NULL),
(13, 2, '2026-02-15 09:00:00', 'attended', NULL),
(13, 3, '2026-02-15 10:00:00', 'attended', NULL),
(13, 4, '2026-02-15 11:00:00', 'attended', NULL),
(13, 5, '2026-02-15 12:00:00', 'attended', NULL),
(14, 6, '2026-02-16 08:00:00', 'attended', NULL),
(14, 7, '2026-02-16 09:00:00', 'attended', NULL),
(14, 8, '2026-02-16 10:00:00', 'attended', NULL),
(15, 9, '2026-02-17 08:00:00', 'attended', NULL),
(15, 10, '2026-02-17 09:00:00', 'attended', NULL),

-- Cancelled bookings
(1, 11, '2026-02-20 15:00:00', 'cancelled', NULL),
(2, 12, '2026-02-20 16:00:00', 'cancelled', NULL),

-- Waitlist
(4, 1, '2026-02-21 14:00:00', 'waitlist', 1),
(4, 2, '2026-02-21 15:00:00', 'waitlist', 2),
(5, 3, '2026-02-21 16:00:00', 'waitlist', 1),
(5, 4, '2026-02-21 17:00:00', 'waitlist', 2);

-- SEED 8: WORKOUT PLANS (10 plans)
INSERT INTO workout_plans (user_id, trainer_id, plan_name, description, goal, start_date, end_date, is_active) VALUES
(1, 1, 'Fat Loss Program', '12-week program focusing on cardio and calorie deficit', 'Weight Loss', '2026-01-01', '2026-03-31', TRUE),
(2, 2, 'Flexibility & Balance', '8-week yoga-based flexibility improvement', 'Flexibility', '2026-02-01', '2026-03-31', TRUE),
(3, 3, 'Beginner Strength', 'Introduction to compound lifts and progressive overload', 'Muscle Gain', '2026-01-15', '2026-04-15', TRUE),
(4, 4, 'CrossFit Fundamentals', '6-week functional fitness foundation', 'General Fitness', '2026-02-10', '2026-03-25', TRUE),
(5, 5, 'Lean Bulk Plan', 'Muscle building with minimal fat gain', 'Muscle Gain', '2026-01-20', '2026-04-20', TRUE),
(6, 1, 'Cardio Endurance', 'Marathon training preparation', 'Endurance', '2026-02-01', '2026-05-01', TRUE),
(7, 3, 'Powerlifting Basics', 'Focus on squat, bench, deadlift', 'Strength', '2026-01-10', '2026-04-10', TRUE),
(8, 2, 'Advanced Yoga Flow', 'Challenging yoga sequences', 'Flexibility', '2026-02-15', '2026-04-15', TRUE),
(9, 4, 'HIIT Fat Shredder', 'High-intensity fat loss protocol', 'Weight Loss', '2026-01-25', '2026-03-25', TRUE),
(10, 5, 'Athletic Performance', 'Sport-specific strength and conditioning', 'Performance', '2026-02-05', '2026-05-05', TRUE);

-- SEED 9: WORKOUT LOGS (40 logs)
INSERT INTO workout_logs (user_id, plan_id, workout_date, exercise_name, muscle_group, sets, reps, weight_kg, duration_minutes, calories_burned, difficulty, notes) VALUES
-- User 1 logs
(1, 1, '2026-02-15', 'Treadmill Run', 'Cardio', NULL, NULL, NULL, 30, 350, 'moderate', 'Good pace maintained'),
(1, 1, '2026-02-16', 'Cycling', 'Cardio', NULL, NULL, NULL, 45, 400, 'moderate', 'Interval training'),
(1, 1, '2026-02-17', 'Jump Rope', 'Cardio', NULL, NULL, NULL, 20, 250, 'hard', 'Very intense'),
(1, 1, '2026-02-18', 'Elliptical', 'Cardio', NULL, NULL, NULL, 35, 320, 'easy', 'Recovery day'),

-- User 2 logs
(2, 2, '2026-02-15', 'Vinyasa Flow', 'Full Body', NULL, NULL, NULL, 60, 200, 'moderate', 'Felt great'),
(2, 2, '2026-02-17', 'Hatha Yoga', 'Full Body', NULL, NULL, NULL, 60, 180, 'easy', 'Relaxing session'),
(2, 2, '2026-02-19', 'Power Yoga', 'Full Body', NULL, NULL, NULL, 60, 250, 'hard', 'Challenging poses'),

-- User 3 logs (Strength training)
(3, 3, '2026-02-15', 'Bench Press', 'Chest', 3, 8, 60.0, NULL, 150, 'moderate', 'Form improving'),
(3, 3, '2026-02-15', 'Squats', 'Legs', 4, 10, 80.0, NULL, 180, 'hard', 'New PR!'),
(3, 3, '2026-02-17', 'Deadlift', 'Back', 3, 6, 100.0, NULL, 200, 'hard', 'Good form'),
(3, 3, '2026-02-17', 'Overhead Press', 'Shoulders', 3, 8, 40.0, NULL, 120, 'moderate', NULL),
(3, 3, '2026-02-19', 'Barbell Rows', 'Back', 4, 8, 70.0, NULL, 160, 'moderate', 'Great pump'),

-- User 4 logs
(4, 4, '2026-02-16', 'Burpees', 'Full Body', 5, 15, NULL, NULL, 250, 'hard', 'Exhausting!'),
(4, 4, '2026-02-18', 'Box Jumps', 'Legs', 4, 12, NULL, NULL, 180, 'moderate', NULL),
(4, 4, '2026-02-20', 'Wall Balls', 'Full Body', 5, 20, 9.0, NULL, 220, 'hard', 'Tough workout'),

-- User 5 logs
(5, 5, '2026-02-15', 'Incline Dumbbell Press', 'Chest', 4, 10, 30.0, NULL, 160, 'moderate', NULL),
(5, 5, '2026-02-15', 'Leg Press', 'Legs', 4, 12, 150.0, NULL, 200, 'hard', 'Heavy weight'),
(5, 5, '2026-02-17', 'Pull-ups', 'Back', 4, 8, NULL, NULL, 140, 'hard', 'Added weight'),
(5, 5, '2026-02-19', 'Dumbbell Curls', 'Arms', 3, 12, 15.0, NULL, 100, 'easy', NULL),

-- User 6 logs
(6, 6, '2026-02-16', 'Long Run', 'Cardio', NULL, NULL, NULL, 90, 800, 'moderate', '15km completed'),
(6, 6, '2026-02-18', 'Tempo Run', 'Cardio', NULL, NULL, NULL, 45, 500, 'hard', 'Fast pace'),
(6, 6, '2026-02-20', 'Easy Jog', 'Cardio', NULL, NULL, NULL, 30, 300, 'easy', 'Recovery run'),

-- User 7 logs
(7, 7, '2026-02-15', 'Back Squat', 'Legs', 5, 5, 120.0, NULL, 220, 'hard', 'Heavy day'),
(7, 7, '2026-02-17', 'Bench Press', 'Chest', 5, 5, 90.0, NULL, 180, 'hard', 'Strong session'),
(7, 7, '2026-02-19', 'Deadlift', 'Back', 5, 3, 140.0, NULL, 250, 'hard', 'New max!'),

-- User 8 logs
(8, 8, '2026-02-16', 'Ashtanga Series', 'Full Body', NULL, NULL, NULL, 90, 300, 'hard', 'Advanced practice'),
(8, 8, '2026-02-18', 'Yin Yoga', 'Full Body', NULL, NULL, NULL, 60, 120, 'easy', 'Deep stretches'),

-- User 9 logs
(9, 9, '2026-02-15', 'Sprint Intervals', 'Cardio', 10, NULL, NULL, 20, 400, 'hard', 'Max effort'),
(9, 9, '2026-02-17', 'Battle Ropes', 'Full Body', 8, 30, NULL, 15, 250, 'hard', 'Shoulder burn'),
(9, 9, '2026-02-19', 'Mountain Climbers', 'Full Body', 5, 20, NULL, 10, 180, 'moderate', NULL),

-- User 10 logs
(10, 10, '2026-02-16', 'Plyometric Jumps', 'Legs', 5, 10, NULL, NULL, 200, 'hard', 'Explosive power'),
(10, 10, '2026-02-18', 'Medicine Ball Slams', 'Full Body', 4, 15, 10.0, NULL, 180, 'moderate', NULL),
(10, 10, '2026-02-20', 'Agility Ladder Drills', 'Legs', NULL, NULL, NULL, 20, 150, 'moderate', 'Speed work'),

-- Random additional logs
(1, 1, '2026-02-19', 'Swimming', 'Cardio', NULL, NULL, NULL, 40, 380, 'moderate', 'Pool session'),
(2, 2, '2026-02-20', 'Stretching', 'Full Body', NULL, NULL, NULL, 30, 80, 'easy', 'Cooldown'),
(3, 3, '2026-02-20', 'Lunges', 'Legs', 3, 12, 20.0, NULL, 140, 'moderate', 'Dumbbell lunges'),
(4, 4, '2026-02-19', 'Kettlebell Swings', 'Full Body', 5, 20, 20.0, NULL, 200, 'hard', 'Great for cardio'),
(5, 5, '2026-02-20', 'Tricep Dips', 'Arms', 4, 12, NULL, NULL, 100, 'moderate', 'Bodyweight'),
(6, 6, '2026-02-19', 'Hill Sprints', 'Cardio', 8, NULL, NULL, 25, 350, 'hard', 'Leg burner');

-- SEED 10: EQUIPMENT (15 items)
INSERT INTO equipment (equipment_name, equipment_type, zone, purchase_date, purchase_cost, manufacturer, model_number, status, total_usage_hours, last_maintenance_date, next_maintenance_due) VALUES
('Treadmill 01', 'Cardio', 'Cardio Zone', '2024-01-15', 150000.00, 'Life Fitness', 'T5-GO', 'available', 450, '2026-01-10', '2026-03-10'),
('Treadmill 02', 'Cardio', 'Cardio Zone', '2024-01-15', 150000.00, 'Life Fitness', 'T5-GO', 'available', 380, '2026-01-10', '2026-03-10'),
('Treadmill 03', 'Cardio', 'Cardio Zone', '2024-01-15', 150000.00, 'Life Fitness', 'T5-GO', 'maintenance', 520, '2026-02-15', '2026-04-15'),
('Stationary Bike 01', 'Cardio', 'Cardio Zone', '2024-02-01', 80000.00, 'Schwinn', 'IC4', 'available', 310, '2026-01-20', '2026-03-20'),
('Elliptical 01', 'Cardio', 'Cardio Zone', '2024-02-10', 120000.00, 'Precor', 'EFX-885', 'available', 290, '2026-01-25', '2026-03-25'),
('Rowing Machine 01', 'Cardio', 'Cardio Zone', '2024-03-01', 95000.00, 'Concept2', 'Model D', 'available', 180, '2026-02-01', '2026-04-01'),
('Squat Rack 01', 'Strength', 'Strength Zone', '2023-12-01', 180000.00, 'Rogue Fitness', 'R-3', 'available', 680, '2026-01-05', '2026-03-05'),
('Squat Rack 02', 'Strength', 'Strength Zone', '2023-12-01', 180000.00, 'Rogue Fitness', 'R-3', 'available', 620, '2026-01-05', '2026-03-05'),
('Bench Press 01', 'Strength', 'Strength Zone', '2023-12-15', 85000.00, 'Rogue Fitness', 'Flat Bench', 'available', 540, '2026-01-15', '2026-03-15'),
('Cable Machine 01', 'Strength', 'Strength Zone', '2024-01-20', 220000.00, 'Life Fitness', 'Signature Series', 'available', 410, '2026-02-05', '2026-04-05'),
('Leg Press 01', 'Strength', 'Strength Zone', '2024-02-15', 190000.00, 'Hammer Strength', 'Plate Loaded', 'available', 360, '2026-02-10', '2026-04-10'),
('Dumbbell Set', 'Strength', 'Free Weights Zone', '2023-11-01', 250000.00, 'York Barbell', '5-50kg Set', 'available', 850, '2025-12-20', '2026-02-20'),
('Kettlebell Set', 'Functional', 'Functional Training Zone', '2024-01-10', 120000.00, 'Rogue Fitness', '8-32kg Set', 'available', 280, '2026-02-01', '2026-04-01'),
('Battle Ropes', 'Functional', 'Functional Training Zone', '2024-03-01', 25000.00, 'Titan Fitness', '15m Heavy', 'available', 95, '2026-02-15', '2026-04-15'),
('Pull-up Bar Station', 'Functional', 'Functional Training Zone', '2023-12-20', 95000.00, 'Rogue Fitness', 'Rig Mounted', 'available', 430, '2026-01-20', '2026-03-20');

-- SEED 11: EQUIPMENT MAINTENANCE (10 records)
INSERT INTO equipment_maintenance (equipment_id, maintenance_date, maintenance_type, description, technician_name, cost, status) VALUES
(1, '2026-01-10', 'routine', 'Belt lubrication and calibration', 'Tech Ahmed', 5000.00, 'completed'),
(2, '2026-01-10', 'routine', 'Belt lubrication and calibration', 'Tech Ahmed', 5000.00, 'completed'),
(3, '2026-02-15', 'repair', 'Motor replacement', 'Tech Bilal', 35000.00, 'completed'),
(4, '2026-01-20', 'routine', 'Chain lubrication, seat adjustment', 'Tech Hassan', 3000.00, 'completed'),
(5, '2026-01-25', 'inspection', 'General safety inspection', 'Tech Ahmed', 2000.00, 'completed'),
(6, '2026-02-01', 'routine', 'Chain tension adjustment', 'Tech Bilal', 2500.00, 'completed'),
(7, '2026-01-05', 'routine', 'J-hooks inspection, bar maintenance', 'Tech Hassan', 4000.00, 'completed'),
(8, '2026-01-05', 'routine', 'J-hooks inspection, bar maintenance', 'Tech Hassan', 4000.00, 'completed'),
(9, '2026-01-15', 'routine', 'Upholstery repair, bench stability check', 'Tech Ahmed', 3500.00, 'completed'),
(10, '2026-02-05', 'repair', 'Cable replacement', 'Tech Bilal', 12000.00, 'completed');

-- SEED 12: LOCKERS (15 lockers)
INSERT INTO lockers (locker_number, locker_size, location, status, current_user_id, assigned_at) VALUES
('A01', 'small', 'Men Changing Room', 'available', NULL, NULL),
('A02', 'small', 'Men Changing Room', 'available', NULL, NULL),
('A03', 'medium', 'Men Changing Room', 'available', NULL, NULL),
('A04', 'medium', 'Men Changing Room', 'available', NULL, NULL),
('A05', 'large', 'Men Changing Room', 'available', NULL, NULL),
('B01', 'small', 'Women Changing Room', 'available', NULL, NULL),
('B02', 'small', 'Women Changing Room', 'available', NULL, NULL),
('B03', 'medium', 'Women Changing Room', 'available', NULL, NULL),
('B04', 'medium', 'Women Changing Room', 'available', NULL, NULL),
('B05', 'large', 'Women Changing Room', 'available', NULL, NULL),
('C01', 'medium', 'VIP Lounge', 'available', NULL, NULL),
('C02', 'large', 'VIP Lounge', 'available', NULL, NULL),
('C03', 'large', 'VIP Lounge', 'available', NULL, NULL),
('M01', 'small', 'Staff Room', 'maintenance', NULL, NULL),
('M02', 'medium', 'Staff Room', 'available', NULL, NULL);

-- SEED 13: ATTENDANCE (25 records)
INSERT INTO attendance (user_id, check_in_time, check_out_time, duration_minutes, locker_assigned, access_areas) VALUES
-- Completed sessions
(1, '2026-02-15 06:30:00', '2026-02-15 08:00:00', 90, 1, '["Cardio Zone", "Locker Room"]'),
(2, '2026-02-15 07:00:00', '2026-02-15 08:30:00', 90, 6, '["Studio A", "Pool", "Locker Room"]'),
(3, '2026-02-15 17:00:00', '2026-02-15 19:00:00', 120, 2, '["Strength Zone", "Locker Room"]'),
(4, '2026-02-16 06:00:00', '2026-02-16 07:30:00', 90, 7, '["Studio A", "Locker Room"]'),
(5, '2026-02-16 18:00:00', '2026-02-16 19:15:00', 75, 3, '["Cardio Zone", "Locker Room"]'),
(6, '2026-02-17 07:30:00', '2026-02-17 09:30:00', 120, 8, '["Pool", "Sauna", "Locker Room"]'),
(7, '2026-02-17 17:30:00', '2026-02-17 19:00:00', 90, 4, '["Strength Zone", "Locker Room"]'),
(8, '2026-02-18 06:30:00', '2026-02-18 08:00:00', 90, 9, '["Studio A", "Locker Room"]'),
(9, '2026-02-18 18:00:00', '2026-02-18 19:30:00', 90, 5, '["Functional Zone", "Locker Room"]'),
(10, '2026-02-19 07:00:00', '2026-02-19 09:00:00', 120, 10, '["Pool", "Premium Zone", "Locker Room"]'),
(1, '2026-02-19 17:00:00', '2026-02-19 18:30:00', 90, 1, '["Cardio Zone", "Locker Room"]'),
(2, '2026-02-19 18:30:00', '2026-02-19 20:00:00', 90, 6, '["Studio A", "Locker Room"]'),
(3, '2026-02-20 06:00:00', '2026-02-20 07:30:00', 90, 2, '["Strength Zone", "Locker Room"]'),
(4, '2026-02-20 17:00:00', '2026-02-20 18:30:00', 90, 7, '["Functional Zone", "Locker Room"]'),
(5, '2026-02-20 18:00:00', '2026-02-20 19:15:00', 75, 3, '["Cardio Zone", "Locker Room"]'),

-- Currently active sessions (still checked in)
(6, '2026-02-21 07:00:00', NULL, NULL, 8, '["Pool", "Sauna"]'),
(7, '2026-02-21 06:30:00', NULL, NULL, 4, '["Strength Zone"]'),
(8, '2026-02-21 17:00:00', NULL, NULL, 9, '["Studio A"]'),
(9, '2026-02-21 18:00:00', NULL, NULL, 5, '["Cardio Zone"]'),
(10, '2026-02-21 18:30:00', NULL, NULL, 10, '["Premium Zone"]'),

-- More past sessions
(11, '2026-02-17 08:00:00', '2026-02-17 09:00:00', 60, 11, '["Cardio Zone", "VIP Lounge"]'),
(12, '2026-02-18 19:00:00', '2026-02-18 20:30:00', 90, 12, '["Pool", "Sauna", "VIP Lounge"]'),
(11, '2026-02-19 07:30:00', '2026-02-19 08:45:00', 75, 11, '["Strength Zone", "VIP Lounge"]'),
(12, '2026-02-20 18:00:00', '2026-02-20 19:30:00', 90, 12, '["Cardio Zone", "VIP Lounge"]'),
(1, '2026-02-16 17:00:00', '2026-02-16 18:15:00', 75, 1, '["Pool", "Locker Room"]');

-- SEED 14: PAYMENTS (20 records)
INSERT INTO payments (user_id, payment_type, amount, payment_method, payment_date, reference_id, description, status) VALUES
-- Membership payments
(1, 'membership', 8000.00, 'credit_card', '2026-01-01 10:00:00', 1, 'Premium membership - Jan 2026', 'completed'),
(2, 'membership', 12000.00, 'online', '2026-02-01 11:00:00', 2, 'VIP membership - Feb 2026', 'completed'),
(3, 'membership', 5000.00, 'debit_card', '2025-12-15 09:30:00', 3, 'Basic membership - Dec 2025', 'completed'),
(4, 'membership', 8000.00, 'credit_card', '2026-01-10 14:00:00', 4, 'Premium membership - Jan 2026', 'completed'),
(5, 'membership', 5000.00, 'cash', '2026-02-01 10:30:00', 5, 'Basic membership - Feb 2026', 'completed'),
(6, 'membership', 12000.00, 'online', '2025-11-01 12:00:00', 6, 'VIP membership - Nov 2025', 'completed'),
(7, 'membership', 8000.00, 'credit_card', '2026-01-15 15:30:00', 7, 'Premium membership - Jan 2026', 'completed'),
(8, 'membership', 5000.00, 'debit_card', '2026-02-10 11:00:00', 8, 'Basic membership - Feb 2026', 'completed'),

-- Training session payments
(1, 'training_session', 2000.00, 'credit_card', '2026-02-10 16:00:00', NULL, '1-hour PT with Coach Ali', 'completed'),
(2, 'training_session', 1800.00, 'online', '2026-02-12 17:00:00', NULL, '1-hour Yoga with Coach Sara', 'completed'),
(3, 'training_session', 2500.00, 'credit_card', '2026-02-14 18:00:00', NULL, '1-hour Strength with Coach Kamran', 'completed'),
(4, 'training_session', 2200.00, 'debit_card', '2026-02-16 10:00:00', NULL, '1-hour CrossFit with Coach Nida', 'completed'),

-- Product sales
(5, 'product', 3500.00, 'cash', '2026-02-11 12:00:00', NULL, 'Whey Protein 2kg', 'completed'),
(6, 'product', 1500.00, 'credit_card', '2026-02-13 14:00:00', NULL, 'Gym Gloves + Shaker', 'completed'),
(7, 'product', 2800.00, 'online', '2026-02-15 11:30:00', NULL, 'Pre-workout + BCAA', 'completed'),

-- Late fees
(3, 'late_fee', 500.00, 'cash', '2026-02-18 09:00:00', 3, 'Late payment penalty', 'completed'),
(5, 'late_fee', 300.00, 'debit_card', '2026-02-19 10:00:00', 5, 'Overdue locker fee', 'completed'),

-- Pending payment
(8, 'training_session', 1800.00, 'online', '2026-02-20 16:00:00', NULL, 'PT session scheduled for Feb 25', 'pending'),

-- Refunded payment
(9, 'membership', 8000.00, 'credit_card', '2026-02-05 12:00:00', 9, 'Premium membership - Refunded due to injury', 'refunded'),

-- Failed payment
(10, 'product', 2000.00, 'credit_card', '2026-02-17 15:00:00', NULL, 'Protein powder - Card declined', 'failed');

-- SEED 15: NUTRITION PLANS (8 plans)
INSERT INTO nutrition_plans (user_id, trainer_id, plan_name, daily_calories_target, protein_grams, carbs_grams, fats_grams, meals_plan, start_date, end_date, is_active) VALUES
(1, 5, 'Fat Loss Nutrition', 1800, 140, 150, 50, 'Meal 1: Egg whites, oats | Meal 2: Chicken, rice, veggies | Meal 3: Fish, sweet potato | Snack: Protein shake', '2026-01-01', '2026-03-31', TRUE),
(2, 5, 'Balanced Diet', 2000, 100, 200, 70, 'Meal 1: Greek yogurt, fruits | Meal 2: Grilled chicken, quinoa | Meal 3: Salmon, brown rice | Snack: Nuts', '2026-02-01', '2026-03-31', TRUE),
(3, 5, 'Muscle Gain Plan', 2800, 180, 300, 90, 'Meal 1: Whole eggs, oats, banana | Meal 2: Beef, rice, veggies | Meal 3: Chicken, pasta | Meal 4: Fish, potatoes | Shake: Post-workout protein', '2026-01-15', '2026-04-15', TRUE),
(5, 5, 'Lean Bulk Nutrition', 2600, 170, 280, 85, 'Meal 1: Egg whites, oats | Meal 2: Turkey, rice | Meal 3: Chicken breast, sweet potato | Meal 4: Fish, veggies | Shake: Casein before bed', '2026-01-20', '2026-04-20', TRUE),
(7, 5, 'Powerlifting Diet', 3200, 200, 350, 110, 'Meal 1: Whole eggs, pancakes | Meal 2: Steak, rice | Meal 3: Pasta, meat sauce | Meal 4: Salmon, potatoes | Shake: Intra-workout carbs', '2026-01-10', '2026-04-10', TRUE),
(9, 5, 'HIIT Fat Loss Diet', 1700, 130, 140, 45, 'Meal 1: Protein shake, banana | Meal 2: Tuna, salad | Meal 3: Chicken, veggies | Snack: Low-fat cottage cheese', '2026-01-25', '2026-03-25', TRUE),
(10, 5, 'Athletic Performance', 2500, 150, 280, 75, 'Meal 1: Oats, protein | Meal 2: Chicken, rice, veggies | Meal 3: Fish, quinoa | Snack: Fruit, nuts | Shake: Post-training', '2026-02-05', '2026-05-05', TRUE),
(4, 5, 'CrossFit Nutrition', 2400, 160, 240, 80, 'Meal 1: Eggs, sweet potato | Meal 2: Ground turkey, rice | Meal 3: Chicken thighs, pasta | Snack: Greek yogurt | Shake: Post-WOD', '2026-02-10', '2026-03-25', TRUE);

-- END OF SEED DATA
-- Total Records: 240+
-- Users: 20 | Membership Tiers: 3 | Memberships: 18
-- Trainers: 5 | Classes: 6 | Class Schedules: 15
-- Class Bookings: 30 | Workout Plans: 10 | Workout Logs: 40
-- Equipment: 15 | Equipment Maintenance: 10
-- Lockers: 15 | Attendance: 25 | Payments: 20
-- Nutrition Plans: 8