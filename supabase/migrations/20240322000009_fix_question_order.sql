-- First, delete any existing email/password questions
DELETE FROM application_questions 
WHERE text IN ('What is your email address?', 'Choose a password for your account');

-- Update order numbers to make space for email and password at the start
UPDATE application_questions 
SET order_number = order_number + 2;

-- Insert email and password questions at the beginning
INSERT INTO application_questions (order_number, text, type, required, section)
VALUES 
  (1, 'What is your email address?', 'email', true, 'intro'),
  (2, 'Choose a password for your account', 'password', true, 'intro');