-- Add username field to auth.users metadata
ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS raw_user_metadata jsonb DEFAULT '{}'::jsonb;

-- Create a function to handle user creation with username
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Extract username from email (before @thegarden.local)
  NEW.raw_user_metadata = jsonb_build_object(
    'username', split_part(NEW.email, '@', 1),
    'has_applied', false
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Update application submission to mark user as having applied
CREATE OR REPLACE FUNCTION mark_user_applied()
RETURNS trigger AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_metadata = raw_user_metadata || '{"has_applied": true}'::jsonb
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for application submission
DROP TRIGGER IF EXISTS on_application_submitted ON applications;
CREATE TRIGGER on_application_submitted
  AFTER INSERT ON applications
  FOR EACH ROW
  EXECUTE FUNCTION mark_user_applied();