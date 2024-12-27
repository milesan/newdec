-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own applications" ON applications;
DROP POLICY IF EXISTS "Users can create their own applications" ON applications;
DROP POLICY IF EXISTS "Admin full access to applications" ON applications;

-- Create new policies with proper permissions
CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Anyone can submit applications"
  ON applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND email = 'andre@thegarden.pt'
    )
  );

-- Ensure RLS is enabled
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON applications TO authenticated;

-- Create policies for linked applications
DROP POLICY IF EXISTS "Admin full access to linked_applications" ON linked_applications;
DROP POLICY IF EXISTS "Users can create linked applications" ON linked_applications;

CREATE POLICY "Users can create linked applications"
  ON linked_applications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM applications
      WHERE id = primary_application_id
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Admin full access to linked_applications"
  ON linked_applications FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND email = 'andre@thegarden.pt'
    )
  );

-- Ensure RLS is enabled for linked applications
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON linked_applications TO authenticated;