-- First, remove existing accommodations that need updating
DELETE FROM accommodations 
WHERE title IN ('Your Own Tent', '4-Bed Dorm', 'A-Frame Pod', 'Master''s Suite');

-- Create updated accommodations
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
('3-Bed Dorm', 'The Garden', 167, 4.7, 45, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (No Bunks)', 3, 1, false, 3, true, false),
('A-Frame Pod', 'The Garden', 275, 4.9, 18, 'https://storage.tally.so/8ad5a3bd-26cb-4210-b33e-16a4e015d5f7/a-framephoto_2024-02-29_14-57-04.jpg', 'Pod', 2, 0, true, 1, false, false),
('Master''s Suite', 'The Garden', 500, 5.0, 12, 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300"><rect width="100%" height="100%" fill="black"/></svg>', 'Suite', 2, 1, true, 1, false, false);

-- Create individual bed entries for 3-bed dorm
WITH dorm_parent AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE title = '3-Bed Dorm'
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
  dp.title || ' Bed ' || bed_number,
  dp.location,
  dp.price,
  dp.rating,
  dp.reviews,
  dp.image_url,
  dp.type,
  1,
  dp.bathrooms,
  dp.superhost,
  1,
  dp.id,
  false,
  false
FROM dorm_parent dp
CROSS JOIN generate_series(1, 3) as bed_number;