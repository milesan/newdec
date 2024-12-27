-- Create a function to handle timezone conversion
CREATE OR REPLACE FUNCTION convert_to_utc1(
  p_date TIMESTAMP WITH TIME ZONE,
  p_hour INTEGER DEFAULT 0
) RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
  -- First convert to UTC midnight
  RETURN date_trunc('day', p_date AT TIME ZONE 'UTC')::timestamp + 
         ((p_hour + 1) * interval '1 hour') AT TIME ZONE 'UTC';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update booking function to use timezone conversion
CREATE OR REPLACE FUNCTION create_manual_booking(
  p_email text,
  p_accommodation_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS bookings AS $$
DECLARE
  v_booking bookings;
  v_accommodation accommodations;
  v_available_bed_id uuid;
  v_user_id uuid;
  v_check_in TIMESTAMP WITH TIME ZONE;
  v_check_out TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Convert dates to UTC+1
  v_check_in := convert_to_utc1(p_check_in, 15);  -- 3 PM
  v_check_out := convert_to_utc1(p_check_out, 12); -- 12 PM

  -- Get user ID from email
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Get accommodation details
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = p_accommodation_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Accommodation not found';
  END IF;

  -- Handle different accommodation types
  IF v_accommodation.is_unlimited THEN
    -- For unlimited accommodations, just create the booking
    INSERT INTO bookings (
      accommodation_id,
      user_id,
      check_in,
      check_out,
      total_price,
      status
    ) VALUES (
      p_accommodation_id,
      v_user_id,
      v_check_in,
      v_check_out,
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
      AND check_out > v_check_in
      AND check_in < v_check_out
    )
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No beds available for these dates';
    END IF;

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
      v_user_id,
      v_check_in,
      v_check_out,
      p_total_price,
      'confirmed'
    ) RETURNING * INTO v_booking;

  ELSE
    -- For regular accommodations, check availability
    IF EXISTS (
      SELECT 1 FROM bookings
      WHERE accommodation_id = p_accommodation_id
      AND status = 'confirmed'
      AND check_out > v_check_in
      AND check_in < v_check_out
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
      v_user_id,
      v_check_in,
      v_check_out,
      p_total_price,
      'confirmed'
    ) RETURNING * INTO v_booking;
  END IF;

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION convert_to_utc1 TO authenticated;
GRANT EXECUTE ON FUNCTION create_manual_booking TO authenticated;