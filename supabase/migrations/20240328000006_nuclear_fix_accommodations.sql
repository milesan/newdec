-- NUCLEAR RESET: Drop and recreate accommodations table
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS availability CASCADE;
DROP TABLE IF EXISTS accommodations CASCADE;

-- Recreate accommodations table
CREATE TABLE accommodations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  location text NOT NULL,
  price integer NOT NULL,
  rating numeric,
  reviews integer DEFAULT 0,
  image_url text NOT NULL,
  type text NOT NULL,
  beds integer NOT NULL,
  bathrooms numeric NOT NULL,
  superhost boolean DEFAULT false,
  inventory_count integer NOT NULL DEFAULT 1,
  parent_accommodation_id uuid REFERENCES accommodations(id) ON DELETE CASCADE,
  is_fungible boolean DEFAULT false,
  is_unlimited boolean DEFAULT false
);

-- Create indexes
CREATE INDEX idx_accommodations_parent_id ON accommodations(parent_accommodation_id);

-- Insert all base accommodations
INSERT INTO accommodations (
  title,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  beds,
  bathrooms,
  superhost,
  inventory_count,
  is_fungible,
  is_unlimited
) VALUES 
-- Regular accommodations
('A-Frame Pod', 'The Garden', 325, 4.9, 18, 'https://storage.tally.so/8ad5a3bd-26cb-4210-b33e-16a4e015d5f7/a-framephoto_2024-02-29_14-57-04.jpg', 'Pod', 2, 0, true, 1, false, false),
('Writer''s Room', 'The Garden', 465, 4.97, 38, 'https://storage.tally.so/78ab26bd-f87a-4d2e-9d58-9257e275e17c/20221227_124015-1-.jpg', 'Room', 2, 1, true, 1, false, false),
('Valleyview Room', 'The Garden', 515, 4.98, 64, 'https://storage.tally.so/065194a8-e63d-4328-aa76-0ebbc6cc59fe/20221227_123043-1-.jpg', 'Room', 2, 1, true, 1, false, false),
('The Hearth', 'The Garden', 630, 5.0, 29, 'https://storage.tally.so/43e64ccc-a48c-44c4-890b-635d3b5d8e21/image-4-1-.jpg', 'Suite', 2, 1, true, 1, false, false),
('4 Meter Bell Tent', 'The Garden', 330, 4.9, 56, 'https://storage.tally.so/f385d036-6b48-4a0b-b119-2e334c0bc1f0/photo_2023-09-07_18-55-18.jpg', 'Bell Tent', 2, 0, true, 25, false, false),
('5m Bell Tent', 'The Garden', 385, 4.95, 42, 'https://storage.tally.so/eb9c15bb-7cb3-4b61-a84e-1c131c23ab38/2023-08-17_Synesthesia-Portugal-by-Alexa-Ashley-0011.jpg', 'Bell Tent', 2, 0, true, 6, false, false),
('Microcabin Left', 'The Garden', 385, 4.92, 73, 'https://storage.tally.so/93a554e1-8d1b-4606-947a-33059b65d5b9/IMG-20230516-WA0004.jpg', 'Cabin', 2, 0, true, 1, false, false),
('Microcabin Middle', 'The Garden', 350, 4.92, 73, 'https://storage.tally.so/93a554e1-8d1b-4606-947a-33059b65d5b9/IMG-20230516-WA0004.jpg', 'Cabin', 2, 0, true, 1, false, false),
('Microcabin Right', 'The Garden', 385, 4.92, 73, 'https://storage.tally.so/93a554e1-8d1b-4606-947a-33059b65d5b9/IMG-20230516-WA0004.jpg', 'Cabin', 2, 0, true, 1, false, false),

