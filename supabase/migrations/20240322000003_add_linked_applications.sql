-- Add a linked_applications table to track application groups
CREATE TABLE linked_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  linked_application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  linked_name text NOT NULL,
  linked_email text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(primary_application_id, linked_email)
);

-- Enable RLS
ALTER TABLE linked_applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admin full access to linked_applications"
  ON linked_applications FOR ALL
  USING (public.is_admin());

-- Create function to handle application submission with linking
CREATE OR REPLACE FUNCTION submit_application(
  p_user_id UUID,
  p_data jsonb,
  p_linked_name text DEFAULT NULL,
  p_linked_email text DEFAULT NULL
) RETURNS applications AS $$
DECLARE
  v_application applications;
BEGIN
  -- Insert the application
  INSERT INTO applications (user_id, data, status)
  VALUES (p_user_id, p_data, 'pending')
  RETURNING * INTO v_application;

  -- If this application is linked to another person
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

  -- Check if this application is linked to by another application
  UPDATE linked_applications
  SET linked_application_id = v_application.id
  WHERE linked_email = (
    SELECT email FROM auth.users WHERE id = p_user_id
  )
  AND linked_application_id IS NULL;

  RETURN v_application;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON linked_applications TO authenticated;
GRANT EXECUTE ON FUNCTION submit_application TO authenticated;