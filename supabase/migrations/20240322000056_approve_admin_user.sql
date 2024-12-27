-- Ensure admin user is properly set up and approved
DO $$
DECLARE
  v_admin_id uuid;
BEGIN
  -- Get admin user ID
  SELECT id INTO v_admin_id
  FROM auth.users
  WHERE email = 'andre@thegarden.pt';

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Admin user not found';
  END IF;

  -- Update admin user metadata and approval status
  UPDATE auth.users
  SET 
    raw_app_meta_data = jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    raw_user_meta_data = jsonb_build_object('approved', true),
    aud = 'authenticated',
    role = 'authenticated',
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    updated_at = now()
  WHERE id = v_admin_id;

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

  -- Create or update admin application if needed
  INSERT INTO applications (
    user_id,
    data,
    status,
    created_at,
    updated_at
  ) VALUES (
    v_admin_id,
    '{"admin": true}'::jsonb,
    'approved',
    now(),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET 
    status = 'approved',
    updated_at = now();
END $$;