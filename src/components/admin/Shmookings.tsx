import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { supabase } from '../../lib/supabase';
import { Search, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface Booking {
  id: string;
  check_in: string;
  check_out: string;
  total_price: number;
  status: string;
  created_at: string;
  accommodation_title: string;
  accommodation_type: string;
  user_email: string;
}

export function Shmookings() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filter, setFilter] = useState<'all' | 'email' | 'accommodation'>('all');

  useEffect(() => {
    loadBookings();

    // Subscribe to booking changes
    const bookingsSubscription = supabase
      .channel('shmookings_channel')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, () => {
        loadBookings();
      })
      .subscribe();

    return () => {
      bookingsSubscription.unsubscribe();
    };
  }, []);

  async function loadBookings() {
    try {
      // First get all bookings
      const { data: bookingsData, error: bookingsError } = await supabase
        .from('bookings')
        .select('*')
        .order('created_at', { ascending: false });

      if (bookingsError) throw bookingsError;

      // Then fetch the related data
      const enrichedBookings = await Promise.all((bookingsData || []).map(async (booking) => {
        // Get accommodation details
        const { data: accomData } = await supabase
          .from('accommodations')
          .select('title, type')
          .eq('id', booking.accommodation_id)
          .single();

        // Get user details
        const { data: userData } = await supabase
          .from('profiles')
          .select('email')
          .eq('id', booking.user_id)
          .single();

        return {
          ...booking,
          accommodation_title: accomData?.title || 'N/A',
          accommodation_type: accomData?.type || 'N/A',
          user_email: userData?.email || 'N/A'
        };
      }));

      setBookings(enrichedBookings);
    } catch (err) {
      console.error('Error loading bookings:', err);
      setError(err instanceof Error ? err.message : 'Failed to load bookings');
    } finally {
      setLoading(false);
    }
  }

  const filteredBookings = bookings.filter(booking => {
    if (!searchTerm) return true;
    
    const searchLower = searchTerm.toLowerCase();
    
    switch (filter) {
      case 'email':
        return booking.user_email.toLowerCase().includes(searchLower);
      case 'accommodation':
        return (
          booking.accommodation_title.toLowerCase().includes(searchLower) ||
          booking.accommodation_type.toLowerCase().includes(searchLower)
        );
      default:
        return (
          booking.user_email.toLowerCase().includes(searchLower) ||
          booking.accommodation_title.toLowerCase().includes(searchLower) ||
          booking.accommodation_type.toLowerCase().includes(searchLower)
        );
    }
  });

  if (loading) {
    return (
      <div className="flex justify-center items-center p-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 text-rose-600 bg-rose-50 rounded-lg">
        {error}
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6 space-y-4">
        <div className="flex items-center gap-4">
          <div className="relative flex-1">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search bookings..."
              className="w-full pl-10 pr-4 py-2 border border-stone-200 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            />
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-stone-400" />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3 top-1/2 transform -translate-y-1/2 text-stone-400 hover:text-stone-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
          <select
            value={filter}
            onChange={(e) => setFilter(e.target.value as 'all' | 'email' | 'accommodation')}
            className="px-4 py-2 border border-stone-200 rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
          >
            <option value="all">All Fields</option>
            <option value="email">Email Only</option>
            <option value="accommodation">Accommodation Only</option>
          </select>
        </div>
      </div>

      <div className="space-y-4">
        <AnimatePresence>
          {filteredBookings.map((booking) => (
            <motion.div
              key={booking.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="bg-white p-6 rounded-lg border border-stone-200 hover:border-emerald-900/20 transition-colors"
            >
              <div className="flex justify-between items-start">
                <div className="space-y-2">
                  <div>
                    <h3 className="font-medium text-lg">{booking.accommodation_title}</h3>
                    <p className="text-stone-600">{booking.accommodation_type}</p>
                  </div>
                  <p className="text-stone-600">{booking.user_email}</p>
                  <div className="space-y-1 text-sm">
                    <p>
                      <span className="text-stone-500">Check-in:</span>{' '}
                      {format(new Date(booking.check_in), 'PPP')}
                    </p>
                    <p>
                      <span className="text-stone-500">Check-out:</span>{' '}
                      {format(new Date(booking.check_out), 'PPP')}
                    </p>
                    <p>
                      <span className="text-stone-500">Total Price:</span>{' '}
                      €{booking.total_price}
                    </p>
                    <p>
                      <span className="text-stone-500">Booked on:</span>{' '}
                      {format(new Date(booking.created_at), 'PPP')}
                    </p>
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                  booking.status === 'confirmed' 
                    ? 'bg-emerald-100 text-emerald-800'
                    : booking.status === 'pending'
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-rose-100 text-rose-800'
                }`}>
                  {booking.status}
                </span>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
        
        {filteredBookings.length === 0 && (
          <div className="text-center py-12 text-stone-600">
            No bookings found matching your search criteria.
          </div>
        )}
      </div>
    </div>
  );
}