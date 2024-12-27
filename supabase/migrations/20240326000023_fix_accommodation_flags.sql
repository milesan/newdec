-- Update Van Parking and +1 accommodations to be unlimited only, not fungible
UPDATE accommodations 
SET 
  is_fungible = false,
  is_unlimited = true
WHERE title IN ('Van Parking', 'I''m staying with someone else / +1', 'Your Own Tent');

-- Ensure parent accommodations for dorms are fungible but not unlimited
UPDATE accommodations 
SET 
  is_fungible = true,
  is_unlimited = false
WHERE title IN ('4-Bed Dorm', '6-Bed Dorm', '3-Bed Dorm');

-- Ensure individual dorm beds are neither fungible nor unlimited
UPDATE accommodations 
SET 
  is_fungible = false,
  is_unlimited = false
WHERE parent_accommodation_id IS NOT NULL;