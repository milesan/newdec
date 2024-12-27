-- Drop existing view if it exists
DROP VIEW IF EXISTS booking_details CASCADE;

-- Create a proper view for bookings with related data
CREATE OR REPLACE VIEW booking_details AS
SELECT 
  b.*,
  a.title as accommodation_title,
  a.location as accommodation_location,
  a.type as accommodation_type,
  a.image_url as accommodation_image,
  COALESCE(p.title, a.title) as parent_title,
  u.email as user_email
FROM bookings b
JOIN accommodations a ON b.accommodation_id = a.id
LEFT JOIN accommodations p ON a.parent_accommodation_id = p.id
JOIN auth.users u ON b.user_id = u.id;

-- Create policies for the view
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Admin full access to bookings" ON bookings;

CREATE POLICY "Users can view their own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to bookings"
  ON bookings FOR ALL
  USING (public.is_admin());

-- Create a function to get user's bookings
CREATE OR REPLACE FUNCTION get_user_bookings()
RETURNS SETOF booking_details AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM booking_details
  WHERE user_id = auth.uid()
  ORDER BY check_in DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT SELECT ON booking_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_bookings TO authenticated;