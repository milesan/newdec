-- Drop existing function
DROP FUNCTION IF EXISTS create_confirmed_booking;

-- Recreate with fixed date comparison
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS bookings AS $$
DECLARE
  v_booking bookings;
  v_is_extension BOOLEAN;
BEGIN
  -- Check if this is an extension
  SELECT EXISTS (
    SELECT 1 FROM bookings 
    WHERE user_id = p_user_id 
    AND accommodation_id = p_accommodation_id
    AND check_out::date = p_check_in::date
  ) INTO v_is_extension;

  -- Apply booking rules if not an extension
  IF NOT v_is_extension AND p_check_in < CURRENT_TIMESTAMP + INTERVAL '3 days' THEN
    RAISE EXCEPTION 'Bookings must be made at least 3 business days in advance';
  END IF;

  -- Check if dates are available
  IF EXISTS (
    SELECT 1 FROM availability 
    WHERE accommodation_id = p_accommodation_id 
    AND status IN ('BOOKED', 'HOLD')
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
    d::date,
    'BOOKED'
  FROM generate_series(
    p_check_in::date,
    p_check_out::date - INTERVAL '1 day',
    INTERVAL '1 day'
  ) d
  ON CONFLICT (accommodation_id, date) 
  DO UPDATE SET status = 'BOOKED';

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;