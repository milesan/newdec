-- Create a function to properly handle application approval and user auth
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_user_id uuid;
  v_email text;
BEGIN
  -- Get the user_id and email from the application
  SELECT a.user_id, u.email INTO v_user_id, v_email
  FROM applications a
  JOIN auth.users u ON a.user_id = u.id
  WHERE a.id = p_application_id;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Ensure user is properly set up in auth system
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    raw_app_meta_data = jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    raw_user_meta_data = '{}',
    aud = 'authenticated',
    role = 'authenticated',
    updated_at = now()
  WHERE id = v_user_id;

  -- Ensure user has an identity record
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    v_user_id,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    'email',
    now(),
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    identity_data = jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    updated_at = now();

  -- Remove from whitelist if they were on it
  DELETE FROM whitelist 
  WHERE user_id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update all existing approved applications to ensure proper auth setup
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM applications WHERE status = 'approved'
  LOOP
    PERFORM approve_application(r.id);
  END LOOP;
END $$;