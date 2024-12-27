-- First, clean up any existing rules
DELETE FROM scheduling_rules;

-- Insert the default rule for Tuesday/Monday pattern
INSERT INTO scheduling_rules (
  start_date,
  end_date,
  arrival_day,
  departure_day,
  is_blocked,
  blocked_dates,
  created_at,
  updated_at
) VALUES (
  '2025-01-07',  -- First Tuesday after special period
  '2025-12-31',  -- End of year
  'tuesday',
  'monday',
  false,
  '[]',
  now(),
  now()
);

-- Insert special period rules for December 2024
INSERT INTO scheduling_rules (
  start_date,
  end_date,
  arrival_day,
  departure_day,
  is_blocked,
  blocked_dates,
  created_at,
  updated_at
) VALUES 
-- Dec 16-22
('2024-12-16', '2024-12-22', 'monday', 'sunday', false, '[]', now(), now()),
-- Dec 23-29
('2024-12-23', '2024-12-29', 'monday', 'sunday', false, '[]', now(), now()),
-- Dec 30-Jan 5
('2024-12-30', '2025-01-05', 'monday', 'sunday', false, '[]', now(), now());