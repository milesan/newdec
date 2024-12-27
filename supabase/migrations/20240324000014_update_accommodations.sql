-- Update base rates for 2024
UPDATE accommodations
SET price = 
  CASE 
    WHEN title = 'Your Own Tent' THEN 0
    WHEN title = '2.2 Meter Tipi' THEN 245
    WHEN title = 'Shared Dorm' THEN 145
    WHEN title = 'Van Parking' THEN 0
    WHEN title = '4 Meter Bell Tent' THEN 280
    WHEN title = '5m Bell Tent' THEN 325
    WHEN title = 'Microcabin' THEN 350
    WHEN title = 'Writer''s Room' THEN 395
    WHEN title = 'Valleyview Room' THEN 440
    WHEN title = 'The Hearth' THEN 535
    WHEN title = 'A-Frame Pod' THEN 350
    ELSE price
  END;

-- Add new accommodation
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
) VALUES (
  'I''m staying with someone else / +1',
  'The Garden',
  0,
  5.0,
  12,
  'https://storage.tally.so/b6723884-5ada-4a14-bd07-6dab8c9b6689/1Untitled-5.jpg',
  'Add-on',
  0,
  0,
  false,
  999
);