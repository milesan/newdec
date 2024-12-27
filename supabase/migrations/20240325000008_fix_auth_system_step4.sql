-- Update existing users' metadata if they're whitelisted
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT u.id, u.email
    FROM auth.users u
    JOIN whitelist w ON u.email = w.email
  LOOP
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved'
    )
    WHERE id = r.id;
    
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = r.email;
  END LOOP;
END $$;