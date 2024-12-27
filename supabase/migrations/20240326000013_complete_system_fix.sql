-- First, clean up any broken state
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Ensure tables exist with correct structure
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY,
  email text NOT NULL,
  credits integer NOT NULL DEFAULT 1000,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  accommodation_id uuid REFERENCES accommodations(id) ON DELETE CASCADE NOT NULL,
  check_in timestamp with time zone NOT NULL,
  check_out timestamp with time zone NOT NULL,
  total_price integer NOT NULL,
  status text NOT NULL DEFAULT 'confirmed',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

CREATE POLICY "Users can view their own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin full access to bookings"
  ON bookings FOR ALL
  USING (public.is_admin());

-- Create a robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_is_whitelisted boolean;
BEGIN
  -- Check whitelist status first
  SELECT EXISTS (
    SELECT 1 FROM whitelist WHERE email = NEW.email
  ) INTO v_is_whitelisted;

  -- Set metadata based on whitelist status
  NEW.raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  );

  IF v_is_whitelisted THEN
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true
    );
    NEW.email_confirmed_at = now();
    
    -- Update whitelist record
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = NEW.email;
  ELSE
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', false,
      'application_status', null
    );
  END IF;

  -- Create profile in a separate transaction
  BEGIN
    INSERT INTO public.profiles (id, email, credits)
    VALUES (NEW.id, NEW.email, 1000);
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Could not create profile: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that runs BEFORE insert
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create function to handle booking creation
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

  -- If this is a dorm parent, find an available bed
  IF v_accommodation.is_fungible AND NOT v_accommodation.is_unlimited THEN
    -- Find an available bed unit
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

    -- Use the bed unit ID instead of the parent dorm ID
    p_accommodation_id := v_available_bed_id;
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

  RETURN v_booking;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_accommodation_id ON bookings(accommodation_id);
CREATE INDEX IF NOT EXISTS idx_bookings_dates ON bookings(check_in, check_out);

-- Grant necessary permissions
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON whitelist TO authenticated;
GRANT ALL ON bookings TO authenticated;
GRANT EXECUTE ON FUNCTION create_confirmed_booking TO authenticated;

-- Fix any existing broken state
UPDATE auth.users u
SET raw_user_meta_data = jsonb_build_object(
  'is_whitelisted', EXISTS (SELECT 1 FROM whitelist w WHERE w.email = u.email),
  'has_seen_welcome', false,
  'application_status', CASE 
    WHEN EXISTS (SELECT 1 FROM whitelist w WHERE w.email = u.email) THEN 'approved'
    ELSE raw_user_meta_data->>'application_status'
  END,
  'has_applied', CASE 
    WHEN EXISTS (SELECT 1 FROM whitelist w WHERE w.email = u.email) THEN true
    ELSE COALESCE((raw_user_meta_data->>'has_applied')::boolean, false)
  END
)
WHERE id IN (
  SELECT id FROM auth.users
  WHERE email IN (SELECT email FROM whitelist)
);