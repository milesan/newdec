-- Drop existing function
DROP FUNCTION IF EXISTS create_terminal_user;

-- Create a simplified function to handle user creation
CREATE OR REPLACE FUNCTION create_terminal_user(
  p_username text,
  p_password text
) RETURNS jsonb AS $$
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
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    aud,
    role,
    created_at,
    updated_at,
    instance_id,
    confirmation_token
  ) VALUES (
    v_user_id,
    v_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'has_applied', false,
      'is_admin', v_email = 'andre@thegarden.pt'
    ),
    'authenticated',
    'authenticated',
    now(),
    now(),
    '00000000-0000-0000-0000-000000000000',
    encode(gen_random_bytes(32), 'base64')
  );

  -- Create profile
  INSERT INTO profiles (id, email)
  VALUES (v_user_id, v_email);

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'email', v_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_terminal_user TO anon;
GRANT EXECUTE ON FUNCTION create_terminal_user TO authenticated;