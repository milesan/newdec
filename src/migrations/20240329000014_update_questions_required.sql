-- Update all questions to be required
UPDATE application_questions
SET required = true
WHERE required = false;

-- Ensure all new questions are required by default
ALTER TABLE application_questions 
ALTER COLUMN required SET DEFAULT true;