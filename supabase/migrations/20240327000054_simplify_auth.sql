-- SIMPLIFIED AUTH SYSTEM: Reset and rebuild

-- 1. Drop everything to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP TABLE IF EXISTS whitelist CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 2. Create profiles table
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  email text NOT NULL,
  credits integer NOT NULL DEFAULT 1000,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 3. Create indexes
CREATE INDEX idx_profiles_id ON profiles(id);
CREATE INDEX idx_profiles_email ON profiles(email);

-- 4. Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 5. Create policies
CREATE POLICY "Users can read their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- 6. Create function to handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Set app metadata
  NEW.raw_app_meta_data := jsonb_build_object(
    'provider', 'email',
    'providers', array['email']
  );

  -- Handle admin user
  IF NEW.email = 'andre@thegarden.pt' THEN
    NEW.raw_user_meta_data := jsonb_build_object(
      'is_admin', true,
      'application_status', 'approved',
      'has_applied', true
    );
    NEW.email_confirmed_at := now();
  ELSE
    -- Regular users start with no application
    NEW.raw_user_meta_data := jsonb_build_object(
      'has_applied', false,
      'application_status', null
    );
  END IF;

  -- Create profile
  BEGIN
    INSERT INTO public.profiles (id, email, credits)
    VALUES (NEW.id, NEW.email, 1000);
  EXCEPTION WHEN others THEN
    RAISE WARNING 'Could not create profile: %', SQLERRM;
  END;

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

-- 9. Fix existing users
DO $$
BEGIN
  -- Reset all users to base state
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object(
    'has_applied', false,
    'application_status', null
  );

  -- Fix admin user
  UPDATE auth.users
  SET 
    raw_user_meta_data = jsonb_build_object(
      'is_admin', true,
      'application_status', 'approved',
      'has_applied', true
    ),
    email_confirmed_at = now()
  WHERE email = 'andre@thegarden.pt';

  -- Fix users with approved applications
  UPDATE auth.users u
  SET 
    raw_user_meta_data = jsonb_build_object(
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