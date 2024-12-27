-- First, clean up by dropping everything related to applications view
DROP VIEW IF EXISTS application_details CASCADE;
DROP POLICY IF EXISTS "Users can view their own applications" ON applications;
DROP POLICY IF EXISTS "Admin can manage applications" ON applications;
DROP POLICY IF EXISTS "Admin full access to applications" ON applications;

-- Create the applications view
CREATE VIEW application_details AS
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

-- Create single policy for admin access to applications
CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT SELECT ON application_details TO authenticated;
GRANT ALL ON applications TO authenticated;