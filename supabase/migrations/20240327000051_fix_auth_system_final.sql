-- FINAL AUTH FIX: Complete reset and proper order of operations

-- 1. First, drop everything to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP TABLE IF EXISTS whitelist CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 2. Create tables first (order matters!)
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  email text NOT NULL,
  credits integer NOT NULL DEFAULT 1000,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false
);

-- 3. Create indexes BEFORE enabling RLS
CREATE INDEX idx_profiles_id ON profiles(id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_whitelist_email ON whitelist(email);

-- 4. Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- 5. Create policies
CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- 6. Create function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, email, credits)
  VALUES (NEW.id, NEW.email, 1000);

  -- Set app metadata
  NEW.raw_app_meta_data := jsonb_build_object(
    'provider', 'email',
    'providers', array['email']
  );

  -- Handle admin user
  IF NEW.email = 'andre@thegarden.pt' THEN
    NEW.raw_user_meta_data := jsonb_build_object(
      'is_admin', true,
      'is_whitelisted', true,
      'has_seen_welcome', true,
      'application_status', 'approved',
      'has_applied', true
    );
    NEW.email_confirmed_at := now();
    RETURN NEW;
  END IF;

  -- Handle whitelisted users
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    NEW.raw_user_meta_data := jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true  -- This ensures they bypass RetroApp
    );
    NEW.email_confirmed_at := now();
    
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = NEW.email;
  ELSE
    -- Non-whitelisted users
    NEW.raw_user_meta_data := jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', false,
      'application_status', null
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 8. Grant permissions
GRANT ALL ON profiles TO authenticated;
GRANT ALL ON whitelist TO authenticated;

-- 9. CRITICAL: Add admin to whitelist FIRST
INSERT INTO whitelist (email, notes, has_seen_welcome)
VALUES ('andre@thegarden.pt', 'Admin user', true)
ON CONFLICT (email) DO UPDATE SET 
  has_seen_welcome = true;

-- 10. Fix ALL existing users
DO $$
DECLARE
  r RECORD;
BEGIN
  -- First, reset ALL user metadata to a known state
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object(
    'is_whitelisted', false,
    'has_applied', false,
    'application_status', null
  );

  -- Fix admin user
  UPDATE auth.users
  SET 
    raw_user_meta_data = jsonb_build_object(
      'is_admin', true,
      'is_whitelisted', true,
      'has_seen_welcome', true,
      'application_status', 'approved',
      'has_applied', true
    ),
    email_confirmed_at = now()
  WHERE email = 'andre@thegarden.pt';

  -- Fix whitelisted users
  UPDATE auth.users u
  SET 
    raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true  -- This ensures they bypass RetroApp
    ),
    email_confirmed_at = now()
  FROM whitelist w
  WHERE u.email = w.email
  AND u.email != 'andre@thegarden.pt';

  -- Fix users with approved applications
  UPDATE auth.users u
  SET 
    raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', true,
      'application_status', 'approved'
    ),
    email_confirmed_at = now()
  FROM applications a
  WHERE u.id = a.user_id
  AND a.status = 'approved'
  AND u.email != 'andre@thegarden.pt';

  -- Fix users with pending applications
  UPDATE auth.users u
  SET raw_user_meta_data = jsonb_build_object(
    'is_whitelisted', false,
    'has_applied', true,
    'application_status', 'pending'
  )
  FROM applications a
  WHERE u.id = a.user_id
  AND a.status = 'pending'
  AND u.email != 'andre@thegarden.pt';

  -- Fix users with rejected applications
  UPDATE auth.users u
  SET raw_user_meta_data = jsonb_build_object(
    'is_whitelisted', false,
    'has_applied', true,
    'application_status', 'rejected'
  )
  FROM applications a
  WHERE u.id = a.user_id
  AND a.status = 'rejected'
  AND u.email != 'andre@thegarden.pt';

  -- Ensure all users have profiles
  INSERT INTO profiles (id, email, credits)
  SELECT id, email, 1000
  FROM auth.users
  ON CONFLICT (id) DO NOTHING;
END $$;