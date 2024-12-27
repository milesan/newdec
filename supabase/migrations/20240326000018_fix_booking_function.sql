-- Drop existing booking function
DROP FUNCTION IF EXISTS create_confirmed_booking CASCADE;

-- Create updated booking function with proper row handling
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS bookings AS $$
DECLARE
  v_booking bookings;
  v_accommodation accommodations;
  v_available_bed_id uuid;
BEGIN
  -- Get accommodation details with FOR UPDATE to lock the row
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Accommodation not found';
  END IF;

  -- Handle dorm/fungible bookings
  IF v_accommodation.is_fungible AND NOT v_accommodation.is_unlimited THEN
    -- Find an available bed unit with FOR UPDATE SKIP LOCKED to prevent race conditions
    SELECT id INTO v_available_bed_id
    FROM accommodations
    WHERE parent_accommodation_id = p_accommodation_id
    AND id NOT IN (
      SELECT DISTINCT accommodation_id
      FROM bookings
      WHERE status = 'confirmed'
      AND check_out > p_check_in
      AND check_in < p_check_out
    )
    FOR UPDATE SKIP LOCKED
    LIMIT 1;

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
    ) THEN
      RAISE EXCEPTION 'Accommodation not available for these dates';
    END IF;
  END IF;

  -- Create the booking
  INSERT INTO bookings (
    accommodation_id,
    user_id,
    check_in,
    check_out,
    total_price,
    status
  ) VALUES (
    p_accommodation_id,
    p_user_id,
    p_check_in,
    p_check_out,
    p_total_price,
    'confirmed'
  )
  RETURNING * INTO v_booking;

  -- Return exactly one row
  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;