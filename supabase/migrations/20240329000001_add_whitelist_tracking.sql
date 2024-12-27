-- Create whitelist table with tracking fields
CREATE TABLE IF NOT EXISTS whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false,
  has_created_account boolean DEFAULT false,
  account_created_at timestamp with time zone,
  has_booked boolean DEFAULT false,
  first_booking_at timestamp with time zone,
  last_booking_at timestamp with time zone,
  total_bookings integer DEFAULT 0
);

-- Enable RLS
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create policy for admin access
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create function to update whitelist tracking
CREATE OR REPLACE FUNCTION update_whitelist_tracking()
RETURNS trigger AS $$
BEGIN
  -- Update whitelist entry when a booking is created
  IF TG_OP = 'INSERT' THEN
    UPDATE whitelist w
    SET 
      has_booked = true,
      first_booking_at = COALESCE(w.first_booking_at, NEW.created_at),
      last_booking_at = NEW.created_at,
      total_bookings = COALESCE(w.total_bookings, 0) + 1
    FROM auth.users u
    WHERE u.id = NEW.user_id
    AND w.email = u.email;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for booking tracking
CREATE TRIGGER update_whitelist_on_booking
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_whitelist_tracking();

-- Create function to check whitelist status
CREATE OR REPLACE FUNCTION check_whitelist_status(p_email text)
RETURNS jsonb AS $$
DECLARE
  v_whitelist_entry whitelist;
BEGIN
  -- Get whitelist entry
  SELECT * INTO v_whitelist_entry
  FROM whitelist
  WHERE email = p_email;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'is_whitelisted', false
    );
  END IF;

  -- Update last login
  UPDATE whitelist
  SET last_login = now()
  WHERE id = v_whitelist_entry.id;

  RETURN jsonb_build_object(
    'is_whitelisted', true,
    'has_seen_welcome', v_whitelist_entry.has_seen_welcome
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON whitelist TO authenticated;
GRANT EXECUTE ON FUNCTION check_whitelist_status TO authenticated;
GRANT EXECUTE ON FUNCTION update_whitelist_tracking TO authenticated;