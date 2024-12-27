-- First, ensure all auth tables have proper indexes
CREATE INDEX IF NOT EXISTS identities_user_id_idx ON auth.identities(user_id);
CREATE INDEX IF NOT EXISTS identities_provider_provider_id_idx ON auth.identities(provider, provider_id);

-- Fix any existing users that might have incorrect auth setup
DO $$
DECLARE
  r RECORD;
BEGIN
  -- Loop through all users
  FOR r IN 
    SELECT u.id, u.email, u.encrypted_password
    FROM auth.users u
    WHERE u.email != 'andre@thegarden.pt'
  LOOP
    -- Update user record with proper metadata
    UPDATE auth.users SET
      raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', ARRAY['email']
      ),
      raw_user_meta_data = '{}'::jsonb,
      aud = 'authenticated',
      role = 'authenticated',
      updated_at = now(),
      email_confirmed_at = COALESCE(email_confirmed_at, now())
    WHERE id = r.id;

    -- Ensure proper identity record exists
    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      r.email,
      r.id,
      jsonb_build_object(
        'sub', r.id::text,
        'email', r.email,
        'email_verified', true,
        'provider', 'email'
      ),
      'email',
      now(),
      now(),
      now()
    )
    ON CONFLICT (provider, provider_id) DO UPDATE
    SET 
      identity_data = jsonb_build_object(
        'sub', EXCLUDED.user_id::text,
        'email', r.email,
        'email_verified', true,
        'provider', 'email'
      ),
      updated_at = now();
  END LOOP;
END $$;

-- Create a trigger to ensure proper auth setup on user creation
CREATE OR REPLACE FUNCTION ensure_proper_auth_setup()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure proper identity record exists
  INSERT INTO auth.identities (
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    NEW.email,
    NEW.id,
    jsonb_build_object(
      'sub', NEW.id::text,
      'email', NEW.email,
      'email_verified', true,
      'provider', 'email'
    ),
    'email',
    now(),
    now(),
    now()
  )
  ON CONFLICT (provider, provider_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS ensure_auth_setup ON auth.users;
CREATE TRIGGER ensure_auth_setup
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_proper_auth_setup();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO postgres, authenticated, anon;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO authenticated, anon;