-- Add new columns for explicitly marking days as not available
ALTER TABLE day_rules
ADD COLUMN not_arrival boolean DEFAULT false,
ADD COLUMN not_departure boolean DEFAULT false;

-- Update constraint to handle new columns
ALTER TABLE day_rules
DROP CONSTRAINT valid_rule,
ADD CONSTRAINT valid_rule CHECK (
  -- Can't be both arrival and departure
  NOT (is_arrival AND is_departure)
  -- Can't be both arrival and not arrival
  AND NOT (is_arrival AND not_arrival)
  -- Can't be both departure and not departure
  AND NOT (is_departure AND not_departure)
);