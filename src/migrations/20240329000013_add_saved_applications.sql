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

-- Create index for better performance
CREATE INDEX idx_saved_applications_user_id ON saved_applications(user_id);

-- Grant necessary permissions
GRANT ALL ON saved_applications TO authenticated;