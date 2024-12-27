-- Drop existing functions and views
DROP FUNCTION IF EXISTS create_user_and_submit_application CASCADE;
DROP VIEW IF EXISTS application_details CASCADE;

-- Create a more robust function for handling application submission
CREATE OR REPLACE FUNCTION create_user_and_submit_application(
  p_email text,
  p_password text,
  p_data jsonb,
  p_linked_name text DEFAULT NULL,
  p_linked_email text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_user_id uuid;
  v_application applications;
BEGIN
  -- Generate a new UUID for the user
  v_user_id := gen_random_uuid();

  -- Create the user
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    '{}'::jsonb,
    'authenticated',
    'authenticated',
    now(),
    now()
  );

  -- Create profile
  INSERT INTO profiles (id, email)
  VALUES (v_user_id, p_email);

  -- Submit application
  INSERT INTO applications (
    user_id,
    data,
    status,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_data,
    'pending',
    now(),
    now()
  )
  RETURNING * INTO v_application;

  -- Handle linked application if provided
  IF p_linked_name IS NOT NULL AND p_linked_email IS NOT NULL THEN
    INSERT INTO linked_applications (
      primary_application_id,
      linked_name,
      linked_email,
      created_at
    ) VALUES (
      v_application.id,
      p_linked_name,
      p_linked_email,
      now()
    );
  END IF;

  -- Remove from whitelist if they were on it
  DELETE FROM whitelist WHERE email = p_email;

  -- Return the result
  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'application_id', v_application.id
  );

EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Email already exists';
  WHEN others THEN
    RAISE EXCEPTION 'Failed to create user: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a view for applications with all related data
CREATE VIEW application_details AS
SELECT 
  a.*,
  u.email as user_email,
  la.linked_name,
  la.linked_email,
  la2.id as linked_application_id,
  u2.email as linked_user_email
FROM applications a
JOIN auth.users u ON a.user_id = u.id
LEFT JOIN linked_applications la ON a.id = la.primary_application_id
LEFT JOIN applications la2 ON la.linked_application_id = la2.id
LEFT JOIN auth.users u2 ON la2.user_id = u2.id;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO anon;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;
GRANT SELECT ON application_details TO authenticated;