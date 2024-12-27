-- Drop existing function
DROP FUNCTION IF EXISTS create_user_and_submit_application;

-- Create the function with proper user creation and auth
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
  v_user_id := extensions.uuid_generate_v4();
  
  -- Insert into auth.users with proper role and metadata
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    aud,
    role,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    'authenticated',
    'authenticated',
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

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

  -- Create a new session for the user
  INSERT INTO auth.sessions (
    id,
    user_id,
    created_at,
    updated_at
  ) VALUES (
    extensions.uuid_generate_v4(),
    v_user_id,
    now(),
    now()
  );

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

-- Ensure UUID extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO anon;