-- Fungible accommodations
('4-Bed Dorm', 'The Garden', 167, 4.7, 45, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (No Bunks)', 4, 1, false, 4, true, false),
('6-Bed Dorm', 'The Garden', 145, 4.7, 89, 'https://storage.tally.so/0c9a2451-3cac-4253-be21-b76c3287598b/photo_2024-03-06_19-48-31.jpg', 'Dorm (3 Double Bunks)', 6, 1, false, 6, true, false),
('Van Parking', 'The Garden', 0, 4.85, 27, 'https://storage.tally.so/530c1104-341b-42ec-8c10-8aaa5ad56b87/DOG_9426.jpg', 'Parking', 0, 0, false, 5000, true, false),
('Your Own Tent', 'The Garden', 0, 4.9, 45, 'https://storage.tally.so/46092536-82aa-4efc-a845-d84097c62a4b/photo_2023-09-07_18-55-35.jpg', 'Camping', 1, 0, false, 5000, true, false),
('I''m staying with someone else / +1', 'The Garden', 0, 5.0, 12, 'https://storage.tally.so/b6723884-5ada-4a14-bd07-6dab8c9b6689/1Untitled-5.jpg', 'Add-on', 0, 0, false, 5000, true, false);

-- Create individual bed entries for dorms
WITH dorm_parents AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE title IN ('4-Bed Dorm', '6-Bed Dorm')
)
INSERT INTO accommodations (
  title,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  beds,
  bathrooms,
  superhost,
  inventory_count,
  parent_accommodation_id,
  is_fungible,
  is_unlimited
)
SELECT 
  dp.title || ' Bed ' || bed_number,
  dp.location,
  dp.price,
  dp.rating,
  dp.reviews,
  dp.image_url,
  dp.type,
  1,
  dp.bathrooms,
  dp.superhost,
  1,
  dp.id,
  false,
  false
FROM dorm_parents dp
CROSS JOIN generate_series(1, 
  CASE 
    WHEN dp.title = '4-Bed Dorm' THEN 4
    WHEN dp.title = '6-Bed Dorm' THEN 6
  END
) as bed_number;

-- Create individual units for fungible accommodations
WITH fungible_parents AS (
  SELECT id, title, location, price, rating, reviews, image_url, type, bathrooms, superhost
  FROM accommodations
  WHERE title IN ('Van Parking', 'Your Own Tent', 'I''m staying with someone else / +1')
)
INSERT INTO accommodations (
  title,
  location,
  price,
  rating,
  reviews,
  image_url,
  type,
  beds,
  bathrooms,
  superhost,
  inventory_count,
  parent_accommodation_id,
  is_fungible,
  is_unlimited
)
SELECT 
  fp.title || ' Unit ' || unit_number,
  fp.location,
  fp.price,
  fp.rating,
  fp.reviews,
  fp.image_url,
  fp.type,
  CASE WHEN fp.title = 'Your Own Tent' THEN 1 ELSE 0 END,
  fp.bathrooms,
  fp.superhost,
  1,
  fp.id,
  false,
  false
FROM fungible_parents fp
CROSS JOIN generate_series(1, 100) as unit_number;

-- Recreate bookings table
CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  accommodation_id uuid REFERENCES accommodations(id) ON DELETE CASCADE NOT NULL,
  check_in timestamp with time zone NOT NULL,
  check_out timestamp with time zone NOT NULL,
  total_price integer NOT NULL,
  status text NOT NULL DEFAULT 'confirmed',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Recreate availability table
CREATE TABLE availability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  accommodation_id uuid REFERENCES accommodations(id) ON DELETE CASCADE,
  date date NOT NULL,
  status text NOT NULL CHECK (status IN ('AVAILABLE', 'HOLD', 'BOOKED')),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(accommodation_id, date)
);

-- Create indexes
CREATE INDEX idx_bookings_dates ON bookings(check_in, check_out);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_availability_lookup ON availability(accommodation_id, date);

-- Enable RLS
ALTER TABLE accommodations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to accommodations"
  ON accommodations FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to accommodations"
  ON accommodations FOR ALL
  USING (public.is_admin());

CREATE POLICY "Users can view their own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin full access to bookings"
  ON bookings FOR ALL
  USING (public.is_admin());

CREATE POLICY "Public read access to availability"
  ON availability FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to availability"
  ON availability FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON accommodations TO authenticated;
GRANT ALL ON bookings TO authenticated;
GRANT ALL ON availability TO authenticated;