-- First, remove existing dorm entries
DELETE FROM accommodations WHERE title IN ('4-Bed Dorm', '6-Bed Dorm');

-- Create the main dorm entries that will be visible in the UI
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
  inventory_count
) VALUES 
('4-Bed Dorm', 'The Garden', 167, 4.7, 45, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (No Bunks)', 4, 1, false, 1),
('6-Bed Dorm', 'The Garden', 145, 4.7, 89, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (3 Double Bunks)', 6, 1, false, 1);

-- Create individual bed entries for inventory tracking
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
  parent_accommodation_id
)
SELECT 
  title || ' Bed ' || bed_number,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  1, -- Each bed entry has 1 bed
  bathrooms,
  superhost,
  1, -- Each bed entry has inventory of 1
  id as parent_accommodation_id
FROM accommodations a
CROSS JOIN generate_series(1, 
  CASE 
    WHEN a.title = '4-Bed Dorm' THEN 4
    WHEN a.title = '6-Bed Dorm' THEN 6
  END
) as bed_number
WHERE a.title IN ('4-Bed Dorm', '6-Bed Dorm');