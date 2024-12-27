-- Drop existing function
DROP FUNCTION IF EXISTS create_confirmed_booking CASCADE;

-- Create updated booking function that ensures single row return
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS bookings AS $$
#variable_conflict use_column
DECLARE
  v_booking bookings;
  v_accommodation accommodations;
  v_available_bed_id uuid;
BEGIN
  -- Get accommodation details with FOR UPDATE to prevent race conditions
  SELECT * INTO STRICT v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id
  FOR UPDATE;

  -- Handle different accommodation types
  IF v_accommodation.is_unlimited THEN
    -- For unlimited accommodations, create booking directly
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
    ) RETURNING * INTO STRICT v_booking;

  ELSIF v_accommodation.is_fungible AND NOT v_accommodation.is_unlimited THEN
    -- For fungible accommodations (dorms), find an available bed
    SELECT id INTO STRICT v_available_bed_id
    FROM accommodations
    WHERE parent_accommodation_id = p_accommodation_id
    AND id NOT IN (
      SELECT accommodation_id
      FROM bookings
      WHERE status = 'confirmed'
      AND check_out > p_check_in
      AND check_in < p_check_out
    )
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    -- Create booking with the specific bed
    INSERT INTO bookings (
      accommodation_id,
      user_id,
      check_in,
      check_out,
      total_price,
      status
    ) VALUES (
      v_available_bed_id,
      p_user_id,
      p_check_in,
      p_check_out,
      p_total_price,
      'confirmed'
    ) RETURNING * INTO STRICT v_booking;

  ELSE
    -- For regular accommodations, check availability
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

    -- Create booking
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
    ) RETURNING * INTO STRICT v_booking;
  END IF;

  -- Return exactly one row
  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX IF NOT EXISTS idx_bookings_accommodation_status ON bookings(accommodation_id, status);