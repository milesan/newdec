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