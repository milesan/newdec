import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export function useCredits() {
  const [credits, setCredits] = useState<number>(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadCredits();

    // Subscribe to changes
    const channel = supabase
      .channel('profile_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'profiles',
          filter: `id=eq.${supabase.auth.getUser().then(({ data }) => data.user?.id)}`
        }, 
        () => {
          loadCredits();
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, []);

  const loadCredits = async () => {
    try {
      setLoading(true);
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setCredits(0);
        return;
      }

      const { data, error } = await supabase
        .from('profiles')
        .select('credits')
        .eq('id', user.id)
        .single();

      if (error) throw error;
      setCredits(data?.credits || 0);
    } catch (err) {
      console.error('Error loading credits:', err);
      setError(err instanceof Error ? err : new Error('Failed to load credits'));
    } finally {
      setLoading(false);
    }
  };

  return { credits, loading, error, refresh: loadCredits };
}