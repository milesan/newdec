-- Add credits column to profiles if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS credits INTEGER NOT NULL DEFAULT 1000;

-- Create credits table to track transactions
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

-- Create policies
CREATE POLICY "Users can view their own credits"
  ON credits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to credits"
  ON credits FOR ALL
  USING (public.is_admin());

-- Grant permissions
GRANT ALL ON credits TO authenticated;