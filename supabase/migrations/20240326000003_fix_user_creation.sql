-- Drop existing triggers and functions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create a more robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile in a separate transaction to avoid deadlocks
  BEGIN
    INSERT INTO public.profiles (id, email, credits)
    VALUES (NEW.id, NEW.email, 1000);
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Failed to create profile: %', SQLERRM;
  END;

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
      'application_status', 'approved'
    );
    
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

  -- Ensure email is confirmed for whitelisted users
  IF NEW.raw_user_meta_data->>'is_whitelisted' = 'true' THEN
    NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, now());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that runs BEFORE insert
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Create a function to ensure profile exists
CREATE OR REPLACE FUNCTION ensure_profile_exists()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, credits)
  VALUES (NEW.id, NEW.email, 1000)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that runs AFTER insert as a backup
CREATE TRIGGER ensure_profile_exists
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_profile_exists();

-- Ensure proper indexes exist
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT ALL ON profiles TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user TO authenticated;
GRANT EXECUTE ON FUNCTION ensure_profile_exists TO authenticated;