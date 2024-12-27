-- Create a trigger function to handle booking-related availability updates
CREATE OR REPLACE FUNCTION handle_booking_availability() RETURNS TRIGGER AS $$
DECLARE
  current_date DATE;
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- For new bookings, mark all dates in range as BOOKED
    current_date := NEW.check_in::DATE;
    WHILE current_date < NEW.check_out::DATE LOOP
      INSERT INTO availability (accommodation_id, date, status)
      VALUES (NEW.accommodation_id, current_date, 'BOOKED')
      ON CONFLICT (accommodation_id, date) 
      DO UPDATE SET status = 'BOOKED';
      
      current_date := current_date + 1;
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS update_availability_on_booking ON bookings;
CREATE TRIGGER update_availability_on_booking
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION handle_booking_availability();