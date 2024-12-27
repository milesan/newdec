-- Create a function to populate user data
CREATE OR REPLACE FUNCTION populate_user_data() RETURNS void AS $$
DECLARE
  v_user RECORD;
  v_has_application boolean;
BEGIN
  -- Loop through all users
  FOR v_user IN 
    SELECT id, email 
    FROM auth.users 
    WHERE email != 'andre@thegarden.pt' -- Skip admin
  LOOP
    -- Check if user has an application
    SELECT EXISTS (
      SELECT 1 
      FROM applications 
      WHERE user_id = v_user.id
    ) INTO v_has_application;

    -- If user doesn't have an application, add them to whitelist
    IF NOT v_has_application THEN
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

-- Run the population function
SELECT populate_user_data();

-- Drop the function as it's no longer needed
DROP FUNCTION populate_user_data();

-- Create a trigger to automatically whitelist new users without applications
CREATE OR REPLACE FUNCTION handle_new_user_whitelist() 
RETURNS trigger AS $$
BEGIN
  -- If the new user doesn't have an application, add them to whitelist
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

CREATE TRIGGER on_auth_user_created_whitelist
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user_whitelist();