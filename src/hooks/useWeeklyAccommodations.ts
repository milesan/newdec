import { useEffect, useState, useCallback } from 'react';
import { useAccommodations } from './useAccommodations';
import { useAvailability } from './useAvailability';
import { addDays, eachDayOfInterval } from 'date-fns';
import { supabase } from '../lib/supabase';

interface DormOccupancy {
  [dormId: string]: {
    [date: string]: number;
  };
}

export function useWeeklyAccommodations() {
  const { accommodations, loading: accommodationsLoading, error: accommodationsError, refresh } = useAccommodations();
  const { availabilityMap, loading: availabilityLoading, error: availabilityError, checkAvailability } = useAvailability();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [dormOccupancy, setDormOccupancy] = useState<DormOccupancy>({});

  useEffect(() => {
    setLoading(accommodationsLoading || availabilityLoading);
    setError(accommodationsError || availabilityError);
  }, [accommodationsLoading, availabilityLoading, accommodationsError, availabilityError]);

  const checkWeekAvailability = useCallback(async (startDate: Date, endDate: Date) => {
    if (!startDate || !endDate) return;

    try {
      // Get all bookings for the date range
      const { data: bookings, error } = await supabase
        .from('bookings')
        .select(`
          accommodation_id,
          check_in,
          check_out,
          accommodations!inner (
            id,
            parent_accommodation_id
          )
        `)
        .eq('status', 'confirmed')
        .or(`check_in.lte.${endDate.toISOString()},check_out.gt.${startDate.toISOString()}`);

      if (error) throw error;

      // Initialize occupancy tracking for dorms
      const occupancy: DormOccupancy = {};
      accommodations
        .filter(acc => acc.is_fungible && !acc.is_unlimited)
        .forEach(acc => {
          occupancy[acc.id] = {};
        });

      // Process each booking
      bookings?.forEach(booking => {
        const parentId = booking.accommodations.parent_accommodation_id;
        if (parentId && occupancy[parentId]) {
          const dates = eachDayOfInterval({
            start: new Date(booking.check_in),
            end: new Date(booking.check_out)
          });

          dates.forEach(date => {
            const dateStr = date.toISOString().split('T')[0];
            occupancy[parentId][dateStr] = (occupancy[parentId][dateStr] || 0) + 1;
          });
        }
      });

      setDormOccupancy(occupancy);
      await checkAvailability(startDate, addDays(endDate, 6));
    } catch (err) {
      console.error('Error checking availability:', err);
      setError(err instanceof Error ? err : new Error('Failed to check availability'));
    }
  }, [checkAvailability, accommodations]);

  const getMaxOccupancy = useCallback((dormId: string, startDate: Date, endDate: Date) => {
    const dateRange = eachDayOfInterval({ start: startDate, end: endDate });
    let maxOccupancy = 0;

    dateRange.forEach(date => {
      const dateStr = date.toISOString().split('T')[0];
      const occupancy = dormOccupancy[dormId]?.[dateStr] || 0;
      maxOccupancy = Math.max(maxOccupancy, occupancy);
    });

    return maxOccupancy;
  }, [dormOccupancy]);

  const isAccommodationAvailable = useCallback(async (accommodation: any, startDate?: Date, endDate?: Date) => {
    if (!startDate || !endDate) return false;

    try {
      // For unlimited accommodations
      if (accommodation.is_unlimited) return true;

      // For fungible accommodations (dorms)
      if (accommodation.is_fungible && !accommodation.is_unlimited) {
        const maxOccupancy = getMaxOccupancy(accommodation.id, startDate, endDate);
        return maxOccupancy < accommodation.inventory_count;
      }

      // For regular accommodations, check if there are any overlapping bookings
      const { data: bookings } = await supabase
        .from('bookings')
        .select('*')
        .eq('accommodation_id', accommodation.id)
        .eq('status', 'confirmed')
        .or(`check_in.lte.${endDate.toISOString()},check_out.gt.${startDate.toISOString()}`);

      return !bookings?.length;
    } catch (err) {
      console.error('Error checking availability:', err);
      return false;
    }
  }, [getMaxOccupancy]);

  return { 
    accommodations, 
    loading, 
    error,
    checkAvailability: checkWeekAvailability,
    availabilityMap,
    getMaxOccupancy,
    isAccommodationAvailable,
    refresh
  };
}