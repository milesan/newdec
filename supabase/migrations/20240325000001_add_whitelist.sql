-- Create whitelist table
CREATE TABLE whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  last_login timestamp with time zone,
  has_seen_welcome boolean DEFAULT false
);

-- Enable RLS
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create function to check if email is whitelisted
CREATE OR REPLACE FUNCTION is_whitelisted(p_email text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM whitelist WHERE email = p_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle whitelist login
CREATE OR REPLACE FUNCTION handle_whitelist_login()
RETURNS trigger AS $$
BEGIN
  -- Update last login time for whitelisted users
  UPDATE whitelist 
  SET last_login = now()
  WHERE email = NEW.email;
  
  -- Set user metadata if whitelisted
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for login handling
CREATE TRIGGER on_auth_sign_in
  BEFORE INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_whitelist_login();

-- Grant permissions
GRANT ALL ON whitelist TO authenticated;