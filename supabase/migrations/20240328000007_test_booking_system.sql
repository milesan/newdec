-- First, let's add some test bookings
INSERT INTO bookings (
  accommodation_id,
  user_id,
  check_in,
  check_out,
  total_price,
  status
)
SELECT 
  a.id,
  (SELECT id FROM auth.users LIMIT 1),
  '2024-12-16',
  '2024-12-23',
  a.price,
  'confirmed'
FROM accommodations a
WHERE a.title = 'Microcabin Left';

-- Add a test booking for a dorm bed
WITH dorm AS (
  SELECT id FROM accommodations WHERE title = '4-Bed Dorm' LIMIT 1
),
dorm_bed AS (
  SELECT id FROM accommodations 
  WHERE parent_accommodation_id = (SELECT id FROM dorm)
  LIMIT 1
)
INSERT INTO bookings (
  accommodation_id,
  user_id,
  check_in,
  check_out,
  total_price,
  status
)
SELECT 
  id,
  (SELECT id FROM auth.users LIMIT 1),
  '2024-12-16',
  '2024-12-23',
  167,
  'confirmed'
FROM dorm_bed;

-- Create a function to check availability
CREATE OR REPLACE FUNCTION check_accommodation_availability(
  p_accommodation_id UUID,
  p_start_date DATE,
  p_end_date DATE
) RETURNS TABLE (
  accommodation_id UUID,
  available_units INTEGER
) AS $$
DECLARE
  v_accommodation accommodations;
BEGIN
  -- Get accommodation details
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id;

  IF v_accommodation.is_unlimited THEN
    RETURN QUERY SELECT 
      p_accommodation_id,
      v_accommodation.inventory_count;
  ELSIF v_accommodation.is_fungible THEN
    -- For fungible accommodations, count available units
    RETURN QUERY 
    SELECT 
      p_accommodation_id,
      v_accommodation.inventory_count - COUNT(DISTINCT b.accommodation_id)::integer
    FROM accommodations a
    LEFT JOIN bookings b ON (
      b.accommodation_id = a.id OR 
      b.accommodation_id IN (
        SELECT id FROM accommodations 
        WHERE parent_accommodation_id = p_accommodation_id
      )
    )
    AND b.status = 'confirmed'
    AND b.check_out > p_start_date
    AND b.check_in < p_end_date
    WHERE a.id = p_accommodation_id
    GROUP BY a.id;
  ELSE
    -- For regular accommodations, check if booked
    RETURN QUERY 
    SELECT 
      p_accommodation_id,
      CASE WHEN EXISTS (
        SELECT 1 FROM bookings 
        WHERE accommodation_id = p_accommodation_id
        AND status = 'confirmed'
        AND check_out > p_start_date
        AND check_in < p_end_date
      ) THEN 0 ELSE 1 END;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_accommodation_availability TO authenticated;