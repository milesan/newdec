-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS maintain_user_auth_trigger ON applications;
DROP FUNCTION IF EXISTS maintain_user_auth();

-- Create a function to handle auth setup when application is approved
CREATE OR REPLACE FUNCTION maintain_user_auth()
RETURNS trigger AS $$
DECLARE
  v_user_email text;
BEGIN
  -- Only proceed if status is changing to approved
  IF TG_OP = 'UPDATE' AND NEW.status = 'approved' AND OLD.status != 'approved' THEN
    -- Get user email
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = NEW.user_id;

    -- Update user auth setup
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
    WHERE id = NEW.user_id;

    -- Ensure proper identity record exists
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
      NEW.user_id,
      v_user_email,  -- Use email as provider_id
      'email',
      jsonb_build_object(
        'sub', NEW.user_id::text,
        'email', v_user_email,
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
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER maintain_user_auth_trigger
  AFTER UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION maintain_user_auth();

-- Fix any existing approved applications
DO $$
DECLARE
  r RECORD;
  v_user_email text;
BEGIN
  FOR r IN 
    SELECT * FROM applications 
    WHERE status = 'approved'
  LOOP
    -- Get user email
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = r.user_id;

    -- Update user auth setup
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
    WHERE id = r.user_id;

    -- Ensure proper identity record exists
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
      r.user_id,
      v_user_email,  -- Use email as provider_id
      'email',
      jsonb_build_object(
        'sub', r.user_id::text,
        'email', v_user_email,
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
  END LOOP;
END $$;