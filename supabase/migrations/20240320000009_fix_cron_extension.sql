-- First ensure we have the required extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create the function to expire holds
CREATE OR REPLACE FUNCTION expire_holds() RETURNS void AS $$
BEGIN
  UPDATE availability
  SET status = 'AVAILABLE'
  WHERE status = 'HOLD'
  AND created_at < NOW() - INTERVAL '72 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schedule the job using cron directly
SELECT cron.schedule(
  'expire-holds',           -- name of the cron job
  '0 * * * *',             -- run every hour
  'SELECT expire_holds()'   -- SQL to execute
);