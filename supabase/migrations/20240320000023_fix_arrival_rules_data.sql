-- First, clean up any duplicate rules
DELETE FROM arrival_rules
WHERE id NOT IN (
  SELECT id
  FROM arrival_rules
  ORDER BY updated_at DESC
  LIMIT 1
);

-- If no rules exist, insert default
INSERT INTO arrival_rules (arrival_day, departure_day)
SELECT 'wednesday', 'tuesday'
WHERE NOT EXISTS (
  SELECT 1 FROM arrival_rules
);

-- Add unique constraint to prevent multiple active rules
ALTER TABLE arrival_rules ADD CONSTRAINT single_active_rule UNIQUE (arrival_day, departure_day);