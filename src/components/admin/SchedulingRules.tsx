import React, { useState } from 'react';
import { X, Plus, Calendar, Trash2, Edit2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { format, parseISO } from 'date-fns';
import type { SchedulingRule } from '../../types/scheduling';
import { AddRuleForm } from './AddRuleForm';

interface Props {
  onClose: () => void;
}

export function SchedulingRules({ onClose }: Props) {
  const [rules, setRules] = useState<SchedulingRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingRule, setEditingRule] = useState<SchedulingRule | null>(null);

  React.useEffect(() => {
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

  const deleteRule = async (id: string) => {
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

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-stone-200 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <Calendar className="w-6 h-6 text-emerald-900" />
            <h2 className="text-2xl font-display font-light">Scheduling Rules</h2>
          </div>
          <button onClick={onClose} className="text-stone-400 hover:text-stone-600">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="p-6 overflow-y-auto">
          {error && (
            <div className="mb-6 p-4 bg-rose-50 text-rose-600 rounded-lg">
              {error}
            </div>
          )}

          <div className="flex justify-end mb-6">
            <button
              onClick={() => {
                setEditingRule(null);
                setShowAddForm(true);
              }}
              className="flex items-center gap-2 bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800"
            >
              <Plus className="w-4 h-4" />
              Add New Rule
            </button>
          </div>

          {loading ? (
            <div className="flex justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
            </div>
          ) : (
            <div className="space-y-4">
              {rules.map((rule) => (
                <div
                  key={rule.id}
                  className="bg-white p-6 rounded-lg border border-stone-200 hover:border-emerald-900/20 transition-colors"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="flex items-center gap-4 mb-2">
                        <h3 className="font-medium">
                          {format(parseISO(rule.start_date), 'PP')} - {format(parseISO(rule.end_date), 'PP')}
                        </h3>
                        {rule.is_blocked && (
                          <span className="px-2 py-1 bg-rose-100 text-rose-800 rounded-full text-xs font-medium">
                            Blocked
                          </span>
                        )}
                      </div>

                      {(rule.arrival_day || rule.departure_day) && (
                        <p className="text-stone-600">
                          {rule.arrival_day && (
                            <span>
                              Arrival: {rule.arrival_day.charAt(0).toUpperCase() + rule.arrival_day.slice(1)}
                            </span>
                          )}
                          {rule.arrival_day && rule.departure_day && ' • '}
                          {rule.departure_day && (
                            <span>
                              Departure: {rule.departure_day.charAt(0).toUpperCase() + rule.departure_day.slice(1)}
                            </span>
                          )}
                        </p>
                      )}

                      {rule.blocked_dates?.length > 0 && (
                        <p className="text-stone-600 mt-2">
                          Blocked dates: {rule.blocked_dates.map(date => format(parseISO(date), 'PP')).join(', ')}
                        </p>
                      )}
                    </div>

                    <div className="flex gap-2">
                      <button
                        onClick={() => {
                          setEditingRule(rule);
                          setShowAddForm(true);
                        }}
                        className="text-stone-400 hover:text-emerald-600 transition-colors"
                      >
                        <Edit2 className="w-5 h-5" />
                      </button>
                      <button
                        onClick={() => deleteRule(rule.id)}
                        className="text-stone-400 hover:text-rose-600 transition-colors"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {showAddForm && (
          <AddRuleForm
            onClose={() => {
              setShowAddForm(false);
              setEditingRule(null);
            }}
            onSave={loadRules}
            editingRule={editingRule}
          />
        )}
      </div>
    </div>
  );
}