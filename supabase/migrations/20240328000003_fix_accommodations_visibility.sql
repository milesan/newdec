-- First, ensure all accommodations are properly marked as fungible/unlimited
UPDATE accommodations 
SET 
  is_fungible = true,
  is_unlimited = false
WHERE title IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1');

-- Update A-Frame Pod price
UPDATE accommodations 
SET price = 325
WHERE title = 'A-Frame Pod';

-- Make sure all accommodations are visible
UPDATE accommodations
SET is_fungible = false, is_unlimited = false
WHERE title NOT IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1')
AND parent_accommodation_id IS NULL;