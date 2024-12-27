import { supabase } from '../lib/supabase';

export async function cleanAvailabilityData() {
  try {
    const { error } = await supabase
      .from('availability')
      .delete()
      .in('status', ['BOOKED', 'HOLD']);

    if (error) throw error;
  } catch (err) {
    console.error('Error cleaning availability data:', err);
  }
}