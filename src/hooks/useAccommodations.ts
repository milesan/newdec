import { useEffect, useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import type { Accommodation } from '../types';

export function useAccommodations() {
  const [accommodations, setAccommodations] = useState<Accommodation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const loadAccommodations = useCallback(async () => {
    try {
      setError(null);
      const { data, error: queryError } = await supabase
        .from('accommodations')
        .select(`
          *,
          parent:parent_accommodation_id (
            id,
            title,
            inventory_count,
            is_unlimited,
            is_fungible
          )
        `)
        .is('parent_accommodation_id', null)
        .order('price', { ascending: true });

      if (queryError) throw queryError;
      setAccommodations(data || []);
    } catch (e) {
      console.error('Error loading accommodations:', e);
      setError(e instanceof Error ? e : new Error('Failed to load accommodations'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAccommodations();

    const subscription = supabase
      .channel('accommodations_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'accommodations' 
        }, 
        () => {
          loadAccommodations();
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [loadAccommodations]);

  return { 
    accommodations, 
    loading, 
    error,
    refresh: loadAccommodations
  };
}