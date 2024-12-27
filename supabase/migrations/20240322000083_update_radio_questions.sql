-- First, clean up the questions we're updating
DELETE FROM application_questions 
WHERE order_number IN (3, 8, 9);

-- Insert updated questions with proper options
INSERT INTO application_questions (
  order_number,
  text,
  type,
  options,
  required,
  section
) VALUES 
(3, 'Do you consent to your data being stored and reviewed for this residency?', 
 'radio', 
 '["Yes", "No"]'::jsonb,
 true, 
 'intro'),

(8, 'Would you like to be a muse? (50% discount in exchange for 7h/week of skills)', 
 'radio', 
 '["Yes", "No"]'::jsonb,
 true, 
 'stay'),

(9, 'Are you applying with someone else?',
 'radio',
 '["Yes", "No"]'::jsonb,
 true,
 'stay');