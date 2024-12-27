import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface ArrivalRules {
  id: string;
  arrival_day: string;
  departure_day: string;
}

export function useArrivalRules() {
  const [rules, setRules] = useState<ArrivalRules>({
    id: '',
    arrival_day: 'wednesday',
    departure_day: 'tuesday'
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadRules();

    const subscription = supabase
      .channel('arrival_rules_changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'arrival_rules' }, () => {
        loadRules();
      })
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  async function loadRules() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('arrival_rules')
        .select('*')
        .order('updated_at', { ascending: false })
        .limit(1)
        .single();

      if (error) {
        console.error('Error loading arrival rules:', error);
        return;
      }

      if (data) {
        setRules(data);
      }
    } catch (err) {
      console.error('Error loading arrival rules:', err);
    } finally {
      setLoading(false);
    }
  }

  return { rules, loading };
}