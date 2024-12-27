-- First, clean up existing tables
DROP TABLE IF EXISTS linked_applications CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS whitelist CASCADE;

-- Create applications table
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create linked applications table
CREATE TABLE linked_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  linked_name text NOT NULL,
  linked_email text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create a function to handle application submission and user creation
CREATE OR REPLACE FUNCTION create_user_and_submit_application(
  p_email text,
  p_password text,
  p_data jsonb,
  p_linked_name text DEFAULT NULL,
  p_linked_email text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_user_id uuid;
  v_application applications;
BEGIN
  -- Check if email exists
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Email already exists';
  END IF;

  -- Create user
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('approved', false),
    now(),
    now()
  )
  RETURNING id INTO v_user_id;

  -- Create application
  INSERT INTO applications (
    user_id,
    data,
    status
  ) VALUES (
    v_user_id,
    p_data,
    'pending'
  )
  RETURNING * INTO v_application;

  -- Handle linked application if provided
  IF p_linked_name IS NOT NULL AND p_linked_email IS NOT NULL THEN
    INSERT INTO linked_applications (
      primary_application_id,
      linked_name,
      linked_email
    ) VALUES (
      v_application.id,
      p_linked_name,
      p_linked_email
    );
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'application_id', v_application.id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to approve applications
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Get user_id from application
  SELECT user_id INTO v_user_id
  FROM applications
  WHERE id = p_application_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Application not found';
  END IF;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Update user metadata to mark as approved
  UPDATE auth.users
  SET 
    raw_user_meta_data = jsonb_build_object('approved', true),
    email_confirmed_at = now(),
    updated_at = now()
  WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if user can sign in
CREATE OR REPLACE FUNCTION auth.check_user_approved()
RETURNS trigger AS $$
BEGIN
  IF NOT (NEW.raw_user_meta_data->>'approved')::boolean THEN
    RAISE EXCEPTION 'User not approved';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to check approval before sign in
DROP TRIGGER IF EXISTS ensure_user_approved ON auth.users;
CREATE TRIGGER ensure_user_approved
  BEFORE UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION auth.check_user_approved();

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (public.is_admin());

CREATE POLICY "Admin full access to linked_applications"
  ON linked_applications FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON applications TO authenticated;
GRANT ALL ON linked_applications TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO anon;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;
GRANT EXECUTE ON FUNCTION approve_application TO authenticated;