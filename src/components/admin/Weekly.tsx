import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { format, addDays, startOfWeek, endOfWeek, addWeeks, isSameWeek } from 'date-fns';
import { X, ChevronLeft, ChevronRight, Users, Calendar, BedDouble } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { generateWeeks } from '../../utils/dates';
import { convertToUTC1 } from '../../utils/timezone';

interface Props {
  onClose: () => void;
}

interface Accommodation {
  id: string;
  title: string;
  inventory_count: number;
  type: string;
}

interface Booking {
  id: string;
  accommodation_id: string;
  check_in: string;
  check_out: string;
  user_email: string;
  total_price: number;
}

interface WeeklyStatus {
  [key: string]: {
    isBooked: boolean;
    booking?: Booking;
  };
}

export function Weekly({ onClose }: Props) {
  const [currentWeekIndex, setCurrentWeekIndex] = useState(0);
  const [accommodations, setAccommodations] = useState<Accommodation[]>([]);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Generate weeks starting from Dec 16, 2024
  const weeks = generateWeeks(convertToUTC1(new Date('2024-12-16'), 0), 52);
  const currentWeek = weeks[currentWeekIndex];
  const weekStart = startOfWeek(currentWeek);
  const weekEnd = endOfWeek(currentWeek);

  useEffect(() => {
    loadData();

    const subscription = supabase
      .channel('bookings_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, () => {
        loadData();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [currentWeekIndex]);

  async function loadData() {
    try {
      setLoading(true);
      setError(null);

      // Load accommodations
      const { data: accommodationsData, error: accommodationsError } = await supabase
        .from('accommodations')
        .select('*')
        .order('price', { ascending: true });

      if (accommodationsError) throw accommodationsError;

      // Load bookings for current week using the booking_details view
      const { data: bookingsData, error: bookingsError } = await supabase
        .from('booking_details')
        .select(`
          id,
          accommodation_id,
          check_in,
          check_out,
          total_price,
          user_email
        `)
        .or(
          `check_in.lte.${weekEnd.toISOString()},check_out.gt.${weekStart.toISOString()}`
        )
        .eq('status', 'confirmed');

      if (bookingsError) throw bookingsError;

      setAccommodations(accommodationsData || []);
      setBookings(bookingsData || []);
    } catch (err) {
      console.error('Error loading data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  const getWeeklyStatus = (accommodation: Accommodation): WeeklyStatus[string] => {
    const booking = bookings.find(b => 
      b.accommodation_id === accommodation.id &&
      isSameWeek(new Date(b.check_in), currentWeek)
    );

    return {
      isBooked: !!booking,
      booking
    };
  };

  const getStatusColor = (status: WeeklyStatus[string]) => {
    if (status.isBooked) {
      return 'bg-black text-white border-stone-300';
    }
    return 'bg-emerald-500 text-white border-emerald-600';
  };

  // Adjust dates for display by subtracting one day
  const adjustDateForDisplay = (date: Date) => {
    return addDays(date, -1);
  };

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 overflow-hidden"
      >
        <motion.div
          initial={{ y: "100%" }}
          animate={{ y: 0 }}
          exit={{ y: "100%" }}
          transition={{ type: "spring", damping: 30, stiffness: 300 }}
          className="absolute inset-0 bg-white"
        >
          <div className="h-screen flex flex-col">
            <div className="p-4 border-b border-stone-200 flex justify-between items-center bg-white">
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setCurrentWeekIndex(prev => Math.max(0, prev - 1))}
                  disabled={currentWeekIndex === 0}
                  className="p-2 hover:bg-stone-100 rounded-full disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                
                <div className="text-center">
                  <h2 className="text-xl font-display">
                    {format(adjustDateForDisplay(weekStart), 'MMM d')} → {format(adjustDateForDisplay(weekEnd), 'MMM d, yyyy')}
                  </h2>
                  <p className="text-sm text-stone-500">
                    Week {currentWeekIndex + 1} of {weeks.length}
                  </p>
                </div>

                <button
                  onClick={() => setCurrentWeekIndex(prev => Math.min(weeks.length - 1, prev + 1))}
                  disabled={currentWeekIndex === weeks.length - 1}
                  className="p-2 hover:bg-stone-100 rounded-full disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-black"></div>
                    <span>Occupied</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-emerald-500"></div>
                    <span>Available</span>
                  </div>
                </div>

                <button
                  onClick={onClose}
                  className="p-2 hover:bg-stone-100 rounded-full text-stone-600 hover:text-stone-900 transition-colors"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-auto p-4">
              {error && (
                <div className="mb-4 p-4 bg-red-50 border-l-4 border-red-500 rounded">
                  <p className="text-red-700">{error}</p>
                </div>
              )}

              {loading ? (
                <div className="flex justify-center items-center h-96">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
                </div>
              ) : (
                <div className="grid gap-2">
                  {accommodations.map((accommodation) => {
                    const status = getWeeklyStatus(accommodation);
                    return (
                      <div
                        key={accommodation.id}
                        className={`p-4 rounded-lg border ${getStatusColor(status)} transition-colors`}
                      >
                        <div className="flex justify-between items-start">
                          <div>
                            <h3 className="text-lg font-display mb-1">
                              {accommodation.title}
                            </h3>
                            <div className="flex items-center gap-4 text-sm opacity-90">
                              <div className="flex items-center gap-1">
                                <BedDouble className="w-4 h-4" />
                                <span>{accommodation.inventory_count} unit{accommodation.inventory_count !== 1 ? 's' : ''}</span>
                              </div>
                              <div className="flex items-center gap-1">
                                <Calendar className="w-4 h-4" />
                                <span>{format(adjustDateForDisplay(weekStart), 'MMM d')} - {format(adjustDateForDisplay(weekEnd), 'MMM d')}</span>
                              </div>
                            </div>
                          </div>

                          {status.isBooked && status.booking && (
                            <div className="text-right">
                              <div className="flex items-center gap-2 mb-1">
                                <Users className="w-4 h-4" />
                                <span>{status.booking.user_email}</span>
                              </div>
                              <p className="text-sm opacity-90">
                                €{status.booking.total_price}
                              </p>
                            </div>
                          )}
                        </div>

                        {status.isBooked && status.booking && (
                          <div className="mt-3 pt-3 border-t border-white/20 grid grid-cols-2 gap-4 text-sm opacity-90">
                            <div>
                              <span className="opacity-75">Check-in:</span>
                              <p>{format(adjustDateForDisplay(new Date(status.booking.check_in)), 'MMM d, yyyy')}</p>
                            </div>
                            <div>
                              <span className="opacity-75">Check-out:</span>
                              <p>{format(adjustDateForDisplay(new Date(status.booking.check_out)), 'MMM d, yyyy')}</p>
                            </div>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            <div className="p-4 border-t border-stone-200 text-sm text-stone-500 text-center">
              Note: All dates shown are adjusted -1 day for display purposes only
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}