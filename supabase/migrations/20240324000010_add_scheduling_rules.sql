-- Create scheduling_rules table
CREATE TABLE scheduling_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  start_date date NOT NULL,
  end_date date NOT NULL,
  arrival_day text,
  departure_day text,
  is_blocked boolean DEFAULT false,
  blocked_dates jsonb DEFAULT '[]',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT valid_arrival_day CHECK (
    arrival_day IS NULL OR 
    arrival_day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')
  ),
  CONSTRAINT valid_departure_day CHECK (
    departure_day IS NULL OR 
    departure_day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')
  ),
  CONSTRAINT valid_dates CHECK (start_date <= end_date)
);

-- Enable RLS
ALTER TABLE scheduling_rules ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to scheduling_rules"
  ON scheduling_rules FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to scheduling_rules"
  ON scheduling_rules FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON scheduling_rules TO authenticated;