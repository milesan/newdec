-- Create a secure RPC function to handle manual bookings
CREATE OR REPLACE FUNCTION create_manual_booking(
  p_email TEXT,
  p_accommodation_id UUID,
  p_check_in TIMESTAMP WITH TIME ZONE,
  p_check_out TIMESTAMP WITH TIME ZONE,
  p_total_price INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_user_id UUID;
  v_booking bookings;
BEGIN
  -- Check if caller is admin
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Get or create user
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_user_id IS NULL THEN
    -- Insert into auth.users using internal auth function
    v_user_id := auth.uid();
    
    -- Create profile
    INSERT INTO profiles (id, email)
    VALUES (v_user_id, p_email);
  END IF;

  -- Create booking using existing function
  SELECT * INTO v_booking
  FROM create_confirmed_booking(
    p_accommodation_id,
    v_user_id,
    p_check_in,
    p_check_out,
    p_total_price
  );

  RETURN jsonb_build_object(
    'booking', row_to_json(v_booking),
    'user_id', v_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;