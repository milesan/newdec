import { addDays, startOfWeek, endOfWeek } from 'date-fns';
import { supabase } from '../lib/supabase';
import { convertToUTC1 } from '../utils/timezone';

export async function createWeeklyBooking(
  accommodationId: string,
  weeks: Date[],
  totalPrice: number
) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('User not authenticated');

  // Convert weeks to check-in/check-out dates
  const firstWeek = weeks[0];
  const lastWeek = weeks[weeks.length - 1];
  
  const checkIn = convertToUTC1(startOfWeek(firstWeek));
  const checkOut = convertToUTC1(addDays(endOfWeek(lastWeek), 1)); // Add 1 day to include the full last day

  try {
    // Create the booking
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert({
        accommodation_id: accommodationId,
        user_id: user.id,
        check_in: checkIn.toISOString(),
        check_out: checkOut.toISOString(),
        total_price: totalPrice,
        status: 'confirmed'
      })
      .select()
      .single();

    if (bookingError) throw bookingError;

    // Mark dates as booked in availability
    const dates = [];
    let currentDate = checkIn;
    while (currentDate < checkOut) {
      dates.push(currentDate.toISOString().split('T')[0]);
      currentDate = addDays(currentDate, 1);
    }

    const { error: availabilityError } = await supabase
      .from('availability')
      .insert(
        dates.map(date => ({
          accommodation_id: accommodationId,
          date,
          status: 'BOOKED'
        }))
      );

    if (availabilityError) throw availabilityError;

    return booking;
  } catch (error) {
    console.error('Error creating booking:', error);
    throw error;
  }
}

export async function checkWeekAvailability(
  accommodationId: string,
  weeks: Date[]
): Promise<boolean> {
  try {
    const firstWeek = weeks[0];
    const lastWeek = weeks[weeks.length - 1];
    
    const startDate = startOfWeek(firstWeek);
    const endDate = addDays(endOfWeek(lastWeek), 1); // Add 1 day to include the full last day

    const { data: unavailableDates, error } = await supabase
      .from('availability')
      .select('*')
      .eq('accommodation_id', accommodationId)
      .in('status', ['BOOKED', 'HOLD'])
      .gte('date', startDate.toISOString().split('T')[0])
      .lt('date', endDate.toISOString().split('T')[0]);

    if (error) throw error;
    return !unavailableDates || unavailableDates.length === 0;
  } catch (error) {
    console.error('Error checking availability:', error);
    throw error;
  }
}