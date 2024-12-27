-- Drop existing view if it exists
DROP VIEW IF EXISTS booking_details CASCADE;

-- Create a proper view for bookings with related data
CREATE OR REPLACE VIEW booking_details AS
SELECT 
  b.*,
  a.title as accommodation_title,
  a.location as accommodation_location,
  a.type as accommodation_type,
  u.email as user_email
FROM bookings b
JOIN accommodations a ON b.accommodation_id = a.id
JOIN auth.users u ON b.user_id = u.id;

-- Create a security definer function to access the view
CREATE OR REPLACE FUNCTION get_booking_details()
RETURNS SETOF booking_details
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT *
  FROM booking_details
  WHERE auth.uid() = user_id OR public.is_admin();
$$;

-- Grant necessary permissions
GRANT SELECT ON booking_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_booking_details TO authenticated;