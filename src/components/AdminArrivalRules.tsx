import React, { useState } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useArrivalRules } from '../hooks/useArrivalRules';

interface Props {
  onClose: () => void;
}

export function AdminArrivalRules({ onClose }: Props) {
  const { rules: currentRules, loading: rulesLoading } = useArrivalRules();
  const [arrivalDay, setArrivalDay] = useState(currentRules.arrival_day);
  const [departureDay, setDepartureDay] = useState(currentRules.departure_day);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSave = async () => {
    if (arrivalDay === departureDay) {
      setError('Arrival and departure days cannot be the same');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      // Get the current rule
      const { data: currentRule } = await supabase
        .from('arrival_rules')
        .select('id')
        .single();

      if (currentRule) {
        // Update existing rule
        const { error: updateError } = await supabase
          .from('arrival_rules')
          .update({
            arrival_day: arrivalDay,
            departure_day: departureDay,
            updated_at: new Date().toISOString()
          })
          .eq('id', currentRule.id);

        if (updateError) throw updateError;
      } else {
        // Insert new rule
        const { error: insertError } = await supabase
          .from('arrival_rules')
          .insert({
            arrival_day: arrivalDay,
            departure_day: departureDay
          });

        if (insertError) throw insertError;
      }

      onClose();
    } catch (err) {
      console.error('Error saving rules:', err);
      setError('Failed to save rules. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  if (rulesLoading) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
        <div className="bg-white rounded-lg p-6">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900 mx-auto"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-md w-full p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-display font-light">Arrival & Departure Rules</h2>
          <button onClick={onClose} className="text-stone-500 hover:text-stone-700">
            <X className="w-6 h-6" />
          </button>
        </div>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Arrival Day
            </label>
            <select
              value={arrivalDay}
              onChange={(e) => setArrivalDay(e.target.value)}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-emerald-500"
            >
              {days.map(day => (
                <option key={day} value={day}>
                  {day.charAt(0).toUpperCase() + day.slice(1)}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-stone-700 mb-1">
              Departure Day
            </label>
            <select
              value={departureDay}
              onChange={(e) => setDepartureDay(e.target.value)}
              className="w-full p-2 border rounded-lg focus:ring-2 focus:ring-emerald-500"
            >
              {days.map(day => (
                <option key={day} value={day}>
                  {day.charAt(0).toUpperCase() + day.slice(1)}
                </option>
              ))}
            </select>
          </div>

          {error && (
            <div className="text-rose-600 text-sm bg-rose-50 p-3 rounded-lg">
              {error}
            </div>
          )}

          <div className="flex justify-end gap-2 mt-6">
            <button
              onClick={onClose}
              className="px-4 py-2 text-stone-600 hover:text-stone-800"
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving || arrivalDay === departureDay}
              className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300"
            >
              {saving ? 'Saving...' : 'Save Rules'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}