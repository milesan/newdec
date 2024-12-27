-- Update accommodations with corrected and discounted base rates
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