-- Drop existing function
DROP FUNCTION IF EXISTS approve_application;

-- Create updated function that handles both approval and rejection
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

  -- Update application status
  UPDATE applications
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_application_id;

  -- Only update user auth setup if approved
  IF (SELECT status FROM applications WHERE id = p_application_id) = 'approved' THEN
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
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a new function specifically for rejecting applications
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION approve_application TO authenticated;
GRANT EXECUTE ON FUNCTION reject_application TO authenticated;