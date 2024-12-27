import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { addDays } from 'date-fns';

export function useAvailability() {
  const [availabilityMap, setAvailabilityMap] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const checkAvailability = useCallback(async (startDate: Date, endDate: Date) => {
    if (!startDate || !endDate) return;

    try {
      setLoading(true);
      setError(null);

      // Get all accommodations first
      const { data: accommodations, error: accError } = await supabase
        .from('accommodations')
        .select(`
          *,
          parent:parent_accommodation_id (
            id,
            title,
            inventory_count,
            is_unlimited,
            is_fungible
          )
        `)
        .is('parent_accommodation_id', null);

      if (accError) throw accError;

      // Get all bookings that overlap with the selected date range
      const { data: bookings, error: bookingsError } = await supabase
        .from('bookings')
        .select(`
          id,
          accommodation_id,
          check_in,
          check_out
        `)
        .eq('status', 'confirmed')
        .or(`check_in.lte.${endDate.toISOString()},check_out.gt.${startDate.toISOString()}`);

      if (bookingsError) throw bookingsError;

      const newAvailabilityMap: Record<string, number> = {};

      // Process each accommodation
      accommodations?.forEach(acc => {
        // Handle unlimited accommodations
        if (acc.is_unlimited) {
          newAvailabilityMap[acc.id] = 999;
          return;
        }

        // Handle fungible accommodations (dorms, etc)
        if (acc.is_fungible) {
          let maxBookedUnits = 0;
          const currentDate = new Date(startDate);

          // Check each day in the range
          while (currentDate <= endDate) {
            const bookedUnits = bookings?.filter(b => {
              const bookingStart = new Date(b.check_in);
              const bookingEnd = new Date(b.check_out);
              return (b.accommodation_id === acc.id) &&
                     currentDate >= bookingStart &&
                     currentDate < bookingEnd;
            }).length || 0;

            maxBookedUnits = Math.max(maxBookedUnits, bookedUnits);
            currentDate.setDate(currentDate.getDate() + 1);
          }

          newAvailabilityMap[acc.id] = Math.max(0, acc.inventory_count - maxBookedUnits);
        } else {
          // Handle regular accommodations
          const isBooked = bookings?.some(b => {
            const bookingStart = new Date(b.check_in);
            const bookingEnd = new Date(b.check_out);
            return b.accommodation_id === acc.id &&
                   bookingStart < endDate &&
                   bookingEnd > startDate;
          });

          newAvailabilityMap[acc.id] = isBooked ? -1 : 1;
        }
      });

      setAvailabilityMap(newAvailabilityMap);
    } catch (err) {
      console.error('Error checking availability:', err);
      setError(err instanceof Error ? err : new Error('Failed to check availability'));
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    availabilityMap,
    loading,
    error,
    checkAvailability
  };
}