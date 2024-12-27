-- First, clean up any duplicate entries
DELETE FROM whitelist w
WHERE EXISTS (
  SELECT 1 
  FROM applications a 
  WHERE a.user_id = w.user_id
);

-- Create a function to properly populate user data
CREATE OR REPLACE FUNCTION fix_user_data() RETURNS void AS $$
DECLARE
  v_user RECORD;
  v_application RECORD;
BEGIN
  -- Loop through all users
  FOR v_user IN 
    SELECT id, email 
    FROM auth.users 
    WHERE email != 'andre@thegarden.pt' -- Skip admin
  LOOP
    -- Check if user has an application
    SELECT * INTO v_application
    FROM applications 
    WHERE user_id = v_user.id;

    IF v_application.id IS NOT NULL THEN
      -- Remove from whitelist if they have an application
      DELETE FROM whitelist 
      WHERE user_id = v_user.id 
      OR email = v_user.email;
    ELSE
      -- Add to whitelist if they don't have an application
      INSERT INTO whitelist (user_id, email, notes)
      VALUES (
        v_user.id, 
        v_user.email,
        'Auto-populated from existing user'
      )
      ON CONFLICT (email) DO NOTHING;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the fix
SELECT fix_user_data();

-- Drop the function as it's no longer needed
DROP FUNCTION fix_user_data();

-- Update the trigger to handle this logic for new users
CREATE OR REPLACE FUNCTION handle_new_user_whitelist() 
RETURNS trigger AS $$
BEGIN
  -- Only add to whitelist if user doesn't have an application
  IF NOT EXISTS (
    SELECT 1 
    FROM applications 
    WHERE user_id = NEW.id
  ) THEN
    INSERT INTO whitelist (user_id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (email) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_whitelist ON auth.users;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created_whitelist
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user_whitelist();