-- Drop existing function
DROP FUNCTION IF EXISTS create_user_and_submit_application;

-- Create the function with proper identity handling
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
  -- Check if email already exists
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE email = p_email
  ) THEN
    RAISE EXCEPTION 'Email already exists';
  END IF;

  -- Check if identity already exists
  IF EXISTS (
    SELECT 1 FROM auth.identities 
    WHERE provider = 'email' 
    AND provider_id = p_email
  ) THEN
    RAISE EXCEPTION 'Email already exists';
  END IF;

  -- Generate user ID
  v_user_id := gen_random_uuid();

  -- Create the user with minimal required fields
  INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    instance_id,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{}'::jsonb,
    'authenticated',
    'authenticated',
    '00000000-0000-0000-0000-000000000000',
    now(),
    now()
  );

  -- Create identity record with proper provider_id
  INSERT INTO auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),  -- Generate a new UUID for identity
    p_email,  -- Use email as provider_id
    v_user_id,
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', p_email,
      'email_verified', true,
      'provider', 'email'
    ),
    'email',
    now(),
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

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'application_id', v_application.id
  );

EXCEPTION
  WHEN unique_violation THEN
    -- Check which constraint was violated
    IF EXISTS (
      SELECT 1 FROM auth.users WHERE email = p_email
    ) OR EXISTS (
      SELECT 1 FROM auth.identities 
      WHERE provider = 'email' 
      AND provider_id = p_email
    ) THEN
      RAISE EXCEPTION 'Email already exists';
    ELSE
      RAISE EXCEPTION 'Failed to create user: %', SQLERRM;
    END IF;
  WHEN others THEN
    RAISE EXCEPTION 'Failed to create user/application: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO anon;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;