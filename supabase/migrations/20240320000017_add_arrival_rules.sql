-- Create arrival_rules table
CREATE TABLE arrival_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  arrival_day text NOT NULL DEFAULT 'wednesday',
  departure_day text NOT NULL DEFAULT 'tuesday',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
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

-- Grant permissions
GRANT SELECT ON arrival_rules TO authenticated;
GRANT ALL ON arrival_rules TO authenticated;