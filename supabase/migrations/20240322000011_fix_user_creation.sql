-- Drop existing function if it exists
DROP FUNCTION IF EXISTS create_user_and_submit_application;

-- Create the function with proper parameters and error handling
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
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  )
  RETURNING id INTO v_user_id;

  -- Create profile
  INSERT INTO profiles (id, email)
  VALUES (v_user_id, p_email);

  -- Submit application
  INSERT INTO applications (user_id, data, status)
  VALUES (v_user_id, p_data, 'pending')
  RETURNING * INTO v_application;

  -- Handle linked application if provided
  IF p_linked_name IS NOT NULL AND p_linked_email IS NOT NULL THEN
    INSERT INTO linked_applications (
      primary_application_id,
      linked_name,
      linked_email
    ) VALUES (
      v_application.id,
      p_linked_name,
      p_linked_email
    );
  END IF;

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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;