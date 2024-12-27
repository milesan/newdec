-- First, clean up any problematic identities
DELETE FROM auth.identities
WHERE provider_id IS NULL OR provider_id = '';

-- Fix all approved users
DO $$
DECLARE
  r RECORD;
  v_identity_id uuid;
BEGIN
  -- Get all approved applications and their users
  FOR r IN 
    SELECT DISTINCT u.id, u.email
    FROM applications a
    JOIN auth.users u ON a.user_id = u.id
    WHERE a.status = 'approved'
  LOOP
    -- Generate new identity ID
    v_identity_id := gen_random_uuid();

    -- Delete any existing identities for this user
    DELETE FROM auth.identities
    WHERE user_id = r.id;

    -- Create new identity
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
      r.id,
      r.email,  -- Use email as provider_id for consistency
      'email',
      jsonb_build_object(
        'sub', r.id::text,
        'email', r.email,
        'email_verified', true,
        'provider', 'email'
      ),
      now(),
      now(),
      now()
    );

    -- Update user metadata
    UPDATE auth.users
    SET 
      raw_app_meta_data = '{"provider": "email", "providers": ["email"]}'::jsonb,
      raw_user_meta_data = '{}'::jsonb,
      aud = 'authenticated',
      role = 'authenticated',
      updated_at = now(),
      email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = r.id;
  END LOOP;
END $$;