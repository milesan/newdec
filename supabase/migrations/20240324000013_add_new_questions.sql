-- Add new questions
INSERT INTO application_questions (
  order_number,
  text,
  type,
  options,
  required,
  section
) VALUES 
(31, 'Roughly how many hours per week will you be working online?', 
 'text',
 NULL,
 true, 
 'stay'),

(32, 'The Garden has two resident cats & seasonal dog. We aren''t able to accommodate other animals. Do you understand?', 
 'radio', 
 '["Yes, I definitely won''t bring an animal with me even though it is super cute.", "No, I do not actually want to come and I am filling out this application just for fun."]'::jsonb,
 true, 
 'stay'),

(33, 'The Garden is strictly an alcohol & smoke free experiment. Do you understand and agree to honor this?', 
 'radio', 
 '["Yes, I understand and agree to honor this completely", "No, this isn''t the right place for me"]'::jsonb,
 true, 
 'stay');