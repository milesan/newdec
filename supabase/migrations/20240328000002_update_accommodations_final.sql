-- First, remove existing unlimited accommodations
DELETE FROM accommodations 
WHERE title IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1');

-- Create parent entries for fungible accommodations
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
('Your Own Tent', 'The Garden', 0, 4.9, 45, 'https://storage.tally.so/46092536-82aa-4efc-a845-d84097c62a4b/photo_2023-09-07_18-55-35.jpg', 'Camping', 1, 0, false, 5000, true, false),
('Van Parking', 'The Garden', 0, 4.85, 27, 'https://storage.tally.so/530c1104-341b-42ec-8c10-8aaa5ad56b87/DOG_9426.jpg', 'Parking', 0, 0, false, 5000, true, false),
('I''m staying with someone else / +1', 'The Garden', 0, 5.0, 12, 'https://storage.tally.so/b6723884-5ada-4a14-bd07-6dab8c9b6689/1Untitled-5.jpg', 'Add-on', 0, 0, false, 5000, true, false);

-- Create individual units for tracking
WITH fungible_parents AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE title IN ('Your Own Tent', 'Van Parking', 'I''m staying with someone else / +1')
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
  fp.title || ' Unit ' || unit_number,
  fp.location,
  fp.price,
  fp.rating,
  fp.reviews,
  fp.image_url,
  fp.type,
  CASE WHEN fp.title = 'Your Own Tent' THEN 1 ELSE 0 END,
  fp.bathrooms,
  fp.superhost,
  1,
  fp.id,
  false,
  false
FROM fungible_parents fp
CROSS JOIN generate_series(1, 5000) as unit_number;