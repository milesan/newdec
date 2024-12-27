-- Drop existing function if it exists
DROP FUNCTION IF EXISTS create_confirmed_booking;

-- Create the function with correct parameter order and error handling
CREATE OR REPLACE FUNCTION create_confirmed_booking(
  p_accommodation_id UUID,
  p_user_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_booking bookings;
BEGIN
  -- Check if dates are available
  IF EXISTS (
    SELECT 1 FROM availability 
    WHERE accommodation_id = p_accommodation_id 
    AND status = 'BOOKED'
    AND (start_date, end_date) OVERLAPS (p_check_in, p_check_out)
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
    'BOOKED';

  RETURN jsonb_build_object(
    'booking', row_to_json(v_booking)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;