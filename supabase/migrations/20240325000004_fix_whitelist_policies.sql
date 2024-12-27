-- First, drop any existing policies
DROP POLICY IF EXISTS "Admin full access to whitelist" ON whitelist;
DROP POLICY IF EXISTS "Public read access to whitelist" ON whitelist;

-- Recreate the policy
CREATE POLICY "Admin full access to whitelist"
  ON whitelist FOR ALL
  USING (public.is_admin());

-- Ensure RLS is enabled
ALTER TABLE whitelist ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON whitelist TO authenticated;