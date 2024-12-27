-- Drop existing function
DROP FUNCTION IF EXISTS create_terminal_user;

-- Create a function to handle terminal user creation
CREATE OR REPLACE FUNCTION create_terminal_user(
  p_username text,
  p_password text
) RETURNS jsonb AS $$
#variable_conflict use_column
DECLARE
  v_user_id uuid;
  v_email text;
BEGIN
  -- Generate email from username
  v_email := p_username || '@thegarden.local';

  -- Check if email exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    RAISE EXCEPTION 'Username already exists';
  END IF;

  -- Generate user ID
  v_user_id := gen_random_uuid();

  -- Create user with minimal required fields
  INSERT INTO auth.users (
    id,
    instance_id,
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
    '00000000-0000-0000-0000-000000000000',
    v_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    jsonb_build_object(
      'username', p_username,
      'has_applied', false
    ),
    'authenticated',
    'authenticated',
    now(),
    now()
  );

  -- Create identity record
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    provider,
    identity_data,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    v_email,
    'email',
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', v_email,
      'email_verified', true,
      'provider', 'email'
    ),
    now(),
    now(),
    now()
  );

  -- Create profile
  INSERT INTO profiles (id, email)
  VALUES (v_user_id, v_email);

  -- Add to whitelist
  INSERT INTO whitelist (user_id, email)
  VALUES (v_user_id, v_email);

  -- Return user info
  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'email', v_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop other user creation functions
DROP FUNCTION IF EXISTS create_user_and_submit_application CASCADE;
DROP FUNCTION IF EXISTS submit_application CASCADE;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_terminal_user TO anon;
GRANT EXECUTE ON FUNCTION create_terminal_user TO authenticated;