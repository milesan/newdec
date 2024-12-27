-- Create applications table
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  data jsonb NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create application questions table
CREATE TABLE application_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number integer NOT NULL,
  text text NOT NULL,
  type text NOT NULL,
  options jsonb,
  required boolean DEFAULT false,
  section text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_questions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can insert their own applications"
  ON applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own applications"
  ON applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to applications"
  ON applications FOR ALL
  USING (public.is_admin());

CREATE POLICY "Anyone can view questions"
  ON application_questions FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to questions"
  ON application_questions FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT SELECT ON application_questions TO authenticated;
GRANT ALL ON applications TO authenticated;