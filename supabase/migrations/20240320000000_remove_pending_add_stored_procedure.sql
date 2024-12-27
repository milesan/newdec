-- First, delete all pending bookings
DELETE FROM bookings WHERE status = 'pending';

-- Remove the default status from bookings table
ALTER TABLE bookings 
ALTER COLUMN status SET DEFAULT 'confirmed',
ALTER COLUMN status SET NOT NULL;

-- Create a function to handle booking creation and availability update
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
    AND daterange(start_date, end_date, '[]') && daterange(p_check_in, p_check_out, '[]')
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
    start_date,
    end_date,
    status
  ) VALUES (
    p_accommodation_id,
    p_check_in,
    p_check_out,
    'BOOKED'
  );

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;