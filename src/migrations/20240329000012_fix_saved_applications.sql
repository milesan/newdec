-- Create saved_applications table if it doesn't exist
CREATE TABLE IF NOT EXISTS saved_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE saved_applications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their own saved applications" ON saved_applications;

-- Create policies
CREATE POLICY "Users can manage their own saved applications"
  ON saved_applications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create function to handle saving application data
CREATE OR REPLACE FUNCTION save_application_data(p_data jsonb)
RETURNS void AS $$
BEGIN
  INSERT INTO saved_applications (user_id, data)
  VALUES (auth.uid(), p_data)
  ON CONFLICT (user_id) 
  DO UPDATE SET 
    data = EXCLUDED.data,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON saved_applications TO authenticated;
GRANT EXECUTE ON FUNCTION save_application_data TO authenticated;