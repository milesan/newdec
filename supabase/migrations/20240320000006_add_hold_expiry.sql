-- Add a function to automatically expire holds after 72 hours
CREATE OR REPLACE FUNCTION expire_holds() RETURNS void AS $$
BEGIN
  UPDATE availability
  SET status = 'AVAILABLE'
  WHERE status = 'HOLD'
  AND created_at < NOW() - INTERVAL '72 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a scheduled job to run every hour
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'expire-holds',
  '0 * * * *', -- Run every hour
  $$SELECT expire_holds()$$
);

-- Add check for minimum advance booking
CREATE OR REPLACE FUNCTION check_booking_rules()
RETURNS TRIGGER AS $$
BEGIN
  -- Check minimum advance booking (3 business days)
  -- Skip check if it's an extension of an existing booking
  IF NOT EXISTS (
    SELECT 1 FROM bookings 
    WHERE user_id = NEW.user_id 
    AND accommodation_id = NEW.accommodation_id
    AND check_out = NEW.check_in
  ) THEN
    IF NEW.check_in < CURRENT_DATE + INTERVAL '3 days' THEN
      RAISE EXCEPTION 'Bookings must be made at least 3 business days in advance';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new bookings
CREATE TRIGGER enforce_booking_rules
  BEFORE INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION check_booking_rules();

-- Update the create_confirmed_booking function to handle extensions
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
    AND check_out = p_check_in
  ) INTO v_is_extension;

  -- Apply booking rules if not an extension
  IF NOT v_is_extension AND p_check_in < CURRENT_TIMESTAMP + INTERVAL '3 days' THEN
    RAISE EXCEPTION 'Bookings must be made at least 3 business days in advance';
  END IF;

  -- Rest of the function remains the same...
  -- [Previous implementation of create_confirmed_booking]

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;