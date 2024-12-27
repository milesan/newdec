-- Create a view for bookings with related data
CREATE OR REPLACE VIEW booking_details AS
SELECT 
  b.*,
  a.title as accommodation_title,
  a.location as accommodation_location,
  a.type as accommodation_type,
  p.email as user_email
FROM bookings b
JOIN accommodations a ON b.accommodation_id = a.id
JOIN profiles p ON b.user_id = p.id;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
DROP POLICY IF EXISTS "Admin full access to bookings" ON bookings;

-- Create updated policies
CREATE POLICY "Users can view their own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to bookings"
  ON bookings FOR ALL
  USING (public.is_admin());

-- Create policy for the view
CREATE POLICY "Users can view their own booking details"
  ON booking_details FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

-- Grant necessary permissions
GRANT SELECT ON booking_details TO authenticated;