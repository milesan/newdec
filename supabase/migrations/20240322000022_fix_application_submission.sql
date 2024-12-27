-- Drop existing function
DROP FUNCTION IF EXISTS create_user_and_submit_application;

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
  -- Create the user
  INSERT INTO auth.users (
    email,
    raw_user_meta_data,
    raw_app_meta_data,
    aud,
    role
  ) VALUES (
    p_email,
    '{}'::jsonb,
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    'authenticated',
    'authenticated'
  )
  RETURNING id INTO v_user_id;

  -- Set the password
  UPDATE auth.users
  SET encrypted_password = crypt(p_password, gen_salt('bf'))
  WHERE id = v_user_id;

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

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'application_id', v_application.id
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Email already exists';
  WHEN others THEN
    -- Log the error details
    RAISE NOTICE 'Error creating user/application: %', SQLERRM;
    RAISE EXCEPTION 'Failed to create user/application: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO anon;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;