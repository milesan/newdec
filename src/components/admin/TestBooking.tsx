import React, { useState } from 'react';
import { X } from 'lucide-react';
import { DayPicker, DateRange } from 'react-day-picker';
import { supabase } from '../../lib/supabase';
import { format } from 'date-fns';

interface Props {
  onClose: () => void;
  onSuccess: () => void;
  accommodations: any[];
}

export function TestBooking({ onClose, onSuccess, accommodations }: Props) {
  const [selectedDates, setSelectedDates] = useState<DateRange | undefined>();
  const [selectedAccommodation, setSelectedAccommodation] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!selectedDates?.from || !selectedDates?.to || !selectedAccommodation) {
      setError('Please select dates and accommodation');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { error: bookingError } = await supabase
        .rpc('create_confirmed_booking', {
          p_accommodation_id: selectedAccommodation,
          p_user_id: user.id,
          p_check_in: selectedDates.from.toISOString(),
          p_check_out: selectedDates.to.toISOString(),
          p_total_price: 0 // Free for test bookings
        });

      if (bookingError) throw bookingError;

      onSuccess();
      onClose();
    } catch (err) {
      console.error('Error creating test booking:', err);
      setError(err instanceof Error ? err.message : 'Failed to create booking');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-[60]">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-xl font-display">Create Test Booking</h3>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Select Dates
            </label>
            <DayPicker
              mode="range"
              selected={selectedDates}
              onSelect={setSelectedDates}
              numberOfMonths={2}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Accommodation
            </label>
            <select
              value={selectedAccommodation}
              onChange={(e) => setSelectedAccommodation(e.target.value)}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-emerald-500"
            >
              <option value="">Select accommodation</option>
              {accommodations.map((acc) => (
                <option key={acc.id} value={acc.id}>
                  {acc.title}
                </option>
              ))}
            </select>
          </div>

          {error && (
            <div className="p-3 bg-rose-50 text-rose-600 rounded-lg text-sm">
              {error}
            </div>
          )}

          <div className="flex justify-end gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-stone-600 hover:text-stone-900"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={loading || !selectedDates?.from || !selectedDates?.to || !selectedAccommodation}
              className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300"
            >
              {loading ? 'Creating...' : 'Create Test Booking'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}