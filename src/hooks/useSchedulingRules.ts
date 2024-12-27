import { useState, useEffect } from 'react';
import { isWithinInterval, parseISO, format } from 'date-fns';
import { supabase } from '../lib/supabase';
import type { SchedulingRule } from '../types/scheduling';

export function useSchedulingRules() {
  const [rules, setRules] = useState<SchedulingRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadRules();

    const subscription = supabase
      .channel('scheduling_rules_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'scheduling_rules' 
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
        .from('scheduling_rules')
        .select('*')
        .order('start_date', { ascending: true });

      if (queryError) throw queryError;
      setRules(data || []);
    } catch (err) {
      console.error('Error loading scheduling rules:', err);
      setError(err instanceof Error ? err : new Error('Failed to load scheduling rules'));
    } finally {
      setLoading(false);
    }
  };

  const isDateBlocked = (date: Date): boolean => {
    const rule = rules.find(rule => 
      isWithinInterval(date, {
        start: parseISO(rule.start_date),
        end: parseISO(rule.end_date)
      })
    );

    if (!rule) return false;
    if (rule.is_blocked) return true;
    if (rule.blocked_dates?.includes(format(date, 'yyyy-MM-dd'))) return true;

    return false;
  };

  const getArrivalDepartureForDate = (date: Date) => {
    const rule = rules.find(rule => 
      isWithinInterval(date, {
        start: parseISO(rule.start_date),
        end: parseISO(rule.end_date)
      })
    );

    return {
      arrival: rule?.arrival_day || 'tuesday',
      departure: rule?.departure_day || 'monday'
    };
  };

  const isWeekAvailable = (weekStart: Date): boolean => {
    // Default to true unless explicitly blocked
    return !isDateBlocked(weekStart);
  };

  return {
    rules,
    loading,
    error,
    isDateBlocked,
    getArrivalDepartureForDate,
    isWeekAvailable,
    refresh: loadRules
  };
}