-- Drop existing view if it exists
DROP VIEW IF EXISTS booking_details CASCADE;

-- Create a proper view for bookings with related data
CREATE VIEW booking_details AS
SELECT 
  b.*,
  a.title as accommodation_title,
  a.location as accommodation_location,
  a.type as accommodation_type,
  u.email as user_email
FROM bookings b
JOIN accommodations a ON b.accommodation_id = a.id
JOIN auth.users u ON b.user_id = u.id;

-- Enable RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Create policies for the view
CREATE POLICY "Users can view their own booking details"
  ON booking_details FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin can view all booking details"
  ON booking_details FOR SELECT
  USING (public.is_admin());

-- Grant necessary permissions
GRANT SELECT ON booking_details TO authenticated;