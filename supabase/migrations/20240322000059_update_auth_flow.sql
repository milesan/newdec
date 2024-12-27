-- Drop existing functions
DROP FUNCTION IF EXISTS create_user_and_submit_application;
DROP FUNCTION IF EXISTS approve_application;

-- Create a function to handle application submission
CREATE OR REPLACE FUNCTION submit_application(
  p_user_id uuid,
  p_data jsonb
) RETURNS jsonb AS $$
DECLARE
  v_application applications;
BEGIN
  -- Create application
  INSERT INTO applications (
    user_id,
    data,
    status
  ) VALUES (
    p_user_id,
    p_data,
    'pending'
  )
  RETURNING * INTO v_application;

  -- Update user metadata
  UPDATE auth.users
  SET 
    raw_user_metadata = raw_user_metadata || jsonb_build_object('has_applied', true)
  WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'application_id', v_application.id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to approve applications
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get user_id from application
  SELECT user_id INTO v_user_id
  FROM applications
  WHERE id = p_application_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Application not found';
  END IF;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Update user metadata
  UPDATE auth.users
  SET 
    raw_user_metadata = raw_user_metadata || 
      jsonb_build_object(
        'approved', true,
        'has_applied', true
      ),
    email_confirmed_at = now(),
    updated_at = now()
  WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION submit_application TO authenticated;
GRANT EXECUTE ON FUNCTION approve_application TO authenticated;