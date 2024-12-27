-- First, create whitelist table if it doesn't exist
CREATE TABLE IF NOT EXISTS whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create a view for applications with user data
CREATE OR REPLACE VIEW application_details AS
SELECT 
  a.*,
  u.email as user_email,
  la.linked_name,
  la.linked_email,
  la2.id as linked_application_id,
  u2.email as linked_user_email
FROM applications a
JOIN auth.users u ON a.user_id = u.id
LEFT JOIN linked_applications la ON a.id = la.primary_application_id
LEFT JOIN applications la2 ON la.linked_email = (
  SELECT email FROM auth.users WHERE id = la2.user_id
)
LEFT JOIN auth.users u2 ON la2.user_id = u2.id;

-- Create a view for whitelist with user data
CREATE OR REPLACE VIEW whitelist_details AS
SELECT 
  w.*,
  u.email as user_email,
  CASE 
    WHEN a.id IS NOT NULL THEN true 
    ELSE false 
  END as has_application,
  a.status as application_status
FROM whitelist w
LEFT JOIN auth.users u ON w.user_id = u.id
LEFT JOIN applications a ON w.user_id = a.user_id;

-- Grant access to tables and views
GRANT ALL ON whitelist TO authenticated;
GRANT SELECT ON application_details TO authenticated;
GRANT SELECT ON whitelist_details TO authenticated;