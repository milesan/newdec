-- First, drop the unique constraint to allow reordering
ALTER TABLE application_questions DROP CONSTRAINT IF EXISTS application_questions_order_number_key;

-- Delete any existing email/password questions
DELETE FROM application_questions 
WHERE text IN ('What is your email address?', 'Choose a password for your account');

-- Create a temporary sequence for reordering
CREATE TEMPORARY SEQUENCE temp_order_seq START WITH 3;

-- Update all existing questions with new order numbers
UPDATE application_questions 
SET order_number = nextval('temp_order_seq');

-- Drop temporary sequence
DROP SEQUENCE temp_order_seq;

-- Insert email and password questions at the beginning
INSERT INTO application_questions (order_number, text, type, required, section)
VALUES 
  (1, 'What is your email address?', 'email', true, 'intro'),
  (2, 'Choose a password for your account', 'password', true, 'intro');

-- Add back the unique constraint
ALTER TABLE application_questions 
ADD CONSTRAINT application_questions_order_number_key UNIQUE (order_number);