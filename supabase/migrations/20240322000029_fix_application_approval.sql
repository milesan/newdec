-- Create a function to handle application approval
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get the user_id from the application
  SELECT user_id INTO v_user_id
  FROM applications
  WHERE id = p_application_id;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Confirm the user's email if not already confirmed
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    updated_at = now()
  WHERE id = v_user_id;

  -- Remove from whitelist if they were on it
  DELETE FROM whitelist 
  WHERE user_id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION approve_application TO authenticated;

-- Update the existing approved applications
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM applications WHERE status = 'approved'
  LOOP
    PERFORM approve_application(r.id);
  END LOOP;
END $$;