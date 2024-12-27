-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view accommodations" ON accommodations;
DROP POLICY IF EXISTS "Admins can manage accommodations" ON accommodations;

-- Create new policies with simplified admin check
CREATE POLICY "Anyone can view accommodations"
  ON accommodations FOR SELECT
  USING (true);

CREATE POLICY "Admins can manage accommodations"
  ON accommodations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = id
      AND email = 'andre@thegarden.pt'
    )
  );

-- Ensure RLS is enabled
ALTER TABLE accommodations ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON accommodations TO authenticated;

-- Update availability policies
DROP POLICY IF EXISTS "Admins can manage availability" ON availability;

CREATE POLICY "Admins can manage availability"
  ON availability FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = id
      AND email = 'andre@thegarden.pt'
    )
  );

-- Grant availability permissions
GRANT ALL ON availability TO authenticated;