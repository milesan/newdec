-- Drop existing views and functions
DROP VIEW IF EXISTS application_details CASCADE;
DROP FUNCTION IF EXISTS approve_application CASCADE;
DROP FUNCTION IF EXISTS reject_application CASCADE;

-- Create a proper view for applications with user data
CREATE OR REPLACE VIEW application_details AS
SELECT 
  a.*,
  u.email as user_email,
  la.linked_name,
  la.linked_email,
  la2.id as linked_application_id,
  u2.email as linked_user_email
FROM applications a
JOIN auth.users u ON a.user_id = u.id
LEFT JOIN linked_applications la ON a.id = la.primary_application_id
LEFT JOIN applications la2 ON la.linked_email = (
  SELECT email FROM auth.users WHERE id = la2.user_id
)
LEFT JOIN auth.users u2 ON la2.user_id = u2.id;

-- Create function to approve applications
CREATE OR REPLACE FUNCTION approve_application(
  p_application_id uuid
) RETURNS void AS $$
DECLARE
  v_user_id uuid;
  v_email text;
BEGIN
  -- Get the user_id and email from the application
  SELECT a.user_id, u.email INTO v_user_id, v_email
  FROM applications a
  JOIN auth.users u ON a.user_id = u.id
  WHERE a.id = p_application_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Application not found';
  END IF;

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Update user metadata and confirm email
  UPDATE auth.users
  SET 
    email_confirmed_at = COALESCE(email_confirmed_at, now()),
    raw_app_meta_data = jsonb_build_object(
      'provider', 'email',
      'providers', ARRAY['email']
    ),
    raw_user_meta_data = jsonb_build_object('approved', true),
    updated_at = now()
  WHERE id = v_user_id;

  -- Ensure proper identity record exists
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    provider,
    identity_data,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    v_user_id,
    v_email,
    'email',
    jsonb_build_object(
      'sub', v_user_id::text,
      'email', v_email,
      'email_verified', true,
      'provider', 'email'
    ),
    now(),
    now(),
    now()
  )
  ON CONFLICT (provider, provider_id) DO UPDATE
  SET 
    identity_data = EXCLUDED.identity_data,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to reject applications
CREATE OR REPLACE FUNCTION reject_application(
  p_application_id uuid
) RETURNS void AS $$
BEGIN
  -- Update application status to rejected
  UPDATE applications
  SET 
    status = 'rejected',
    updated_at = now()
  WHERE id = p_application_id;

  -- Update user metadata
  UPDATE auth.users u
  SET raw_user_meta_data = jsonb_build_object('approved', false)
  FROM applications a
  WHERE a.id = p_application_id
  AND u.id = a.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create policies for the view
DROP POLICY IF EXISTS "Admin can view all applications" ON application_details;
CREATE POLICY "Admin can view all applications"
  ON application_details FOR SELECT
  USING (public.is_admin());

-- Grant necessary permissions
GRANT SELECT ON application_details TO authenticated;
GRANT EXECUTE ON FUNCTION approve_application TO authenticated;
GRANT EXECUTE ON FUNCTION reject_application TO authenticated;