-- Drop existing function and policies
DROP FUNCTION IF EXISTS public.is_admin();
DROP POLICY IF EXISTS "Admin full access" ON availability;
DROP POLICY IF EXISTS "Admins can manage accommodations" ON accommodations;

-- Create a more secure admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND email = 'andre@thegarden.pt'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Update availability policies
CREATE POLICY "Admin full access"
ON availability
FOR ALL
USING (public.is_admin());

-- Update accommodations policies
CREATE POLICY "Admins can manage accommodations"
ON accommodations
FOR ALL
USING (public.is_admin());

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON availability TO authenticated;
GRANT ALL ON accommodations TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;