-- Create saved_applications table
CREATE TABLE saved_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  data jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE saved_applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can manage their own saved applications"
  ON saved_applications FOR ALL
  USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON saved_applications TO authenticated;