-- Create approved_users table
CREATE TABLE approved_users (
  email text PRIMARY KEY,
  approved_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE approved_users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admin full access to approved_users"
  ON approved_users FOR ALL
  USING (public.is_admin());

CREATE POLICY "Anyone can check if they're approved"
  ON approved_users FOR SELECT
  USING (true);

-- Create function to approve user
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_email text;
BEGIN
  -- Get the email from the application
  SELECT u.email INTO v_email
  FROM applications a
  JOIN auth.users u ON a.user_id = u.id
  WHERE a.id = p_application_id;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Add to approved users
  INSERT INTO approved_users (email)
  VALUES (v_email)
  ON CONFLICT (email) DO NOTHING;

  -- Remove from whitelist
  DELETE FROM whitelist WHERE email = v_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create hook to check if user is approved before sign in
CREATE OR REPLACE FUNCTION public.check_user_approved()
RETURNS trigger AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM approved_users 
    WHERE email = NEW.email
  ) THEN
    RAISE EXCEPTION 'User not approved';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to check approval on sign in
DROP TRIGGER IF EXISTS ensure_user_approved ON auth.users;
CREATE TRIGGER ensure_user_approved
  BEFORE UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION check_user_approved();

-- Populate approved_users from existing approved applications
INSERT INTO approved_users (email)
SELECT DISTINCT u.email
FROM applications a
JOIN auth.users u ON a.user_id = u.id
WHERE a.status = 'approved'
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT SELECT ON approved_users TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_user_approved TO authenticated, anon;