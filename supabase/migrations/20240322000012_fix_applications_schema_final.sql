-- Drop existing tables if they exist (in correct order)
DROP TABLE IF EXISTS linked_applications CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS application_questions CASCADE;

-- Create applications table with proper foreign key to auth.users
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  data jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
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

-- Create application_questions table
CREATE TABLE application_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number integer NOT NULL,
  text text NOT NULL,
  type text NOT NULL,
  options jsonb,
  required boolean DEFAULT false,
  section text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(order_number)
);

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_questions ENABLE ROW LEVEL SECURITY;

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

-- Create policies for application_questions
CREATE POLICY "Public read access to questions"
  ON application_questions FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to questions"
  ON application_questions FOR ALL
  USING (public.is_admin());

-- Create function to handle user creation and application submission
CREATE OR REPLACE FUNCTION create_user_and_submit_application(
  p_email text,
  p_password text,
  p_data jsonb,
  p_linked_name text DEFAULT NULL,
  p_linked_email text DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
  v_user_id uuid;
  v_application applications;
BEGIN
  -- Create the user
  INSERT INTO auth.users (
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    p_email,
    crypt(p_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now()
  )
  RETURNING id INTO v_user_id;

  -- Create profile
  INSERT INTO profiles (id, email)
  VALUES (v_user_id, p_email);

  -- Submit application
  INSERT INTO applications (user_id, data, status)
  VALUES (v_user_id, p_data, 'pending')
  RETURNING * INTO v_application;

  -- Handle linked application if provided
  IF p_linked_name IS NOT NULL AND p_linked_email IS NOT NULL THEN
    INSERT INTO linked_applications (
      primary_application_id,
      linked_name,
      linked_email
    ) VALUES (
      v_application.id,
      p_linked_name,
      p_linked_email
    );
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_user_id,
    'application_id', v_application.id
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Email already exists';
  WHEN others THEN
    RAISE EXCEPTION 'Failed to create user: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert initial questions
INSERT INTO application_questions (order_number, text, type, required, section)
VALUES 
  (1, 'What is your email address?', 'email', true, 'intro'),
  (2, 'Choose a password for your account', 'password', true, 'intro'),
  (3, 'I consent to my data being stored and reviewed for the process of this residency.', 'radio', true, 'intro'),
  (4, 'First Name', 'text', true, 'personal'),
  (5, 'Last Name', 'text', true, 'personal'),
  (6, 'So, where aren''t you from?', 'text', false, 'personal'),
  (7, 'Who, if anyone, referred you?', 'text', false, 'personal'),
  (8, 'Applying as a muse or artisan? Muses receive a 50% discount on their stay (not including accom), and are asked to provide their skills 7h/week.', 'radio', false, 'stay'),
  (9, 'Are you applying with someone else? [like a partner, friend, or family?]', 'radio', false, 'stay'),
  (10, 'What is your # [Whatsapp preferred]', 'tel', false, 'personal'),
  (11, 'Is there any web or social media presence you''d like to share?', 'text', false, 'personal'),
  (12, 'Where are you at in your life right now? Max 80 words, please.', 'textarea', false, 'personal'),
  (13, 'Why do you want to spend time at the Garden? What''s your intention? What do you seek?', 'textarea', false, 'personal'),
  (14, 'What photo(s) of you best captures your essence? No more than 3, please.', 'file', false, 'personal'),
  (15, 'What''s something you''ve created / built that you''re proud of?', 'textarea', false, 'personal'),
  (16, 'If someone hurt your feelings, did they do something wrong?', 'textarea', true, 'philosophy'),
  (17, 'What a recent belief you changed?', 'textarea', false, 'philosophy'),
  (18, 'If we really knew you, what would we know?', 'textarea', false, 'philosophy'),
  (19, 'What is something about yourself that you''re working on?', 'textarea', false, 'philosophy'),
  (20, 'What''s your ideal way of getting to know a new person?', 'textarea', false, 'philosophy'),
  (21, 'What questions, if any, do you like to ask strangers?', 'textarea', true, 'philosophy'),
  (22, 'How do you identify yourself?', 'textarea', false, 'philosophy'),
  (23, 'Are there any topics which are not OK to discuss?', 'textarea', false, 'philosophy'),
  (24, 'What''s your favorite conspiracy theory?', 'textarea', false, 'philosophy'),
  (25, 'What do you believe is true that most other people believe is false?', 'textarea', false, 'philosophy'),
  (26, 'What, if anything, does astrology mean to you?', 'textarea', false, 'philosophy'),
  (27, 'If some robots are mechanics and some mechanics are purple, does it logically follow that some robots must be purple?', 'textarea', false, 'philosophy'),
  (28, 'Do you believe an old book gives you claim to a piece of land?', 'textarea', true, 'philosophy'),
  (29, 'How many times have you been vaccinated for COVID & how do you feel about that?', 'textarea', true, 'health'),
  (30, 'If you know it, what is your MBTI type?', 'text', false, 'personal');

-- Create indexes for better performance
CREATE INDEX idx_applications_user_id ON applications(user_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_linked_applications_email ON linked_applications(linked_email);

-- Grant necessary permissions
GRANT ALL ON applications TO authenticated;
GRANT ALL ON linked_applications TO authenticated;
GRANT SELECT ON application_questions TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_and_submit_application TO authenticated;