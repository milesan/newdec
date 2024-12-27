-- First, clean up any broken state
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create a more robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Set app metadata first
  NEW.raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  );

  -- Check if user is whitelisted
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

  -- Return the modified user record
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a separate function to handle profile creation
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile in a separate transaction
  INSERT INTO public.profiles (id, email, credits)
  VALUES (NEW.id, NEW.email, 1000)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers that run in the correct order
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER create_profile_after_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_user();

-- Fix any existing users
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Update metadata for all whitelisted users
  FOR r IN 
    SELECT u.id, u.email
    FROM auth.users u
    JOIN whitelist w ON u.email = w.email
  LOOP
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
END $$;