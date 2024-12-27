-- Drop existing table if it exists
DROP TABLE IF EXISTS application_questions CASCADE;

-- Create application questions table with proper schema
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
ALTER TABLE application_questions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public read access to questions"
  ON application_questions FOR SELECT
  USING (true);

CREATE POLICY "Admin full access to questions"
  ON application_questions FOR ALL
  USING (public.is_admin());

-- Insert initial questions
INSERT INTO application_questions (order_number, text, type, options, required, section)
VALUES
  (1, 'I consent to my data being stored and reviewed for the process of this residency.', 'radio', '["Yes", "No [if you click this, we can''t review your application]"]', true, 'intro'),
  (2, 'First Name', 'text', null, true, 'personal'),
  (3, 'Last Name', 'text', null, true, 'personal'),
  (4, 'So, where aren''t you from?', 'text', null, false, 'personal'),
  (5, 'What is your email address?', 'email', null, true, 'personal'),
  (6, 'Who, if anyone, referred you?', 'text', null, false, 'personal'),
  (7, 'Applying as a muse or artisan? Muses receive a 50% discount on their stay (not including accom), and are asked to provide their skills 7h/week.', 'radio', '["Yes", "No"]', false, 'stay'),
  (8, 'Are you applying with someone else? [like a partner, friend, or family?]', 'radio', '["Yes!", "Nope, it''s just me :)"]', false, 'stay'),
  (9, 'What is your # [Whatsapp preferred]', 'tel', null, false, 'personal'),
  (10, 'Is there any web or social media presence you''d like to share?', 'text', null, false, 'personal'),
  (11, 'Where are you at in your life right now? Max 80 words, please.', 'textarea', null, false, 'personal'),
  (12, 'Why do you want to spend time at the Garden? What''s your intention? What do you seek?', 'textarea', null, false, 'personal'),
  (13, 'What photo(s) of you best captures your essence? No more than 3, please.', 'file', null, false, 'personal'),
  (14, 'What''s something you''ve created / built that you''re proud of?', 'textarea', null, false, 'personal'),
  (15, 'If someone hurt your feelings, did they do something wrong?', 'textarea', null, true, 'philosophy'),
  (16, 'What a recent belief you changed?', 'textarea', null, false, 'philosophy'),
  (17, 'If we really knew you, what would we know?', 'textarea', null, false, 'philosophy'),
  (18, 'What is something about yourself that you''re working on?', 'textarea', null, false, 'philosophy'),
  (19, 'What''s your ideal way of getting to know a new person?', 'textarea', null, false, 'philosophy'),
  (20, 'What questions, if any, do you like to ask strangers?', 'textarea', null, true, 'philosophy'),
  (21, 'How do you identify yourself?', 'textarea', null, false, 'philosophy'),
  (22, 'Are there any topics which are not OK to discuss?', 'textarea', null, false, 'philosophy'),
  (23, 'What''s your favorite conspiracy theory?', 'textarea', null, false, 'philosophy'),
  (24, 'What do you believe is true that most other people believe is false?', 'textarea', null, false, 'philosophy'),
  (25, 'What, if anything, does astrology mean to you?', 'textarea', null, false, 'philosophy'),
  (26, 'If some robots are mechanics and some mechanics are purple, does it logically follow that some robots must be purple?', 'textarea', null, false, 'philosophy'),
  (27, 'Do you believe an old book gives you claim to a piece of land?', 'textarea', null, true, 'philosophy'),
  (28, 'How many times have you been vaccinated for COVID & how do you feel about that?', 'textarea', null, true, 'health'),
  (29, 'If you know it, what is your MBTI type?', 'text', null, false, 'personal');

-- Grant permissions
GRANT SELECT ON application_questions TO authenticated;
GRANT ALL ON application_questions TO authenticated;