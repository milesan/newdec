-- Create a secure way to check admin status
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND email = 'andre@thegarden.pt'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update availability table policies
DROP POLICY IF EXISTS "Admin full access" ON availability;

CREATE POLICY "Admin full access"
ON availability
FOR ALL
USING (public.is_admin());

-- Update accommodations table policies
DROP POLICY IF EXISTS "Anyone can view accommodations" ON accommodations;
DROP POLICY IF EXISTS "Admins can manage accommodations" ON accommodations;

CREATE POLICY "Anyone can view accommodations"
ON accommodations
FOR SELECT
USING (true);

CREATE POLICY "Admins can manage accommodations"
ON accommodations
FOR ALL
USING (public.is_admin());

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON availability TO authenticated;
GRANT ALL ON accommodations TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;