-- First, drop the existing functions to avoid conflicts
DROP FUNCTION IF EXISTS create_manual_booking;
DROP FUNCTION IF EXISTS create_confirmed_booking;

-- Recreate the base booking function with proper signature
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS bookings AS $$
DECLARE
  v_booking bookings;
BEGIN
  -- Check if dates are available
  IF EXISTS (
    SELECT 1 FROM availability 
    WHERE accommodation_id = p_accommodation_id 
    AND status = 'BOOKED'
    AND date >= p_check_in::date
    AND date < p_check_out::date
  ) THEN
    RAISE EXCEPTION 'Selected dates are not available';
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

  -- Mark dates as booked in availability
  INSERT INTO availability (
    accommodation_id,
    date,
    status
  )
  SELECT 
    p_accommodation_id,
    generate_series(p_check_in::date, p_check_out::date - interval '1 day', interval '1 day'),
    'BOOKED'
  ON CONFLICT (accommodation_id, date) 
  DO UPDATE SET status = 'BOOKED';

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the manual booking function that uses the base function
CREATE OR REPLACE FUNCTION create_manual_booking(
  p_email TEXT,
  p_accommodation_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
  v_booking bookings;
BEGIN
  -- Check if caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Get or create user
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_user_id IS NULL THEN
    -- Create profile for new user
    INSERT INTO profiles (id, email)
    VALUES (gen_random_uuid(), p_email)
    RETURNING id INTO v_user_id;
  END IF;

  -- Create booking using base function
  SELECT * INTO v_booking
  FROM create_confirmed_booking(
    p_accommodation_id,
    v_user_id,
    p_check_in,
    p_check_out,
    p_total_price
  );

  RETURN jsonb_build_object(
    'booking', row_to_json(v_booking),
    'user_id', v_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;
GRANT EXECUTE ON FUNCTION create_manual_booking TO authenticated;