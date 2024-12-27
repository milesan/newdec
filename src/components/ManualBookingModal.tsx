import React, { useState } from 'react';
import { X } from 'lucide-react';
import { DayPicker, DateRange } from 'react-day-picker';
import { supabase } from '../lib/supabase';
import { convertToUTC1, getUTC1Date, CHECK_IN_HOUR, CHECK_OUT_HOUR } from '../utils/timezone';

interface Accommodation {
  id: string;
  title: string;
  type: string;
  price: number;
}

interface ManualBookingModalProps {
  onClose: () => void;
  onSuccess: () => void;
  accommodations: Accommodation[];
}

export function ManualBookingModal({ onClose, onSuccess, accommodations }: ManualBookingModalProps) {
  const [email, setEmail] = useState('');
  const [selectedDates, setSelectedDates] = useState<DateRange | undefined>();
  const [selectedAccommodation, setSelectedAccommodation] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [availableAccommodations, setAvailableAccommodations] = useState<Accommodation[]>(accommodations);
  const [isCheckingAvailability, setIsCheckingAvailability] = useState(false);

  const checkAvailability = async (from: Date, to: Date) => {
    try {
      setIsCheckingAvailability(true);
      setError(null);

      const utc1From = getUTC1Date(from);
      const utc1To = getUTC1Date(to);

      // Check for both booked and held dates
      const [{ data: bookedData, error: bookedError }, { data: heldData, error: heldError }] = await Promise.all([
        supabase
          .from('availability')
          .select('accommodation_id')
          .eq('status', 'BOOKED')
          .gte('date', utc1From.toISOString().split('T')[0])
          .lte('date', utc1To.toISOString().split('T')[0]),
        supabase
          .from('availability')
          .select('accommodation_id')
          .eq('status', 'HOLD')
          .gte('date', utc1From.toISOString().split('T')[0])
          .lte('date', utc1To.toISOString().split('T')[0])
      ]);

      if (bookedError) throw bookedError;
      if (heldError) throw heldError;

      // Combine unavailable IDs from both booked and held dates
      const unavailableIds = new Set([
        ...(bookedData?.map(item => item.accommodation_id) || []),
        ...(heldData?.map(item => item.accommodation_id) || [])
      ]);

      setSelectedAccommodation('');
      const available = accommodations.filter(acc => !unavailableIds.has(acc.id));
      setAvailableAccommodations(available);
    } catch (err) {
      console.error('Error checking availability:', err);
      setError(err instanceof Error ? err.message : 'Failed to check availability');
    } finally {
      setIsCheckingAvailability(false);
    }
  };

  const handleDateSelect = (range: DateRange | undefined) => {
    setSelectedDates(range);
    if (range?.from && range?.to) {
      checkAvailability(range.from, range.to);
    } else {
      setAvailableAccommodations(accommodations);
    }
  };

  const handleSubmit = async () => {
    if (!email || !selectedDates?.from || !selectedDates?.to || !selectedAccommodation) {
      setError('Please fill in all fields');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const accommodation = accommodations.find(acc => acc.id === selectedAccommodation);
      if (!accommodation) throw new Error('Selected accommodation not found');

      const { error: bookingError } = await supabase.rpc('create_manual_booking', {
        p_email: email,
        p_accommodation_id: selectedAccommodation,
        p_check_in: convertToUTC1(selectedDates.from).toISOString(),
        p_check_out: convertToUTC1(selectedDates.to).toISOString(),
        p_total_price: accommodation.price
      });

      if (bookingError) throw bookingError;

      onSuccess();
    } catch (err) {
      console.error('Error creating manual booking:', err);
      setError(err instanceof Error ? err.message : 'Failed to create booking');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-2xl w-full p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-semibold">Add Manual Booking</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="w-6 h-6" />
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-50 text-rose-600 rounded-lg">
            {error}
          </div>
        )}

        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Guest Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-emerald-500"
              placeholder="guest@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Select Dates
            </label>
            <DayPicker
              mode="range"
              selected={selectedDates}
              onSelect={handleDateSelect}
              disabled={{ before: new Date() }}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Accommodation
            </label>
            <select
              value={selectedAccommodation}
              onChange={(e) => setSelectedAccommodation(e.target.value)}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-emerald-500"
              disabled={!selectedDates || isCheckingAvailability}
            >
              <option value="">Select accommodation</option>
              {availableAccommodations.map((acc) => (
                <option key={acc.id} value={acc.id}>
                  {acc.title} - €{acc.price}
                </option>
              ))}
            </select>
            {isCheckingAvailability && (
              <p className="mt-1 text-sm text-gray-500">Checking availability...</p>
            )}
            {availableAccommodations.length === 0 && !isCheckingAvailability && selectedDates && (
              <p className="mt-1 text-sm text-rose-600">No accommodations available for selected dates</p>
            )}
          </div>

          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={loading || !email || !selectedDates || !selectedAccommodation}
              className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              {loading ? 'Creating...' : 'Create Booking'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}