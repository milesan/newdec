import { supabase } from '../lib/supabase';
import type { Database } from '../types/database';

type Accommodation = Database['public']['Tables']['accommodations']['Row'];

export async function createBooking(
  accommodationId: string,
  checkIn: Date,
  checkOut: Date,
  totalPrice: number,
  doBooking?: boolean
) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('User not authenticated');

  try {
    // Get accommodation details
    const { data: accommodation, error: accError } = await supabase
      .from('accommodations')
      .select(`
        *,
        parent:parent_accommodation_id (
          id,
          title,
          inventory_count,
          is_fungible,
          is_unlimited
        )
      `)
      .eq('id', accommodationId)
      .single();

    if (accError) throw accError;
    if (!accommodation) throw new Error('Accommodation not found');

    if(doBooking) {
      // Create booking using RPC function
      const { data: booking, error: createError } = await supabase
        .rpc('create_manual_booking', {
          p_accommodation_id: accommodationId,
          p_check_in: checkIn.toISOString(),
          p_check_out: checkOut.toISOString(),
          p_email: user.email,
          p_total_price: totalPrice
        });

      if (createError) throw createError;      
      return booking;
    }
  } catch (error) {
    console.error('Error creating booking:', error);
    throw error;
  }
}

export async function getUserBookings() {
  try {
    // Get current user
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    // Get bookings with accommodation details
    const { data, error } = await supabase
      .from('booking_details')
      .select('*')
      .eq('user_id', user.id)
      .order('check_in', { ascending: false });

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error fetching user bookings:', error);
    throw error;
  }
}