import React from 'react';
import { X } from 'lucide-react';
import { differenceInDays } from 'date-fns';
import { bookingRules } from '../utils/bookingRules';
import { createBooking } from '../services/bookings';
import { useCredits } from '../hooks/useCredits';

interface BookingModalProps {
  accommodation: {
    id: string;
    title: string;
    price: number;
  };
  checkIn: Date;
  checkOut: Date;
  onClose: () => void;
  onBookingComplete: () => void;
  isExtension?: boolean;
}

export function BookingModal({ 
  accommodation, 
  checkIn, 
  checkOut, 
  onClose, 
  onBookingComplete,
  isExtension = false 
}: BookingModalProps) {
  const [isLoading, setIsLoading] = React.useState(false);
  const [error, setError] = React.useState<string | null>(null);
  const { credits, loading: creditsLoading, refresh: refreshCredits } = useCredits();

  const numberOfDays = differenceInDays(checkOut, checkIn);
  const numberOfWeeks = Math.ceil(numberOfDays / 7);
  const totalAmount = accommodation.price * numberOfWeeks;

  const handleBooking = async () => {
    if (credits < totalAmount) {
      setError(`Insufficient credits. You need €${totalAmount} but have €${credits}`);
      return;
    }

    setIsLoading(true);
    setError(null);
    
    try {
      await createBooking(
        accommodation.id,
        checkIn,
        checkOut,
        totalAmount
      );
      await refreshCredits();
      onBookingComplete();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create booking');
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (date: Date) => {
    const formatter = new Intl.DateTimeFormat('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
    const parts = formatter.formatToParts(date);
    const month = parts.find(part => part.type === 'month')?.value;
    const day = parts.find(part => part.type === 'day')?.value;
    const year = parts.find(part => part.type === 'year')?.value;
    return `${month} ${day}${getOrdinalSuffix(parseInt(day || '0'))}, ${year}`;
  };

  const getOrdinalSuffix = (day: number) => {
    if (day > 3 && day < 21) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-display font-light">Confirm Your Journey</h2>
          <button onClick={onClose} className="text-stone-500 hover:text-stone-700">
            <X className="w-6 h-6" />
          </button>
        </div>
        
        <div className="space-y-4">
          <div>
            <h3 className="font-display text-lg">{accommodation.title}</h3>
          </div>

          <div className="border-t border-b border-stone-200 py-4">
            <div className="flex justify-between mb-2">
              <span>Arrival</span>
              <span>You may arrive {formatDate(checkIn)} from 3-6PM</span>
            </div>
            <div className="flex justify-between">
              <span>Departure</span>
              <span>You may depart {formatDate(checkOut)} by 12PM Noon</span>
            </div>
            <div className="flex justify-between mt-2 text-stone-600">
              <span>Duration</span>
              <span>{numberOfDays} days ({numberOfWeeks} weeks)</span>
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex justify-between text-stone-600">
              <span>Your Credits</span>
              <span>€{credits}</span>
            </div>
            <div className="flex justify-between text-stone-600">
              <span>Weekly rate</span>
              <span>€{accommodation.price}</span>
            </div>
            <div className="flex justify-between font-display text-lg">
              <span>Total Journey Cost</span>
              <span>€{totalAmount}</span>
            </div>
          </div>

          {!isExtension && (
            <div className="text-sm text-emerald-700 bg-emerald-50 p-3 rounded-lg">
              {bookingRules.minAdvance}
            </div>
          )}

          {error && (
            <div className="text-rose-600 text-sm bg-rose-50 p-3 rounded-lg">
              {error}
            </div>
          )}

          <button
            onClick={handleBooking}
            disabled={isLoading || creditsLoading || credits < totalAmount}
            className="w-full bg-emerald-900 text-white py-3 px-6 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300 disabled:cursor-not-allowed transition-colors text-sm font-body"
          >
            {isLoading ? 'Processing...' : credits < totalAmount ? 'Insufficient Credits' : 'Confirm Booking'}
          </button>
        </div>
      </div>
    </div>
  );
}