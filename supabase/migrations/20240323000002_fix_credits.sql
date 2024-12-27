-- Add credits column to profiles if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'credits'
  ) THEN
    ALTER TABLE profiles
    ADD COLUMN credits INTEGER NOT NULL DEFAULT 1000;
  END IF;
END $$;

-- Drop and recreate credits table to ensure correct schema
DROP TABLE IF EXISTS credits CASCADE;

CREATE TABLE credits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  amount integer NOT NULL,
  description text NOT NULL,
  booking_id uuid REFERENCES bookings ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE credits ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own credits" ON credits;
DROP POLICY IF EXISTS "Admin full access to credits" ON credits;

-- Create policies
CREATE POLICY "Users can view their own credits"
  ON credits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to credits"
  ON credits FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON credits TO authenticated;

-- Update existing users to have 1000 credits if they don't already have credits set
UPDATE profiles 
SET credits = 1000 
WHERE credits IS NULL OR credits = 0;