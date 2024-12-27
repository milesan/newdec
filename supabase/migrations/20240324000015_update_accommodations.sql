-- Update accommodations
UPDATE accommodations
SET price = 
  CASE 
    WHEN title = 'Microcabin' AND id = (SELECT id FROM accommodations WHERE title = 'Microcabin' LIMIT 1) THEN 385
    WHEN title = 'Microcabin' AND id IN (SELECT id FROM accommodations WHERE title = 'Microcabin' OFFSET 1) THEN 385
    ELSE price
  END;

-- Delete existing dorm
DELETE FROM accommodations WHERE title = 'Shared Dorm';

-- Add new accommodations
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
('6-Bed Dorm', 'The Garden', 145, 4.7, 89, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (3 Double Bunks)', 6, 1, false, 1),
('Master''s Suite', 'The Garden', 589, 5.0, 12, 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300"><rect width="100%" height="100%" fill="black"/></svg>', 'Suite', 2, 1, true, 1);