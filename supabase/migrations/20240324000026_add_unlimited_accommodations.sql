-- First, remove existing unlimited accommodations
DELETE FROM accommodations 
WHERE title IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1');

-- Create parent entries for unlimited accommodations
INSERT INTO accommodations (
  title,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  beds,
  bathrooms,
  superhost,
  inventory_count,
  is_fungible,
  is_unlimited
) VALUES 
('Your Own Tent', 'The Garden', 0, 4.9, 45, 'https://storage.tally.so/46092536-82aa-4efc-a845-d84097c62a4b/photo_2023-09-07_18-55-35.jpg', 'Camping', 1, 0, false, 999, true, true),
('Van Parking', 'The Garden', 0, 4.85, 27, 'https://storage.tally.so/530c1104-341b-42ec-8c10-8aaa5ad56b87/DOG_9426.jpg', 'Parking', 0, 0, false, 999, true, true),
('I''m staying with someone else / +1', 'The Garden', 0, 5.0, 12, 'https://storage.tally.so/b6723884-5ada-4a14-bd07-6dab8c9b6689/1Untitled-5.jpg', 'Add-on', 0, 0, false, 999, true, true);

-- Create initial units (will auto-expand as needed)
WITH unlimited_parents AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE is_unlimited = true
)
INSERT INTO accommodations (
  title,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  beds,
  bathrooms,
  superhost,
  inventory_count,
  parent_accommodation_id,
  is_fungible,
  is_unlimited
)
SELECT 
  up.title || ' Unit ' || unit_number,
  up.location,
  up.price,
  up.rating,
  up.reviews,
  up.image_url,
  up.type,
  CASE WHEN up.title = 'Your Own Tent' THEN 1 ELSE 0 END,
  up.bathrooms,
  up.superhost,
  1,
  up.id,
  false,
  false
FROM unlimited_parents up
CROSS JOIN generate_series(1, 10) as unit_number;