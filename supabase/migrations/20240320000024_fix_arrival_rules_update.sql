-- Drop existing table and recreate with proper constraints
DROP TABLE IF EXISTS arrival_rules CASCADE;

CREATE TABLE arrival_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  arrival_day text NOT NULL,
  departure_day text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT valid_arrival_day CHECK (arrival_day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
  CONSTRAINT valid_departure_day CHECK (departure_day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
  CONSTRAINT different_days CHECK (arrival_day != departure_day)
);

-- Enable RLS
ALTER TABLE arrival_rules ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to arrival_rules"
  ON arrival_rules FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to arrival_rules"
  ON arrival_rules FOR ALL
  USING (public.is_admin());

-- Insert default rules
INSERT INTO arrival_rules (arrival_day, departure_day)
VALUES ('wednesday', 'tuesday');

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION update_arrival_rules_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for timestamp update
CREATE TRIGGER update_arrival_rules_timestamp
  BEFORE UPDATE ON arrival_rules
  FOR EACH ROW
  EXECUTE FUNCTION update_arrival_rules_timestamp();

-- Grant necessary permissions
GRANT SELECT ON arrival_rules TO authenticated;
GRANT ALL ON arrival_rules TO authenticated;