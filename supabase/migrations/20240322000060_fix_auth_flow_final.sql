-- First, ensure admin user exists and has proper permissions
DO $$
DECLARE
  v_admin_id uuid;
BEGIN
  -- Create admin user if not exists
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'andre@thegarden.pt',
    crypt('admin', gen_salt('bf')), -- You'll need to set the actual password
    now(),
    jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    jsonb_build_object(
      'approved', true,
      'is_admin', true
    ),
    true,
    now(),
    now()
  )
  ON CONFLICT (email) DO UPDATE
  SET 
    raw_user_meta_data = jsonb_build_object(
      'approved', true,
      'is_admin', true
    ),
    is_super_admin = true,
    email_confirmed_at = COALESCE(auth.users.email_confirmed_at, now())
  RETURNING id INTO v_admin_id;

  -- Ensure admin has proper identity record
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
    v_admin_id,
    'andre@thegarden.pt',
    'email',
    jsonb_build_object(
      'sub', v_admin_id::text,
      'email', 'andre@thegarden.pt',
      'email_verified', true,
      'provider', 'email'
    ),
    now(),
    now(),
    now()
  )
  ON CONFLICT (provider, provider_id) DO UPDATE
  SET 
    identity_data = EXCLUDED.identity_data,
    updated_at = now();
END $$;

-- Update is_admin function to check for admin user
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1 
      FROM auth.users 
      WHERE id = auth.uid() 
      AND email = 'andre@thegarden.pt'
      AND (raw_user_meta_data->>'is_admin')::boolean = true
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to handle user creation from terminal
CREATE OR REPLACE FUNCTION create_terminal_user(
  p_username text,
  p_password text
) RETURNS jsonb AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Generate email from username
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
    p_username || '@thegarden.local',
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
    p_username || '@thegarden.local',
    'email',
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', p_username || '@thegarden.local',
      'email_verified', true,
      'provider', 'email'
    ),
    now(),
    now(),
    now()
  );

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'email', p_username || '@thegarden.local'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to handle application submission
CREATE OR REPLACE FUNCTION submit_application(
  p_data jsonb,
  p_linked_name text DEFAULT NULL,
  p_linked_email text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_user_id uuid;
  v_application applications;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Create application
  INSERT INTO applications (
    user_id,
    data,
    status
  ) VALUES (
    v_user_id,
    p_data,
    'pending'
  )
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

  -- Update user metadata
  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('has_applied', true)
  WHERE id = v_user_id;

  RETURN jsonb_build_object(
    'application_id', v_application.id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION create_terminal_user TO anon;
GRANT EXECUTE ON FUNCTION submit_application TO authenticated;