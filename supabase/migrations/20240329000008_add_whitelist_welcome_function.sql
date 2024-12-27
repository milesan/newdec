-- Create function to mark whitelist welcome as seen
CREATE OR REPLACE FUNCTION mark_whitelist_welcome_seen(p_email text)
RETURNS void AS $$
BEGIN
  UPDATE whitelist
  SET 
    has_seen_welcome = true,
    updated_at = now()
  WHERE email = p_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION mark_whitelist_welcome_seen TO authenticated;