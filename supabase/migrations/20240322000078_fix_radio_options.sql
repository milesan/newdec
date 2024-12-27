-- First, update the application_questions table to ensure options are properly stored
ALTER TABLE application_questions
ALTER COLUMN options TYPE jsonb USING options::jsonb;

-- Delete existing questions that need to be fixed
DELETE FROM application_questions 
WHERE text IN (
  'Applying as a muse or artisan? Muses receive a 50% discount on their stay (not including accom), and are asked to provide their skills 7h/week.',
  'Are you applying with someone else? [like a partner, friend, or family?]'
);

-- Insert the questions with proper options
INSERT INTO application_questions (
  order_number,
  text,
  type,
  options,
  required,
  section
) VALUES 
(7, 'Applying as a muse or artisan? Muses receive a 50% discount on their stay (not including accom), and are asked to provide their skills 7h/week.', 
 'radio', 
 '["Yes, I want to be a muse", "No, I prefer to be a regular guest"]',
 true, 
 'stay'),
(8, 'Are you applying with someone else? [like a partner, friend, or family?]',
 'radio',
 '["Yes!", "No, applying solo"]',
 true,
 'stay');