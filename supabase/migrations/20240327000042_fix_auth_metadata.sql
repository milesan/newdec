-- First, ensure we have the correct structure
CREATE TABLE IF NOT EXISTS whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false,
  has_created_account boolean DEFAULT false,
  account_created_at timestamp with time zone
);

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

-- Create updated function to properly handle new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Create profile
  INSERT INTO public.profiles (id, email, credits)
  VALUES (NEW.id, NEW.email, 1000);

  -- Set app metadata
  NEW.raw_app_meta_data = jsonb_build_object(
    'provider', 'email',
    'providers', ARRAY['email']
  );

  -- Special case for admin - handle this FIRST
  IF NEW.email = 'andre@thegarden.pt' THEN
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_admin', true,
      'is_whitelisted', true,
      'has_seen_welcome', true,
      'application_status', 'approved',
      'has_applied', true
    );
    NEW.email_confirmed_at = now();
    RETURN NEW;
  END IF;

  -- Then handle regular whitelisted users
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    -- CRITICAL: Set has_applied to true to prevent RetroApp redirect
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true  -- This is crucial to bypass RetroApp
    );
    NEW.email_confirmed_at = now();
    
    UPDATE whitelist 
    SET 
      last_login = now(),
      has_created_account = true,
      account_created_at = now()
    WHERE email = NEW.email;
  ELSE
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', false,
      'has_applied', false,
      'application_status', null
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Fix ALL existing users
DO $$
BEGIN
  -- Fix admin user first
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object(
    'is_admin', true,
    'is_whitelisted', true,
    'has_seen_welcome', true,
    'application_status', 'approved',
    'has_applied', true
  )
  WHERE email = 'andre@thegarden.pt';

  -- Fix whitelisted users - CRITICAL: Set has_applied to true
  UPDATE auth.users u
  SET 
    raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved',
      'has_applied', true  -- This ensures they bypass RetroApp
    ),
    email_confirmed_at = COALESCE(email_confirmed_at, now())
  FROM whitelist w
  WHERE u.email = w.email
  AND u.email != 'andre@thegarden.pt';

  -- Fix non-whitelisted users
  UPDATE auth.users u
  SET raw_user_meta_data = jsonb_build_object(
    'is_whitelisted', false,
    'has_applied', false,
    'application_status', null
  )
  WHERE NOT EXISTS (
    SELECT 1 FROM whitelist w 
    WHERE w.email = u.email
  )
  AND email != 'andre@thegarden.pt';

  -- Update whitelist records
  UPDATE whitelist w
  SET 
    has_created_account = true,
    account_created_at = u.created_at,
    last_login = u.last_sign_in_at
  FROM auth.users u
  WHERE w.email = u.email;
END $$;