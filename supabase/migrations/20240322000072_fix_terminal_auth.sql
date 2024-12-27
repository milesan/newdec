-- Drop existing function
DROP FUNCTION IF EXISTS create_terminal_user;

-- Create a function to handle terminal user creation with simpler auth
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

  -- Generate UUID
  v_user_id := gen_random_uuid();

  -- Create user
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
      'has_applied', false,
      'is_admin', v_email = 'andre@thegarden.pt'
    ),
    'authenticated',
    'authenticated',
    now(),
    now()
  );

  -- Create identity
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
    v_user_id,
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

  -- Return user info
  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'email', v_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_terminal_user TO anon;
GRANT EXECUTE ON FUNCTION create_terminal_user TO authenticated;

-- Ensure auth schema permissions
GRANT USAGE ON SCHEMA auth TO postgres, authenticated, anon;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO authenticated, anon;