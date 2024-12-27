-- Update inventory counts for specific accommodations
UPDATE accommodations
SET inventory_count = 
  CASE 
    WHEN type = 'Tipi' THEN 40
    WHEN title = '4 Meter Bell Tent' THEN 25
    WHEN title = '5m Bell Tent' THEN 6
    WHEN title = 'A-Frame Pod' THEN 1
    WHEN title = 'Microcabin' THEN 3
    ELSE inventory_count
  END;