import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type { DayRule, DayRuleType } from '../types/scheduling';

export function useDayRules() {
  const [rules, setRules] = useState<DayRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadRules();

    const subscription = supabase
      .channel('day_rules_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'day_rules' 
        }, 
        () => {
          loadRules();
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadRules = async () => {
    try {
      setLoading(true);
      const { data, error: queryError } = await supabase
        .from('day_rules')
        .select('*')
        .order('date', { ascending: true });

      if (queryError) throw queryError;
      setRules(data || []);
    } catch (err) {
      console.error('Error loading day rules:', err);
      setError(err instanceof Error ? err : new Error('Failed to load day rules'));
    } finally {
      setLoading(false);
    }
  };

  const setDayRule = async (date: Date, type: DayRuleType) => {
    const dateStr = date.toISOString().split('T')[0];
    
    try {
      if (type === null) {
        // Delete the rule
        const { error } = await supabase
          .from('day_rules')
          .delete()
          .eq('date', dateStr);
        
        if (error) throw error;
      } else {
        // Upsert the rule
        const { error } = await supabase
          .from('day_rules')
          .upsert({
            date: dateStr,
            is_arrival: type === 'arrival',
            is_departure: type === 'departure',
            not_arrival: type === 'not_arrival',
            not_departure: type === 'not_departure'
          }, {
            onConflict: 'date'
          });

        if (error) throw error;
      }

      await loadRules();
    } catch (err) {
      console.error('Error setting day rule:', err);
      throw err;
    }
  };

  const getDayRule = (date: Date): { 
    isArrival: boolean; 
    isDeparture: boolean;
    notArrival: boolean;
    notDeparture: boolean;
  } => {
    const dateStr = date.toISOString().split('T')[0];
    const rule = rules.find(r => r.date === dateStr);
    
    return {
      isArrival: rule?.is_arrival || false,
      isDeparture: rule?.is_departure || false,
      notArrival: rule?.not_arrival || false,
      notDeparture: rule?.not_departure || false
    };
  };

  return {
    rules,
    loading,
    error,
    setDayRule,
    getDayRule,
    refresh: loadRules
  };
}