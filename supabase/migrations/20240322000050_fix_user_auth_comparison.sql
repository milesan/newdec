-- First, let's check and fix the admin user
DO $$
DECLARE
  v_admin_id uuid;
  v_admin_identity_id uuid;
BEGIN
  -- Get admin user details
  SELECT id INTO v_admin_id
  FROM auth.users
  WHERE email = 'andre@thegarden.pt';

  IF v_admin_id IS NOT NULL THEN
    -- Check admin's identity record
    SELECT id INTO v_admin_identity_id
    FROM auth.identities
    WHERE user_id = v_admin_id;

    -- If no identity exists, create one
    IF v_admin_identity_id IS NULL THEN
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
      );
    END IF;

    -- Update admin user metadata
    UPDATE auth.users
    SET 
      raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', ARRAY['email']
      ),
      raw_user_meta_data = jsonb_build_object('approved', true),
      aud = 'authenticated',
      role = 'authenticated',
      email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = v_admin_id;
  END IF;
END $$;

-- Create a function to fix user auth setup
CREATE OR REPLACE FUNCTION fix_user_auth(p_email text)
RETURNS void AS $$
DECLARE
  v_user_id uuid;
  v_has_application boolean;
  v_application_status text;
BEGIN
  -- Get user ID
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- Check if user has an approved application
  SELECT 
    EXISTS(SELECT 1 FROM applications WHERE user_id = v_user_id) as has_app,
    (SELECT status FROM applications WHERE user_id = v_user_id LIMIT 1) as app_status
  INTO v_has_application, v_application_status;

  -- Fix identity record
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
    p_email,
    'email',
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', p_email,
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

  -- Update user metadata based on application status
  UPDATE auth.users
  SET 
    raw_app_meta_data = jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    raw_user_meta_data = jsonb_build_object(
      'approved', CASE 
        WHEN v_has_application AND v_application_status = 'approved' THEN true
        ELSE false
      END
    ),
    aud = 'authenticated',
    role = 'authenticated',
    email_confirmed_at = CASE 
      WHEN v_has_application AND v_application_status = 'approved' THEN now()
      ELSE null
    END,
    updated_at = now()
  WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix specific user
SELECT fix_user_auth('net@net.net');

-- Create a trigger to maintain proper auth setup
CREATE OR REPLACE FUNCTION maintain_user_auth()
RETURNS trigger AS $$
BEGIN
  -- When application is approved
  IF TG_OP = 'UPDATE' AND NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Update user auth setup
    UPDATE auth.users
    SET 
      raw_user_meta_data = jsonb_build_object('approved', true),
      email_confirmed_at = now()
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS maintain_user_auth_trigger ON applications;
CREATE TRIGGER maintain_user_auth_trigger
  AFTER UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION maintain_user_auth();