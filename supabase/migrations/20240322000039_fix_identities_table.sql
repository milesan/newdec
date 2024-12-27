-- First, clean up any problematic identities
DELETE FROM auth.identities
WHERE provider_id IS NULL;

-- Add NOT NULL constraint to provider_id if it doesn't exist
ALTER TABLE auth.identities 
ALTER COLUMN provider_id SET NOT NULL;

-- Create a function to fix existing users' identities
CREATE OR REPLACE FUNCTION fix_user_identities()
RETURNS void AS $$
DECLARE
  r RECORD;
BEGIN
  -- Loop through all users
  FOR r IN 
    SELECT id, email 
    FROM auth.users 
    WHERE email != 'andre@thegarden.pt'
  LOOP
    -- Delete any problematic identities for this user
    DELETE FROM auth.identities 
    WHERE user_id = r.id;

    -- Create a new clean identity record
    INSERT INTO auth.identities (
      id,
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
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
    ON CONFLICT (provider, provider_id) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the fix
SELECT fix_user_identities();

-- Drop the function as it's no longer needed
DROP FUNCTION fix_user_identities();

-- Create a trigger to ensure identities are always created properly
CREATE OR REPLACE FUNCTION ensure_user_identity()
RETURNS TRIGGER AS $$
BEGIN
  -- Create identity record if it doesn't exist
  INSERT INTO auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
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
DROP TRIGGER IF EXISTS ensure_user_identity ON auth.users;
CREATE TRIGGER ensure_user_identity
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_identity();