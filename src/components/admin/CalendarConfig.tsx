import React, { useState, useEffect } from 'react';
import { X, Calendar, Trash2 } from 'lucide-react';
import { DayPicker } from 'react-day-picker';
import { format, parseISO } from 'date-fns';
import { supabase } from '../../lib/supabase';

interface Props {
  onClose: () => void;
  onSave: () => void;
}

interface Rule {
  id: string;
  start_date: string;
  end_date: string;
  arrival_day: string;
  departure_day: string;
  is_blocked: boolean;
  created_at: string;
}

export function CalendarConfig({ onClose, onSave }: Props) {
  const [startDate, setStartDate] = useState<Date>();
  const [endDate, setEndDate] = useState<Date>();
  const [arrivalDay, setArrivalDay] = useState('tuesday');
  const [departureDay, setDepartureDay] = useState('monday');
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [rules, setRules] = useState<Rule[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRules();
  }, []);

  const loadRules = async () => {
    try {
      setLoading(true);
      const { data, error: queryError } = await supabase
        .from('scheduling_rules')
        .select('*')
        .order('start_date', { ascending: true });

      if (queryError) throw queryError;
      setRules(data || []);
    } catch (err) {
      console.error('Error loading rules:', err);
      setError(err instanceof Error ? err.message : 'Failed to load rules');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!startDate || !endDate) {
      setError('Please select both start and end dates');
      return;
    }

    if (arrivalDay === departureDay) {
      setError('Arrival and departure days cannot be the same');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const { error: insertError } = await supabase
        .from('scheduling_rules')
        .insert([{
          start_date: startDate.toISOString().split('T')[0],
          end_date: endDate.toISOString().split('T')[0],
          arrival_day: arrivalDay,
          departure_day: departureDay
        }]);

      if (insertError) throw insertError;

      await loadRules();
      onSave();
      
      // Reset form
      setStartDate(undefined);
      setEndDate(undefined);
      setArrivalDay('tuesday');
      setDepartureDay('monday');
    } catch (err) {
      console.error('Error saving rule:', err);
      setError(err instanceof Error ? err.message : 'Failed to save rule');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      const { error: deleteError } = await supabase
        .from('scheduling_rules')
        .delete()
        .eq('id', id);

      if (deleteError) throw deleteError;
      await loadRules();
    } catch (err) {
      console.error('Error deleting rule:', err);
      setError(err instanceof Error ? err.message : 'Failed to delete rule');
    }
  };

  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-[60]">
      <div className="bg-white rounded-lg w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-stone-200 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <Calendar className="w-6 h-6 text-emerald-900" />
            <h2 className="text-2xl font-display font-light">Configure Calendar Range</h2>
          </div>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 overflow-auto">
          <div className="p-6 grid grid-cols-2 gap-8">
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-stone-700 mb-1">
                    Start Date
                  </label>
                  <DayPicker
                    mode="single"
                    selected={startDate}
                    onSelect={setStartDate}
                    className="border rounded-lg bg-white"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-stone-700 mb-1">
                    End Date
                  </label>
                  <DayPicker
                    mode="single"
                    selected={endDate}
                    onSelect={setEndDate}
                    disabled={date => date < (startDate || new Date())}
                    className="border rounded-lg bg-white"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-stone-700 mb-1">
                    Arrival Day
                  </label>
                  <select
                    value={arrivalDay}
                    onChange={(e) => setArrivalDay(e.target.value)}
                    className="w-full p-2 border rounded-lg"
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
                    className="w-full p-2 border rounded-lg"
                  >
                    {days.map(day => (
                      <option key={day} value={day}>
                        {day.charAt(0).toUpperCase() + day.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>
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
                  disabled={saving || !startDate || !endDate || arrivalDay === departureDay}
                  className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300"
                >
                  {saving ? 'Saving...' : 'Add Rule'}
                </button>
              </div>
            </div>

            <div className="border-l pl-8">
              <h4 className="text-xl font-display font-light mb-6">Current Rules</h4>
              {loading ? (
                <div className="flex justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
                </div>
              ) : (
                <div className="space-y-4 max-h-[600px] overflow-y-auto pr-4">
                  {rules.map((rule) => (
                    <div
                      key={rule.id}
                      className="bg-white p-6 rounded-lg border border-stone-200 hover:border-emerald-900/20 transition-colors"
                    >
                      <div className="flex justify-between items-start">
                        <div className="space-y-2">
                          <p className="font-display text-lg">
                            {format(parseISO(rule.start_date), 'MMM d, yyyy')} - {format(parseISO(rule.end_date), 'MMM d, yyyy')}
                          </p>
                          {rule.is_blocked ? (
                            <p className="text-rose-600 font-medium">Blocked Period</p>
                          ) : (
                            <div className="text-stone-600">
                              {rule.arrival_day && (
                                <p>Arrival: {rule.arrival_day.charAt(0).toUpperCase() + rule.arrival_day.slice(1)}</p>
                              )}
                              {rule.departure_day && (
                                <p>Departure: {rule.departure_day.charAt(0).toUpperCase() + rule.departure_day.slice(1)}</p>
                              )}
                            </div>
                          )}
                        </div>
                        <button
                          onClick={() => handleDelete(rule.id)}
                          className="text-stone-400 hover:text-rose-600 transition-colors"
                        >
                          <Trash2 className="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}