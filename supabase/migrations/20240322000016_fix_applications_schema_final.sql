-- Drop existing tables to ensure clean slate
DROP TABLE IF EXISTS linked_applications CASCADE;
DROP TABLE IF EXISTS applications CASCADE;

-- Create applications table with proper foreign key and RLS
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create linked_applications table
CREATE TABLE linked_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  linked_application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  linked_name text NOT NULL,
  linked_email text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(primary_application_id, linked_email)
);

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;

-- Create policies for applications
CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own applications"
  ON applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (public.is_admin());

-- Create policies for linked_applications
CREATE POLICY "Admin full access to linked_applications"
  ON linked_applications FOR ALL
  USING (public.is_admin());

-- Create indexes for better performance
CREATE INDEX idx_applications_user_id ON applications(user_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_linked_applications_email ON linked_applications(linked_email);

-- Grant necessary permissions
GRANT ALL ON applications TO authenticated;
GRANT ALL ON linked_applications TO authenticated;