-- Drop existing function
DROP FUNCTION IF EXISTS create_confirmed_booking CASCADE;

-- Create updated booking function that properly handles unlimited accommodations
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
  -- Get accommodation details
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Accommodation not found';
  END IF;

  -- Handle different accommodation types
  IF v_accommodation.is_unlimited THEN
    -- For unlimited accommodations (van parking, +1, etc), just create the booking
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
    ) RETURNING * INTO v_booking;
  ELSIF v_accommodation.is_fungible AND NOT v_accommodation.is_unlimited THEN
    -- For fungible accommodations (dorms), find an available bed
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
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No beds available for these dates';
    END IF;

    -- Use the bed unit ID
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
    ) RETURNING * INTO v_booking;
  ELSE
    -- For regular accommodations, check availability
    IF EXISTS (
      SELECT 1 FROM bookings
      WHERE accommodation_id = p_accommodation_id
      AND status = 'confirmed'
      AND check_out > p_check_in
      AND check_in < p_check_out
    ) THEN
      RAISE EXCEPTION 'Accommodation not available for these dates';
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
    ) RETURNING * INTO v_booking;
  END IF;

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;