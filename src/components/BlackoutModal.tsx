import React, { useState } from 'react';
import { X } from 'lucide-react';
import { format } from 'date-fns';
import { supabase } from '../lib/supabase';

interface BlackoutModalProps {
  startDate: Date;
  endDate: Date;
  accommodations: any[];
  onClose: () => void;
  onSave: () => void;
}

export function BlackoutModal({ startDate, endDate, accommodations, onClose, onSave }: BlackoutModalProps) {
  const [selectedAccommodation, setSelectedAccommodation] = useState<string>('');
  const [reason, setReason] = useState<string>('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSave = async () => {
    if (!selectedAccommodation) {
      setError('Please select an accommodation');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const { error: insertError } = await supabase
        .from('blackout_dates')
        .insert({
          accommodation_id: selectedAccommodation,
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          reason: reason || 'Maintenance'
        });

      if (insertError) throw insertError;

      onSave();
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to save blackout dates');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold">Add Blackout Dates</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Dates
            </label>
            <p className="text-gray-600">
              {format(startDate, 'PP')} - {format(endDate, 'PP')}
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Accommodation
            </label>
            <select
              value={selectedAccommodation}
              onChange={(e) => setSelectedAccommodation(e.target.value)}
              className="w-full p-2 border rounded-lg"
            >
              <option value="">Select accommodation</option>
              {accommodations.map((acc) => (
                <option key={acc.id} value={acc.id}>
                  {acc.title}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Reason (optional)
            </label>
            <input
              type="text"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g., Maintenance, Private event"
              className="w-full p-2 border rounded-lg"
            />
          </div>

          {error && (
            <div className="text-red-500 text-sm">{error}</div>
          )}

          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving}
              className="bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              {saving ? 'Saving...' : 'Save'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}