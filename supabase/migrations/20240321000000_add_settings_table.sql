-- Create settings table for global configuration
CREATE TABLE settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to settings"
  ON settings FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to settings"
  ON settings FOR ALL
  USING (public.is_admin());

-- Insert default settings
INSERT INTO settings (key, value)
VALUES ('stripe_test_mode', 'true'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Grant permissions
GRANT SELECT ON settings TO authenticated;
GRANT ALL ON settings TO authenticated;