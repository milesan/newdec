-- First, ensure all accommodations have correct flags
UPDATE accommodations 
SET 
  is_fungible = true,
  is_unlimited = false
WHERE title IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1')
AND parent_accommodation_id IS NULL;

-- Update A-Frame Pod price
UPDATE accommodations 
SET price = 325
WHERE title = 'A-Frame Pod';

-- Reset all other accommodations to be non-fungible and non-unlimited
UPDATE accommodations
SET 
  is_fungible = false,
  is_unlimited = false
WHERE title NOT IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1')
AND parent_accommodation_id IS NULL;

-- Make sure dorms are properly marked as fungible
UPDATE accommodations
SET 
  is_fungible = true,
  is_unlimited = false
WHERE title IN ('4-Bed Dorm', '6-Bed Dorm', '3-Bed Dorm')
AND parent_accommodation_id IS NULL;