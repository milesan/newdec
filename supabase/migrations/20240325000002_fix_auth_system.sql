-- Drop existing triggers and functions with CASCADE
DROP TRIGGER IF EXISTS on_auth_sign_in ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_whitelist_login() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_sign_in() CASCADE;

-- Create a more robust function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, email, credits)
  VALUES (new.id, new.email, 1000);

  -- Check if user is whitelisted
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = new.email) THEN
    -- Update user metadata for whitelisted users
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
    -- Set default metadata for non-whitelisted users
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
  UPDATE whitelist 
  SET last_login = now()
  WHERE email = NEW.email;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for sign ins
CREATE TRIGGER on_auth_sign_in
  BEFORE UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_sign_in();

-- Ensure proper indexes exist
CREATE INDEX IF NOT EXISTS idx_whitelist_email ON whitelist(email);
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;
GRANT ALL ON whitelist TO authenticated;
GRANT EXECUTE ON FUNCTION handle_new_user TO authenticated;
GRANT EXECUTE ON FUNCTION handle_sign_in TO authenticated;