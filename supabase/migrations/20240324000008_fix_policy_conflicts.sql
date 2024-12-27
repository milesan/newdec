-- First, drop all existing policies
DROP POLICY IF EXISTS "Users can view their own applications" ON applications;
DROP POLICY IF EXISTS "Users can create their own applications" ON applications;
DROP POLICY IF EXISTS "Admin full access to applications" ON applications;
DROP POLICY IF EXISTS "Admin can manage applications" ON applications;
DROP POLICY IF EXISTS "Anyone can submit applications" ON applications;

DROP POLICY IF EXISTS "Users can create linked applications" ON linked_applications;
DROP POLICY IF EXISTS "Admin full access to linked_applications" ON linked_applications;
DROP POLICY IF EXISTS "Admin can manage linked_applications" ON linked_applications;

-- Drop existing views
DROP VIEW IF EXISTS application_details CASCADE;

-- Recreate the applications view
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

-- Create clean policies for applications
CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own applications"
  ON applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (public.is_admin());

-- Create clean policies for linked_applications
CREATE POLICY "Users can create linked applications"
  ON linked_applications FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM applications
    WHERE id = primary_application_id
    AND user_id = auth.uid()
  ));

CREATE POLICY "Admin full access to linked_applications"
  ON linked_applications FOR ALL
  USING (public.is_admin());

-- Grant necessary permissions
GRANT ALL ON applications TO authenticated;
GRANT ALL ON linked_applications TO authenticated;
GRANT SELECT ON application_details TO authenticated;