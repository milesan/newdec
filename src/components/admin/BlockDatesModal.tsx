import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { DayPicker } from 'react-day-picker';
import { format } from 'date-fns';

interface Props {
  onClose: () => void;
  onSave: () => void;
}

export function BlockDatesModal({ onClose, onSave }: Props) {
  const [selectedDates, setSelectedDates] = useState<Date[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    try {
      if (selectedDates.length === 0) {
        setError('Please select at least one date to block');
        return;
      }

      setSaving(true);
      setError(null);

      const { error: insertError } = await supabase
        .from('scheduling_rules')
        .insert([{
          start_date: selectedDates[0].toISOString().split('T')[0],
          end_date: selectedDates[selectedDates.length - 1].toISOString().split('T')[0],
          blocked_dates: selectedDates.map(date => date.toISOString().split('T')[0])
        }]);

      if (insertError) throw insertError;

      onSave();
      onClose();
    } catch (err) {
      console.error('Error blocking dates:', err);
      setError(err instanceof Error ? err.message : 'Failed to block dates');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-[60]">
      <div className="bg-white rounded-lg w-full max-w-md">
        <div className="p-4 border-b border-stone-200 flex justify-between items-center">
          <h3 className="text-lg font-medium">Block Specific Dates</h3>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-4">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-stone-700 mb-1">
                Select Dates to Block
              </label>
              <DayPicker
                mode="multiple"
                selected={selectedDates}
                onSelect={setSelectedDates}
                className="border rounded-lg bg-white"
              />
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
                onClick={handleSave}
                disabled={saving || selectedDates.length === 0}
                className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300"
              >
                {saving ? 'Saving...' : 'Block Dates'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}