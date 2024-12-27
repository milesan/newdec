-- First, clean up existing whitelist-related objects
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS create_profile_for_user() CASCADE;

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

-- Enable RLS on whitelist
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create whitelist policy
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create a robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Check if user is whitelisted first
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    -- Set metadata for whitelisted users
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
    -- Set default metadata for non-whitelisted users
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', false,
      'application_status', null
    );
  END IF;

  -- Set app metadata
  NEW.raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  );

  -- Create profile
  BEGIN
    INSERT INTO public.profiles (id, email, credits)
    VALUES (NEW.id, NEW.email, 1000)
    ON CONFLICT (id) DO NOTHING;
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

-- Fix existing users' metadata
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Fix whitelisted users
  FOR r IN 
    SELECT u.id, u.email
    FROM auth.users u
    JOIN whitelist w ON u.email = w.email
  LOOP
    -- Update user metadata
    UPDATE auth.users
    SET 
      raw_user_meta_data = jsonb_build_object(
        'is_whitelisted', true,
        'has_seen_welcome', false,
        'application_status', 'approved',
        'has_applied', true
      ),
      email_confirmed_at = COALESCE(email_confirmed_at, now()),
      raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', ARRAY['email']
      )
    WHERE id = r.id;

    -- Ensure profile exists
    INSERT INTO profiles (id, email, credits)
    VALUES (r.id, r.email, 1000)
    ON CONFLICT (id) DO NOTHING;
  END LOOP;

  -- Fix non-whitelisted users
  UPDATE auth.users u
  SET raw_user_meta_data = jsonb_build_object(
    'is_whitelisted', false,
    'has_applied', false,
    'application_status', null
  )
  WHERE NOT EXISTS (
    SELECT 1 FROM whitelist w 
    WHERE w.email = u.email
  );
END $$;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);

-- Grant necessary permissions
GRANT ALL ON whitelist TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user TO authenticated;