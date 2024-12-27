-- First, ensure we can drop the triggers safely
DROP TRIGGER IF EXISTS on_auth_sign_in ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;

-- Drop existing functions with CASCADE to remove dependencies
DROP FUNCTION IF EXISTS handle_whitelist_login() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_sign_in() CASCADE;

-- Create a simpler profiles trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, credits)
  VALUES (new.id, new.email, 1000);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON auth.users TO authenticated;