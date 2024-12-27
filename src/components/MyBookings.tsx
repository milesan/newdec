import React from 'react';
import { format } from 'date-fns';
import { getUserBookings } from '../services/bookings';
import { motion } from 'framer-motion';
import { ExternalLink } from 'lucide-react';
import { useSession } from '../hooks/useSession';

export function MyBookings() {
  const [bookings, setBookings] = React.useState<any[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);
  const session = useSession();

  React.useEffect(() => {
    loadBookings();
  }, []);

  const loadBookings = async () => {
    try {
      setLoading(true);
      const data = await getUserBookings();
      setBookings(data || []);
    } catch (err) {
      console.error('Error loading bookings:', err);
      setError(err instanceof Error ? err.message : 'Failed to load bookings');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12">
        <div className="flex justify-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-12">
        <div className="bg-rose-50 text-rose-600 p-4 rounded-lg">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-12">
      <div className="flex justify-between items-start mb-8">
        <div>
          <h1 className="text-4xl font-display font-light text-stone-900 mb-2">My Account</h1>
          <div className="text-stone-600">
            <p>{session?.user?.email}</p>
          </div>
        </div>
      </div>
      
      {bookings.length === 0 ? (
        <div className="text-center text-stone-600">
          No bookings found. Book your first stay!
        </div>
      ) : (
        <div className="space-y-6">
          {bookings.map((booking) => (
            <motion.div
              key={booking.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white p-6 rounded-xl shadow-sm border border-stone-200"
            >
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-xl font-display font-light mb-2">
                    {booking.accommodations?.title || booking.accommodation_title || 'Accommodation'}
                  </h3>
                  <p className="text-stone-600 mb-4">
                    {booking.accommodations?.location || booking.accommodation_location || 'The Garden'}
                  </p>
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
                    <a 
                      href="https://gardening.notion.site/Welcome-to-The-Garden-2684f446b48e4b43b3f003d7fca33664?pvs=4"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 text-emerald-600 hover:text-emerald-700 transition-colors mt-2"
                    >
                      Welcome Guide
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  </div>
                </div>
                {(booking.accommodations?.image_url || booking.accommodation_image) && (
                  <img
                    src={booking.accommodations?.image_url || booking.accommodation_image}
                    alt={booking.accommodations?.title || booking.accommodation_title}
                    className="w-32 h-32 object-cover rounded-lg"
                  />
                )}
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
}