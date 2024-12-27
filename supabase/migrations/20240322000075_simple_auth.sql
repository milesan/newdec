-- Drop existing functions and tables
DROP FUNCTION IF EXISTS create_terminal_user;

-- Create a simple function to handle user creation
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