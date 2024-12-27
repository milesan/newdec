-- Create whitelist table
CREATE TABLE whitelist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  notes text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Create policies for whitelist
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Create view to show all users and their status
CREATE OR REPLACE VIEW user_status AS
SELECT 
  u.id as user_id,
  u.email,
  CASE 
    WHEN a.id IS NOT NULL THEN 'application'
    WHEN w.id IS NOT NULL THEN 'whitelist'
    ELSE 'none'
  END as status,
  a.id as application_id,
  a.status as application_status,
  w.id as whitelist_id,
  w.notes as whitelist_notes
FROM auth.users u
LEFT JOIN applications a ON u.id = a.user_id
LEFT JOIN whitelist w ON u.id = w.user_id;

-- Grant permissions
GRANT ALL ON whitelist TO authenticated;
GRANT SELECT ON user_status TO authenticated;