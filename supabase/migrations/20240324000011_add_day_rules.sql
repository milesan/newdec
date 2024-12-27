-- Create a table for individual day rules
CREATE TABLE day_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  date date NOT NULL,
  is_arrival boolean DEFAULT false,
  is_departure boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT valid_rule CHECK (NOT (is_arrival AND is_departure)), -- Can't be both arrival and departure
  UNIQUE(date)
);

-- Enable RLS
ALTER TABLE day_rules ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to day_rules"
  ON day_rules FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to day_rules"
  ON day_rules FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON day_rules TO authenticated;