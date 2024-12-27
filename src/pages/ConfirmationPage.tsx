import React from 'react';
import { motion } from 'framer-motion';
import { CheckCircle, Calendar, MapPin, Users, ArrowLeft, ExternalLink } from 'lucide-react';
import { format } from 'date-fns';
import { Link, useLocation, useNavigate } from 'react-router-dom';

export function ConfirmationPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const booking = location.state?.booking;

  React.useEffect(() => {
    // If user tries to access confirmation page directly without booking data
    if (!booking) {
      navigate('/my-bookings');
    }
  }, [booking, navigate]);

  // Handle back navigation
  React.useEffect(() => {
    const handleNavigation = (e: PopStateEvent) => {
      navigate('/my-bookings');
    };

    window.addEventListener('popstate', handleNavigation);
    return () => window.removeEventListener('popstate', handleNavigation);
  }, [navigate]);

  if (!booking) {
    return null;
  }

  return (
    <div className="min-h-screen bg-stone-50 flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-2xl w-full bg-white rounded-xl shadow-sm border border-stone-200 overflow-hidden"
      >
        <div className="p-8 text-center border-b border-stone-200">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
            className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6"
          >
            <CheckCircle className="w-8 h-8 text-emerald-600" />
          </motion.div>
          
          <h1 className="text-3xl font-display font-light text-stone-900 mb-2">
            Booking Confirmed
          </h1>
          <p className="text-stone-600 font-body">
            Your journey at The Garden awaits
          </p>
        </div>

        <div className="p-8 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-stone-600">
                <Calendar className="w-4 h-4" />
                <span className="text-sm">Check-in</span>
              </div>
              <p className="font-display text-xl">
                {format(new Date(booking.checkIn), 'EEEE, MMMM d')}
              </p>
              <p className="text-sm text-emerald-600">
                Available from 3-6PM
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-stone-600">
                <Calendar className="w-4 h-4" />
                <span className="text-sm">Check-out</span>
              </div>
              <p className="font-display text-xl">
                {format(new Date(booking.checkOut), 'EEEE, MMMM d')}
              </p>
              <p className="text-sm text-emerald-600">
                By 12PM Noon
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-stone-600">
                <MapPin className="w-4 h-4" />
                <span className="text-sm">Accommodation</span>
              </div>
              <p className="font-display text-xl">
                {booking.accommodation}
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center gap-2 text-stone-600">
                <Users className="w-4 h-4" />
                <span className="text-sm">Guests</span>
              </div>
              <p className="font-display text-xl">
                {booking.guests} {booking.guests === 1 ? 'Person' : 'People'}
              </p>
            </div>
          </div>

          <div className="border-t border-stone-200 pt-6">
            <div className="flex justify-between items-center text-lg font-display">
              <span>Total Amount Paid</span>
              <span>€{booking.totalPrice}</span>
            </div>
          </div>

          <div className="bg-emerald-50 p-6 rounded-lg space-y-4">
            <h3 className="font-display text-lg text-emerald-900">
              Tidbits
            </h3>
            <ul className="space-y-2 text-sm text-emerald-800">
              <li className="flex items-start gap-2">
                <span className="text-emerald-700 mt-1">❧</span>
                <span>This is a co-created experience. </span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-emerald-700 mt-1">❧</span>
                <span>The Garden is a strictly smoke & alcohol-free space</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="text-emerald-700 mt-1">❧</span>
                <span>Lunch & dinner included Monday-Friday</span>
              </li>
            </ul>
          </div>

          <a 
            href="https://gardening.notion.site/Welcome-to-The-Garden-2684f446b48e4b43b3f003d7fca33664?pvs=4"
            target="_blank"
            rel="noopener noreferrer"
            className="block w-full bg-emerald-900 text-white py-3 px-6 rounded-lg hover:bg-emerald-800 transition-colors text-center font-display text-lg flex items-center justify-center gap-2"
          >
            Welcome Guide
            <ExternalLink className="w-4 h-4" />
          </a>

          <Link 
            to="/my-bookings"
            className="inline-flex items-center gap-2 text-stone-600 hover:text-stone-900 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>View All Bookings</span>
          </Link>
        </div>
      </motion.div>
    </div>
  );
}