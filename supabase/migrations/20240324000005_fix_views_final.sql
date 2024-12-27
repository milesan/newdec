-- Drop existing views
DROP VIEW IF EXISTS application_details CASCADE;
DROP VIEW IF EXISTS booking_details CASCADE;

-- Create a proper view for applications with user data
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

-- Create a view for bookings with related data
CREATE VIEW booking_details AS
SELECT 
  b.*,
  a.title as accommodation_title,
  a.location as accommodation_location,
  a.type as accommodation_type,
  p.email as user_email
FROM bookings b
JOIN accommodations a ON b.accommodation_id = a.id
JOIN profiles p ON b.user_id = p.id;

-- Enable RLS on base tables
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;

-- Create policies for applications
CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can manage applications"
  ON applications FOR ALL
  USING (public.is_admin());

-- Create policies for bookings
CREATE POLICY "Users can view their own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can manage bookings"
  ON bookings FOR ALL
  USING (public.is_admin());

-- Create policies for linked applications
CREATE POLICY "Admin can manage linked applications"
  ON linked_applications FOR ALL
  USING (public.is_admin());

-- Grant permissions for views
GRANT SELECT ON application_details TO authenticated;
GRANT SELECT ON booking_details TO authenticated;

-- Create security definer functions for views
CREATE OR REPLACE FUNCTION get_application_details()
RETURNS SETOF application_details
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM application_details
  WHERE public.is_admin() OR user_id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION get_booking_details()
RETURNS SETOF booking_details
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM booking_details
  WHERE public.is_admin() OR user_id = auth.uid()
$$;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_application_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_booking_details TO authenticated;