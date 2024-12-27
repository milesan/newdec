import React, { useState, useEffect } from 'react';
import { format, addDays } from 'date-fns';
import { supabase } from '../lib/supabase';
import { Calendar, ChevronLeft, ChevronRight, X } from 'lucide-react';
import { StatusModal } from './StatusModal';
import type { AvailabilityStatus } from '../types/availability';
import { motion, AnimatePresence } from 'framer-motion';
import { ManualBookingModal } from './ManualBookingModal';

interface Props {
  onClose: () => void;
}

interface DormOccupancy {
  [date: string]: number;
}

interface DormBookings {
  [accommodationId: string]: DormOccupancy;
}

export function InventoryCalendar({ onClose }: Props) {
  const [events, setEvents] = useState<any[]>([]);
  const [accommodations, setAccommodations] = useState<any[]>([]);
  const [selectedAccommodation, setSelectedAccommodation] = useState<string>('all');
  const [showStatusModal, setShowStatusModal] = useState(false);
  const [showManualBooking, setShowManualBooking] = useState(false);
  const [selectedDates, setSelectedDates] = useState<{ start: Date; end: Date } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentDate, setCurrentDate] = useState(() => new Date());
  const [dormBookings, setDormBookings] = useState<DormBookings>({});

  const daysInMonth = Array.from({ length: new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate() }, 
    (_, i) => new Date(currentDate.getFullYear(), currentDate.getMonth(), i + 1));

  useEffect(() => {
    loadData();
  }, [currentDate, selectedAccommodation]);

  async function loadData() {
    try {
      setLoading(true);
      setError(null);

      // Load accommodations
      const { data: accommodationsData, error: accommodationsError } = await supabase
        .from('accommodations')
        .select('*')
        .order('title')
        .is('parent_accommodation_id', null); // Only get parent accommodations
      
      if (accommodationsError) throw accommodationsError;

      // Load all bookings for the month
      const monthStart = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
      const monthEnd = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);

      const { data: bookingsData, error: bookingsError } = await supabase
        .from('bookings')
        .select(`
          id,
          accommodation_id,
          check_in,
          check_out,
          accommodations!inner (
            id,
            title,
            parent_accommodation_id
          )
        `)
        .eq('status', 'confirmed')
        .or(
          `check_in.lte.${monthEnd.toISOString()},check_out.gt.${monthStart.toISOString()}`
        );

      if (bookingsError) throw bookingsError;

      // Process dorm bookings
      const dormOccupancy: DormBookings = {};
      const dormIds = accommodationsData
        ?.filter(acc => acc.title.includes('Dorm'))
        .map(acc => acc.id) || [];

      dormIds.forEach(dormId => {
        dormOccupancy[dormId] = {};
        daysInMonth.forEach(day => {
          dormOccupancy[dormId][format(day, 'yyyy-MM-dd')] = 0;
        });
      });

      // Count occupancy for each dorm
      bookingsData?.forEach(booking => {
        const acc = booking.accommodations;
        if (acc.parent_accommodation_id && dormIds.includes(acc.parent_accommodation_id)) {
          const bookingStart = new Date(booking.check_in);
          const bookingEnd = new Date(booking.check_out);
          let currentDate = new Date(bookingStart);

          while (currentDate < bookingEnd) {
            const dateStr = format(currentDate, 'yyyy-MM-dd');
            if (dormOccupancy[acc.parent_accommodation_id][dateStr] !== undefined) {
              dormOccupancy[acc.parent_accommodation_id][dateStr]++;
            }
            currentDate = addDays(currentDate, 1);
          }
        }
      });

      setAccommodations(accommodationsData || []);
      setEvents(bookingsData || []);
      setDormBookings(dormOccupancy);
    } catch (err) {
      console.error('Error loading data:', err);
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  }

  const getDateStatus = (date: Date, accommodationId: string): AvailabilityStatus => {
    const dateStr = date.toISOString().split('T')[0];
    
    for (const booking of events) {
      if (booking.accommodation_id === accommodationId) {
        const checkIn = booking.check_in.split('T')[0];
        const checkOut = booking.check_out.split('T')[0];
        
        if (dateStr === checkIn) return 'CHECK_IN';
        if (dateStr === checkOut) return 'CHECK_OUT';
        if (dateStr > checkIn && dateStr < checkOut) return 'BOOKED';
      }
    }
    
    return 'AVAILABLE';
  };

  const getCellStyle = (status: AvailabilityStatus | number) => {
    const baseStyle = 'h-8 px-2 text-center text-xs border-r cursor-pointer transition-colors';
    
    if (typeof status === 'number') {
      // For dorm occupancy numbers
      return `${baseStyle} bg-white`;
    }

    switch (status) {
      case 'CHECK_IN':
        return `${baseStyle} bg-gradient-to-r from-emerald-500 to-black text-white`;
      case 'CHECK_OUT':
        return `${baseStyle} bg-gradient-to-l from-emerald-500 to-black text-white`;
      case 'BOOKED':
        return `${baseStyle} bg-black text-white cursor-not-allowed`;
      case 'HOLD':
        return `${baseStyle} bg-yellow-400`;
      default:
        return `${baseStyle} bg-emerald-500 text-white`;
    }
  };

  const getCellContent = (accommodation: any, date: Date) => {
    const dateStr = format(date, 'yyyy-MM-dd');

    // Handle dorms differently
    if (accommodation.title.includes('Dorm')) {
      const occupancy = dormBookings[accommodation.id]?.[dateStr] || 0;
      return occupancy.toString();
    }

    // Regular accommodation handling
    const status = getDateStatus(date, accommodation.id);
    switch (status) {
      case 'CHECK_IN':
        return '→';
      case 'CHECK_OUT':
        return '←';
      case 'BOOKED':
        return '×';
      case 'HOLD':
        return '⌛';
      default:
        return '✓';
    }
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
              <div className="flex items-center gap-4">
                <button
                  onClick={() => setCurrentDate(prev => new Date(prev.getFullYear(), prev.getMonth() - 1))}
                  className="p-2 hover:bg-gray-100 rounded-full"
                >
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <h2 className="text-xl font-semibold">
                  {format(adjustDateForDisplay(currentDate), 'MMMM yyyy')}
                </h2>
                <button
                  onClick={() => setCurrentDate(prev => new Date(prev.getFullYear(), prev.getMonth() + 1))}
                  className="p-2 hover:bg-gray-100 rounded-full"
                >
                  <ChevronRight className="w-5 h-5" />
                </button>
              </div>

              <div className="flex items-center gap-4">
                <button
                  onClick={() => setShowManualBooking(true)}
                  className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800"
                >
                  Add Manual Booking
                </button>

                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-emerald-500"></div>
                    <span>Available</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
                    <span>Hold</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-black"></div>
                    <span>Booked</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="w-20 h-3 rounded-full bg-gradient-to-r from-emerald-500 to-black"></div>
                    <span>Check-in/out</span>
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

            <div className="flex-1 overflow-auto p-6">
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
                <div className="overflow-x-auto">
                  <table className="w-full divide-y divide-gray-200" style={{ tableLayout: 'fixed' }}>
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="sticky left-0 bg-gray-50 px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-[200px]">
                          Accommodation
                        </th>
                        {daysInMonth.map(day => (
                          <th key={day.toISOString()} className="px-2 py-2 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                            <div>{format(adjustDateForDisplay(day), 'd')}</div>
                            <div>{format(adjustDateForDisplay(day), 'EEE')}</div>
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {accommodations.map((accommodation) => (
                        <tr key={accommodation.id}>
                          <td className="sticky left-0 bg-white px-4 py-2 whitespace-nowrap border-r">
                            <div className="text-sm font-medium text-gray-900">
                              {accommodation.title} ({accommodation.inventory_count})
                            </div>
                          </td>
                          {daysInMonth.map(day => {
                            const status = accommodation.title.includes('Dorm')
                              ? dormBookings[accommodation.id]?.[format(day, 'yyyy-MM-dd')] || 0
                              : getDateStatus(day, accommodation.id);
                            return (
                              <td
                                key={day.toISOString()}
                                className={getCellStyle(status)}
                              >
                                {getCellContent(accommodation, day)}
                              </td>
                            );
                          })}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            <div className="p-4 border-t border-stone-200 text-sm text-stone-500 text-center">
              Note: All dates shown are adjusted -1 day for display purposes only
            </div>
          </div>
        </motion.div>
      </motion.div>

      {showStatusModal && (
        <StatusModal
          onClose={() => {
            setShowStatusModal(false);
            setSelectedDates(null);
          }}
          onSave={async (status) => {
            if (!selectedDates) return;
            try {
              const { error } = await supabase
                .from('availability')
                .insert({
                  accommodation_id: selectedAccommodation,
                  date: selectedDates.start.toISOString(),
                  status
                });

              if (error) throw error;
              await loadData();
              setShowStatusModal(false);
              setSelectedDates(null);
            } catch (err) {
              console.error('Error saving availability:', err);
              setError(err instanceof Error ? err.message : 'Failed to save availability');
            }
          }}
        />
      )}

      {showManualBooking && (
        <ManualBookingModal
          onClose={() => setShowManualBooking(false)}
          onSuccess={() => {
            setShowManualBooking(false);
            loadData();
          }}
          accommodations={accommodations}
        />
      )}
    </AnimatePresence>
  );
}