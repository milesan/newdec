import { supabase } from '../lib/supabase';
import type { Database } from '../types/database';

type Accommodation = Database['public']['Tables']['accommodations']['Row'];

export async function getAccommodations() {
  const { data, error } = await supabase
    .from('accommodations')
    .select('*')
    .order('title');

  if (error) throw error;
  return data as Accommodation[];
}

export async function updateAccommodation(id: string, updates: Partial<Accommodation>) {
  const { data, error } = await supabase
    .from('accommodations')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) {
    console.error('Error updating accommodation:', error);
    throw error;
  }

  return data;
}

export async function checkAvailability(
  accommodationId: string,
  checkIn: Date,
  checkOut: Date
) {
  const { data, error } = await supabase
    .from('availability')
    .select('*')
    .eq('accommodation_id', accommodationId)
    .overlaps('start_date', [checkIn.toISOString(), checkOut.toISOString()]);

  if (error) throw error;
  return data.length === 0;
}