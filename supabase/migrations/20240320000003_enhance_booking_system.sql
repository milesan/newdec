-- Create a credits table to track user credits
CREATE TABLE credits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  amount integer NOT NULL,
  description text,
  booking_id uuid REFERENCES bookings ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on credits table
ALTER TABLE credits ENABLE ROW LEVEL SECURITY;

-- Create policies for credits
CREATE POLICY "Users can view their own credits"
  ON credits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to credits"
  ON credits FOR ALL
  USING (public.is_admin());

-- Add a credits column to profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS credits integer DEFAULT 0 NOT NULL;

-- Create a function to handle booking changes
CREATE OR REPLACE FUNCTION modify_booking(
  p_booking_id UUID,
  p_new_check_in TIMESTAMP WITH TIME ZONE,
  p_new_check_out TIMESTAMP WITH TIME ZONE
) RETURNS JSONB AS $$
DECLARE
  v_old_booking bookings;
  v_new_total_price integer;
  v_price_difference integer;
  v_accommodation accommodations;
BEGIN
  -- Get the existing booking
  SELECT * INTO v_old_booking
  FROM bookings
  WHERE id = p_booking_id AND user_id = auth.uid();
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found or unauthorized';
  END IF;

  -- Get accommodation details
  SELECT * INTO v_accommodation
  FROM accommodations
  WHERE id = v_old_booking.accommodation_id;

  -- Calculate new total price based on duration
  v_new_total_price := v_accommodation.price * 
    CEIL(EXTRACT(EPOCH FROM (p_new_check_out - p_new_check_in)) / 86400.0);
  
  -- Calculate price difference
  v_price_difference := v_new_total_price - v_old_booking.total_price;

  -- Check if new dates are available (excluding current booking's dates)
  IF EXISTS (
    SELECT 1 FROM availability 
    WHERE accommodation_id = v_old_booking.accommodation_id 
    AND status = 'BOOKED'
    AND id != v_old_booking.id
    AND (p_new_check_in, p_new_check_out) OVERLAPS (date, date + interval '1 day')
  ) THEN
    RAISE EXCEPTION 'Selected dates are not available';
  END IF;

  -- If price difference is positive, ensure user confirms payment first
  IF v_price_difference > 0 THEN
    RETURN jsonb_build_object(
      'status', 'payment_required',
      'amount', v_price_difference,
      'booking', row_to_json(v_old_booking)
    );
  END IF;

  -- Update the booking
  UPDATE bookings 
  SET 
    check_in = p_new_check_in,
    check_out = p_new_check_out,
    total_price = v_new_total_price,
    updated_at = now()
  WHERE id = p_booking_id
  RETURNING * INTO v_old_booking;

  -- If price difference is negative, add credit
  IF v_price_difference < 0 THEN
    INSERT INTO credits (user_id, amount, description, booking_id)
    VALUES (auth.uid(), abs(v_price_difference), 'Booking modification refund', p_booking_id);
    
    UPDATE profiles 
    SET credits = credits + abs(v_price_difference)
    WHERE id = auth.uid();
  END IF;

  -- Update availability
  -- First, remove old availability records
  DELETE FROM availability 
  WHERE accommodation_id = v_old_booking.accommodation_id
  AND date >= v_old_booking.check_in::date
  AND date < v_old_booking.check_out::date;

  -- Then insert new availability records
  INSERT INTO availability (accommodation_id, date, status)
  SELECT 
    v_old_booking.accommodation_id,
    generate_series(p_new_check_in::date, p_new_check_out::date - interval '1 day', interval '1 day'),
    'BOOKED';

  RETURN jsonb_build_object(
    'status', 'success',
    'booking', row_to_json(v_old_booking),
    'credit_added', GREATEST(-v_price_difference, 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to delete a booking
CREATE OR REPLACE FUNCTION delete_booking(p_booking_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_booking bookings;
BEGIN
  -- Get the booking and verify ownership
  SELECT * INTO v_booking
  FROM bookings
  WHERE id = p_booking_id AND user_id = auth.uid();
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found or unauthorized';
  END IF;

  -- Delete availability records
  DELETE FROM availability 
  WHERE accommodation_id = v_booking.accommodation_id
  AND date >= v_booking.check_in::date
  AND date < v_booking.check_out::date;

  -- Add full refund as credit
  INSERT INTO credits (user_id, amount, description, booking_id)
  VALUES (auth.uid(), v_booking.total_price, 'Booking cancellation refund', p_booking_id);
  
  UPDATE profiles 
  SET credits = credits + v_booking.total_price
  WHERE id = auth.uid();

  -- Delete the booking
  DELETE FROM bookings WHERE id = p_booking_id;

  RETURN jsonb_build_object(
    'status', 'success',
    'credit_added', v_booking.total_price
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON credits TO authenticated;
GRANT EXECUTE ON FUNCTION modify_booking TO authenticated;
GRANT EXECUTE ON FUNCTION delete_booking TO authenticated;