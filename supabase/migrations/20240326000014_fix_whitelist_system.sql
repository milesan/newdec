-- First, drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admin full access to whitelist" ON whitelist;
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Users can create bookings" ON bookings;
DROP POLICY IF EXISTS "Admin full access to bookings" ON bookings;

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Ensure whitelist table exists with correct structure
CREATE TABLE IF NOT EXISTS whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false
);

-- Enable RLS
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create fresh policies
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

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
BEGIN
  -- Create profile first
  INSERT INTO public.profiles (id, email, credits)
  VALUES (NEW.id, NEW.email, 1000);

  -- Initialize default metadata
  NEW.raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  );

  -- Check if user is whitelisted
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true
    );
    NEW.email_confirmed_at = now();
    
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

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that runs BEFORE insert
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Fix any existing users' metadata
UPDATE auth.users u
SET 
  raw_user_meta_data = jsonb_build_object(
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
  ),
  email_confirmed_at = CASE 
    WHEN EXISTS (SELECT 1 FROM whitelist w WHERE w.email = u.email) THEN now()
    ELSE email_confirmed_at
  END
WHERE id IN (
  SELECT id FROM auth.users
  WHERE email IN (SELECT email FROM whitelist)
);