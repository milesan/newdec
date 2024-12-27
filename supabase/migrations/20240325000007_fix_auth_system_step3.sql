-- Create function to handle whitelist status
CREATE OR REPLACE FUNCTION check_whitelist_status()
RETURNS trigger AS $$
BEGIN
  -- Check if user is whitelisted
  IF EXISTS (SELECT 1 FROM whitelist WHERE email = NEW.email) THEN
    -- Update whitelist record
    UPDATE whitelist 
    SET last_login = now()
    WHERE email = NEW.email;
    
    -- Set user metadata
    NEW.raw_user_meta_data = jsonb_build_object(
      'is_whitelisted', true,
      'has_seen_welcome', false,
      'application_status', 'approved'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for whitelist check
CREATE TRIGGER check_whitelist_status
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION check_whitelist_status();

-- Grant permissions
GRANT EXECUTE ON FUNCTION check_whitelist_status TO authenticated;