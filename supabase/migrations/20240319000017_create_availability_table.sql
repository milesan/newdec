-- Drop existing table if it exists
DROP TABLE IF EXISTS availability;

-- Create availability table
CREATE TABLE availability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  accommodation_id uuid REFERENCES accommodations(id) ON DELETE CASCADE,
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone NOT NULL,
  status text NOT NULL CHECK (status IN ('AVAILABLE', 'HOLD', 'BOOKED')),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT no_overlap EXCLUDE USING gist (
    accommodation_id WITH =,
    tstzrange(start_date, end_date) WITH &&
  )
);

-- Create index for faster queries
CREATE INDEX idx_availability_dates ON availability (accommodation_id, start_date, end_date);

-- Enable RLS
ALTER TABLE availability ENABLE ROW LEVEL SECURITY;

-- Create policy for admin access
CREATE POLICY "Admin full access"
  ON availability
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = id
      AND email = 'andre@thegarden.pt'
    )
  );

-- Grant permissions
GRANT ALL ON availability TO authenticated;