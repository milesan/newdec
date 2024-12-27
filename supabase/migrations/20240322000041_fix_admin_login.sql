-- First, clean up any problematic identities
DELETE FROM auth.identities
WHERE provider_id IS NULL OR provider_id = '';

-- Fix admin user specifically
DO $$
DECLARE
  v_admin_id uuid;
  v_identity_id uuid;
BEGIN
  -- Get admin user ID
  SELECT id INTO v_admin_id
  FROM auth.users
  WHERE email = 'andre@thegarden.pt';

  IF v_admin_id IS NOT NULL THEN
    -- Generate new identity ID
    v_identity_id := gen_random_uuid();

    -- Delete any existing identities for admin
    DELETE FROM auth.identities
    WHERE user_id = v_admin_id;

    -- Create new identity for admin
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
      v_identity_id,
      v_admin_id,
      'andre@thegarden.pt',  -- Use email as provider_id for consistency
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

    -- Update admin user metadata
    UPDATE auth.users
    SET 
      raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
      raw_user_meta_data = '{}'::jsonb,
      aud = 'authenticated',
      role = 'authenticated',
      updated_at = now(),
      email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = v_admin_id;
  END IF;
END $$;</content>