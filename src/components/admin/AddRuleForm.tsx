import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { DayPicker } from 'react-day-picker';
import { format, parseISO } from 'date-fns';
import type { SchedulingRule } from '../../types/scheduling';

interface Props {
  onClose: () => void;
  onSave: () => void;
  editingRule?: SchedulingRule | null;
}

const DAYS_OF_WEEK = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday'
] as const;

export function AddRuleForm({ onClose, onSave, editingRule }: Props) {
  const [startDate, setStartDate] = useState<Date | undefined>(
    editingRule ? new Date(editingRule.start_date) : undefined
  );
  const [endDate, setEndDate] = useState<Date | undefined>(
    editingRule ? new Date(editingRule.end_date) : undefined
  );
  const [isBlocked, setIsBlocked] = useState(editingRule?.is_blocked || false);
  const [arrivalDay, setArrivalDay] = useState<string | undefined>(editingRule?.arrival_day || undefined);
  const [departureDay, setDepartureDay] = useState<string | undefined>(editingRule?.departure_day || undefined);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [rules, setRules] = useState<SchedulingRule[]>([]);
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
    try {
      if (!startDate || !endDate) {
        setError('Please select both start and end dates');
        return;
      }

      setSaving(true);
      setError(null);

      const ruleData = {
        start_date: startDate.toISOString().split('T')[0],
        end_date: endDate.toISOString().split('T')[0],
        is_blocked: isBlocked,
        arrival_day: arrivalDay || null,
        departure_day: departureDay || null
      };

      if (editingRule) {
        const { error: updateError } = await supabase
          .from('scheduling_rules')
          .update(ruleData)
          .eq('id', editingRule.id);

        if (updateError) throw updateError;
      } else {
        const { error: insertError } = await supabase
          .from('scheduling_rules')
          .insert([ruleData]);

        if (insertError) throw insertError;
      }

      await loadRules();
      onSave();
    } catch (err) {
      console.error('Error saving rule:', err);
      setError(err instanceof Error ? err.message : 'Failed to save rule');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-[60]">
      <div className="bg-white rounded-lg w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-stone-200 flex justify-between items-center">
          <h3 className="text-xl font-medium">
            {editingRule ? 'Edit Rule' : 'Add New Rule'}
          </h3>
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

              <div className="space-y-4">
                <div className="bg-rose-50 p-4 rounded-lg">
                  <label className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={isBlocked}
                      onChange={(e) => {
                        setIsBlocked(e.target.checked);
                        if (e.target.checked) {
                          setArrivalDay(undefined);
                          setDepartureDay(undefined);
                        }
                      }}
                      className="rounded border-rose-300 text-rose-600 focus:ring-rose-600"
                    />
                    <span className="text-sm font-medium text-rose-900">Block all dates in this range</span>
                  </label>
                </div>

                {!isBlocked && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-stone-700 mb-1">
                        Arrival Day
                      </label>
                      <select
                        value={arrivalDay || ''}
                        onChange={(e) => setArrivalDay(e.target.value || undefined)}
                        className="w-full p-2 border rounded-lg"
                      >
                        <option value="">Default</option>
                        {DAYS_OF_WEEK.map((day) => (
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
                        value={departureDay || ''}
                        onChange={(e) => setDepartureDay(e.target.value || undefined)}
                        className="w-full p-2 border rounded-lg"
                      >
                        <option value="">Default</option>
                        {DAYS_OF_WEEK.map((day) => (
                          <option key={day} value={day}>
                            {day.charAt(0).toUpperCase() + day.slice(1)}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                )}
              </div>

              {error && (
                <div className="p-4 bg-rose-50 text-rose-600 rounded-lg text-sm">
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
                  disabled={saving || !startDate || !endDate}
                  className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300"
                >
                  {saving ? 'Saving...' : editingRule ? 'Update' : 'Add Rule'}
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