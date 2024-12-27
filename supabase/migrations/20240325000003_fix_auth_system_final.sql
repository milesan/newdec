-- First, drop all existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_sign_in ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_whitelist_login() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_sign_in() CASCADE;

-- Create whitelist table if it doesn't exist
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

-- Create whitelist policies
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create a simpler function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, email, credits)
  VALUES (new.id, new.email, 1000);

  -- Check if user is whitelisted
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = new.email) THEN
    -- Set metadata for whitelisted users
    new.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved'
    );
    
    -- Update whitelist record
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = new.email;
  ELSE
    -- Set default metadata
    new.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', false
    );
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create function to handle sign ins
CREATE OR REPLACE FUNCTION handle_sign_in()
RETURNS trigger AS $$
BEGIN
  -- Update last login for whitelisted users
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for sign ins
CREATE TRIGGER on_auth_sign_in
  BEFORE UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_sign_in();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT ALL ON whitelist TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user TO authenticated;
GRANT EXECUTE ON FUNCTION handle_sign_in TO authenticated;

-- Update existing users' metadata if they're whitelisted
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT u.id, u.email, u.raw_user_meta_data
    FROM auth.users u
    JOIN whitelist w ON u.email = w.email
  LOOP
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved'
    )
    WHERE id = r.id;
  END LOOP;
END $$;