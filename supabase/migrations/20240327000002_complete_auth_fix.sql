-- First, ensure we have a clean slate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS create_profile_after_user ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS create_profile_for_user() CASCADE;

-- Drop all existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can read their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admin full access to profiles" ON profiles;
DROP POLICY IF EXISTS "Admin full access to whitelist" ON whitelist;

-- Recreate tables with correct structure
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY,
  email text NOT NULL,
  credits integer NOT NULL DEFAULT 1000,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS whitelist;
CREATE TABLE whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create fresh policies
CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create a robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Set app metadata
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

  -- Create profile
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON whitelist TO authenticated;

-- Fix any existing users
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Update whitelisted users
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

  -- Update non-whitelisted users
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