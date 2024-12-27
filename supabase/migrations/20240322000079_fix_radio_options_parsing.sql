-- First, ensure we have a clean slate for these questions
DELETE FROM application_questions 
WHERE text LIKE '%muse or artisan%' OR text LIKE '%applying with someone else%';

-- Insert the questions with properly formatted JSON array options
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
 '["Yes, I want to be a muse", "No, I prefer to be a regular guest"]'::jsonb,
 true, 
 'stay'),
(8, 'Are you applying with someone else? [like a partner, friend, or family?]',
 'radio',
 '["Yes!", "No, applying solo"]'::jsonb,
 true,
 'stay');