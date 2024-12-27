-- Drop existing view if it exists
DROP VIEW IF EXISTS application_details CASCADE;

-- Create a more efficient view for applications with user data
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
LEFT JOIN applications la2 ON la.linked_application_id = la2.id
LEFT JOIN auth.users u2 ON la2.user_id = u2.id;

-- Grant access to the view
GRANT SELECT ON application_details TO authenticated;

-- Create index to improve performance
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_created_at ON applications(created_at DESC);