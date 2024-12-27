import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { useSchedulingRules } from '../hooks/useSchedulingRules';
import { getSeasonalDiscount, getDurationDiscount } from '../utils/pricing';
import type { Accommodation } from '../types';
import { format, addDays } from 'date-fns';
import { useNavigate } from 'react-router-dom';
import { createBooking } from '../services/bookings';
import { supabase } from '../lib/supabase';
import { StripeCheckoutForm } from './StripeCheckoutForm';
import { useWeeklyAccommodations } from '../hooks/useWeeklyAccommodations';
import { useSession } from '../hooks/useSession';

interface Props {
  selectedWeeks: Date[];
  selectedAccommodation: Accommodation | null;
  baseRate: number;
  onClearWeeks: () => void;
  onClearAccommodation: () => void;
}

export function BookingSummary({
  selectedWeeks,
  selectedAccommodation,
  baseRate,
  onClearWeeks,
  onClearAccommodation,
}: Props) {
  const [isBooking, setIsBooking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showStripeModal, setShowStripeModal] = useState(false);
  const [authToken, setAuthToken] = useState('');
  const { getArrivalDepartureForDate } = useSchedulingRules();
  const { checkAvailability, availabilityMap } = useWeeklyAccommodations();
  const navigate = useNavigate();
  const session = useSession();
  const isAdmin = session?.user?.email === 'andre@thegarden.pt';

  React.useEffect(() => {
    supabase.auth.getSession().then(res => {
      const token = res?.data?.session?.access_token;
      if(token && token !== '') {
        setAuthToken(token);
      }
    });
  }, []);

  // Validate availability before showing Stripe modal
  const validateAvailability = async () => {
    if (!selectedAccommodation || selectedWeeks.length === 0) return false;

    const startDate = selectedWeeks[0];
    const endDate = addDays(selectedWeeks[selectedWeeks.length - 1], 6);
    
    await checkAvailability(startDate, endDate);
    
    const availabilityStatus = availabilityMap[selectedAccommodation.id];
    const isAvailable = selectedAccommodation.is_unlimited || 
      (selectedAccommodation.is_fungible ? availabilityStatus > 0 : availabilityStatus !== -1);

    return isAvailable;
  };

  if (selectedWeeks.length === 0 && !selectedAccommodation) return null;

  const numberOfWeeks = selectedWeeks.length;
  const baseAccommodationRate = selectedAccommodation?.price || 0;
  
  // Calculate seasonal discount
  const seasonalDiscount = selectedWeeks.length > 0 ? 
    selectedWeeks.reduce((acc, week) => acc + getSeasonalDiscount(week), 0) / selectedWeeks.length : 
    0;

  // Calculate duration discount
  const durationDiscount = getDurationDiscount(numberOfWeeks);
  
  // Apply seasonal discount to accommodation rate
  const accommodationRate = baseAccommodationRate * (1 - seasonalDiscount);

  // Special December 2024 rate for food & facilities
  const effectiveBaseRate = selectedWeeks.some(week => {
    const month = week.getMonth();
    const year = week.getFullYear();
    return month === 11 && year === 2024;
  }) ? 190 : baseRate;

  const weeklyRate = effectiveBaseRate + Math.round(accommodationRate);
  const subtotal = weeklyRate * numberOfWeeks;
  const durationDiscountAmount = Math.round(subtotal * durationDiscount);
  const totalAmount = Math.round(subtotal - durationDiscountAmount);

  const handleBookingSuccess = async () => {
    if (!selectedAccommodation) return;
    
    setIsBooking(true);
    setError(null);
    
    try {
      const checkIn = selectedWeeks[0];
      const checkOut = addDays(selectedWeeks[selectedWeeks.length - 1], 6);
      
      await createBooking(
        selectedAccommodation.id,
        checkIn,
        checkOut,
        totalAmount,
        true // Actually create the booking after payment
      );
      
      onClearWeeks();
      onClearAccommodation();
      setShowStripeModal(false);
      
      // Navigate to confirmation page with booking details
      navigate('/confirmation', {
        state: {
          booking: {
            checkIn,
            checkOut,
            accommodation: selectedAccommodation.title,
            totalPrice: totalAmount,
            guests: 1
          }
        }
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create booking');
    } finally {
      setIsBooking(false);
    }
  };

  const handleConfirmClick = async () => {
    setError(null);
    
    try {
      const isAvailable = await validateAvailability();
      if (!isAvailable) {
        setError('Selected accommodation is no longer available for these dates');
        return;
      }
      
      setShowStripeModal(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to validate availability');
    }
  };

  const handleAdminConfirm = async () => {
    if (!selectedAccommodation) return;
    
    setIsBooking(true);
    setError(null);
    
    try {
      const checkIn = selectedWeeks[0];
      const checkOut = addDays(selectedWeeks[selectedWeeks.length - 1], 6);
      
      await createBooking(
        selectedAccommodation.id,
        checkIn,
        checkOut,
        totalAmount,
        true
      );
      
      onClearWeeks();
      onClearAccommodation();
      
      navigate('/confirmation', {
        state: {
          booking: {
            checkIn,
            checkOut,
            accommodation: selectedAccommodation.title,
            totalPrice: totalAmount,
            guests: 1
          }
        }
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create booking');
    } finally {
      setIsBooking(false);
    }
  };

  // Get arrival/departure days for first and last week
  const firstWeek = selectedWeeks[0];
  const lastWeek = selectedWeeks[selectedWeeks.length - 1];
  
  const firstWeekDays = firstWeek ? getArrivalDepartureForDate(firstWeek) : null;
  const lastWeekDays = lastWeek ? getArrivalDepartureForDate(lastWeek) : null;

  return (
    <>
      <div 
        className="lg:sticky lg:z-50" 
        style={{ 
          position: '-webkit-sticky',
          position: 'sticky',
          top: 'calc(4.5rem + 1px)', // Height of navbar (4.5rem) plus border (1px)
          height: 'fit-content',
          maxHeight: 'calc(100vh - 4.5rem - 2rem)', // Viewport height minus navbar height minus some padding
          overflowY: 'auto'
        }}
      >
        <div className="bg-white p-8 pixel-corners">
          <h2 className="text-2xl font-serif font-light text-stone-900 mb-4">
            Summary of Stay
          </h2>

          {error && (
            <div className="mb-4 p-3 bg-rose-50 text-rose-600 rounded-lg flex justify-between items-center">
              <span>{error}</span>
              <button onClick={() => setError(null)}>
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {selectedWeeks.length > 0 && (
            <div className="space-y-6">
              <div>
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-medium">{numberOfWeeks} weeks</h3>
                  <button
                    onClick={onClearWeeks}
                    className="text-stone-400 hover:text-stone-600"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </div>

                <div className="space-y-2 text-stone-600">
                  <div className="text-lg font-serif">
                    {format(firstWeek, 'MMM d')} → {format(addDays(lastWeek, 6), 'MMM d')}
                  </div>
                  <div className="text-sm">
                    Check-in {firstWeekDays?.arrival.charAt(0).toUpperCase() + firstWeekDays?.arrival.slice(1)} 3-6PM
                  </div>
                  <div className="text-sm">
                    Check-out {lastWeekDays?.departure.charAt(0).toUpperCase() + lastWeekDays?.departure.slice(1)} 12PM
                  </div>
                </div>
              </div>

              {selectedAccommodation && (
                <div className="mb-6">
                  <div className="flex justify-between items-center mb-2">
                    <h3 className="font-medium">{selectedAccommodation.title}</h3>
                    <button
                      onClick={onClearAccommodation}
                      className="text-stone-400 hover:text-stone-600"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}

              <div className="grid grid-cols-[1fr,auto,1fr] items-center gap-2 font-mono text-base">
                <div className="text-right">€{effectiveBaseRate}</div>
                <div className="text-center text-stone-400">+</div>
                <div>
                  {selectedAccommodation?.price === 0 ? 'Free' : `€${Math.round(accommodationRate)}`}
                </div>
                <div className="text-right text-stone-500">food & facilities</div>
                <div></div>
                <div className="text-stone-500">accommodation</div>
              </div>

              <div className="border-t border-stone-200 pt-4">
                <div className="flex justify-between text-stone-600 mb-4">
                  <span>€{weeklyRate} × {numberOfWeeks} weeks</span>
                  <span>€{subtotal}</span>
                </div>

                {durationDiscount > 0 && (
                  <div className="flex justify-between text-emerald-600 mb-4">
                    <span>{Math.round(durationDiscount * 100)}% duration discount</span>
                    <span>-€{durationDiscountAmount}</span>
                  </div>
                )}

                <div className="flex justify-between text-xl font-serif border-t border-stone-200 pt-4">
                  <span>Total</span>
                  <span>€{totalAmount}</span>
                </div>
              </div>

              <motion.button
                onClick={handleConfirmClick}
                disabled={!selectedAccommodation || isBooking}
                className="w-full bg-emerald-900 text-white py-3 rounded-lg hover:bg-emerald-800 transition-colors disabled:bg-stone-300 disabled:cursor-not-allowed font-serif text-lg pixel-corners"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                {isBooking ? 'Processing...' : 'Confirm'}
              </motion.button>

              {isAdmin && (
                <motion.button
                  onClick={handleAdminConfirm}
                  disabled={!selectedAccommodation || isBooking}
                  className="w-full bg-rose-600 text-white py-3 rounded-lg hover:bg-rose-700 transition-colors disabled:bg-stone-300 disabled:cursor-not-allowed font-serif text-lg pixel-corners"
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                >
                  {isBooking ? 'Processing...' : 'Admin Confirm (No Payment)'}
                </motion.button>
              )}
            </div>
          )}
        </div>
      </div>

      <AnimatePresence>
        {showStripeModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-[60]"
          >
            <motion.div
              initial={{ scale: 0.95 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.95 }}
              className="bg-white rounded-lg max-w-xl w-full p-6"
            >
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-xl font-serif">Complete Payment</h3>
                <button
                  onClick={() => setShowStripeModal(false)}
                  className="text-stone-400 hover:text-stone-600"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {authToken && selectedAccommodation && (
                <StripeCheckoutForm
                  authToken={authToken}
                  total={totalAmount}
                  description={`${selectedAccommodation.title} for ${numberOfWeeks} weeks`}
                  onSuccess={handleBookingSuccess}
                />
              )}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}