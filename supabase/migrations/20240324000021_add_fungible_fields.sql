-- Add fungible accommodation fields
ALTER TABLE accommodations
ADD COLUMN IF NOT EXISTS is_fungible BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_unlimited BOOLEAN DEFAULT false;

-- Update existing accommodations
UPDATE accommodations SET
  is_fungible = true,
  is_unlimited = true
WHERE title IN ('Your Own Tent', 'Van Parking', "I'm staying with someone else / +1");

-- Update fungible accommodations
UPDATE accommodations SET
  is_fungible = true,
  is_unlimited = false
WHERE title IN (
  '2.2 Meter Tipi',
  '4 Meter Bell Tent',
  '5m Bell Tent',
  '4-Bed Dorm',
  '6-Bed Dorm'
);