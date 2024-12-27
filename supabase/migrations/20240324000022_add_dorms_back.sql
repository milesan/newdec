-- First, remove existing dorm entries
DELETE FROM accommodations WHERE title LIKE '%Dorm%';

-- Create the main dorm entries
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
('4-Bed Dorm', 'The Garden', 167, 4.7, 45, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (No Bunks)', 4, 1, false, 4, true, false),
('6-Bed Dorm', 'The Garden', 145, 4.7, 89, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (3 Double Bunks)', 6, 1, false, 6, true, false);

-- Create individual bed entries for inventory tracking
WITH dorm_parents AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE title IN ('4-Bed Dorm', '6-Bed Dorm')
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
FROM dorm_parents dp
CROSS JOIN generate_series(1, 
  CASE 
    WHEN dp.title = '4-Bed Dorm' THEN 4
    WHEN dp.title = '6-Bed Dorm' THEN 6
  END
) as bed_number;