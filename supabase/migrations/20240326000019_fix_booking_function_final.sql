-- Drop existing booking function
DROP FUNCTION IF EXISTS create_confirmed_booking CASCADE;

-- Create updated booking function that ensures single row return
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS SETOF bookings AS $$
DECLARE
  v_accommodation accommodations;
  v_available_bed_id uuid;
  v_booking_id uuid;
BEGIN
  -- Lock the accommodation row
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Accommodation not found';
  END IF;

  -- Handle dorm/fungible bookings
  IF v_accommodation.is_fungible AND NOT v_accommodation.is_unlimited THEN
    -- Find a single available bed unit
    SELECT id INTO v_available_bed_id
    FROM accommodations
    WHERE parent_accommodation_id = p_accommodation_id
    AND id NOT IN (
      SELECT accommodation_id
      FROM bookings
      WHERE status = 'confirmed'
      AND check_out > p_check_in
      AND check_in < p_check_out
    )
    ORDER BY id  -- Ensure consistent ordering
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No beds available for these dates';
    END IF;

    -- Use the specific bed unit
    p_accommodation_id := v_available_bed_id;
  ELSE
    -- For non-fungible accommodations, check availability
    IF EXISTS (
      SELECT 1 FROM bookings
      WHERE accommodation_id = p_accommodation_id
      AND status = 'confirmed'
      AND check_out > p_check_in
      AND check_in < p_check_out
      FOR UPDATE
    ) THEN
      RAISE EXCEPTION 'Accommodation not available for these dates';
    END IF;
  END IF;

  -- Generate a unique booking ID
  v_booking_id := gen_random_uuid();

  -- Create the booking with the specific ID
  RETURN QUERY
  INSERT INTO bookings (
    id,
    accommodation_id,
    user_id,
    check_in,
    check_out,
    total_price,
    status
  ) VALUES (
    v_booking_id,
    p_accommodation_id,
    p_user_id,
    p_check_in,
    p_check_out,
    p_total_price,
    'confirmed'
  )
  RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX IF NOT EXISTS idx_bookings_accommodation_status ON bookings(accommodation_id, status);