import { useState, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export function useAutosave() {
  const [showSaveNotification, setShowSaveNotification] = useState(false);
  const [lastSavedData, setLastSavedData] = useState<any>(null);
  const [initialDataLoaded, setInitialDataLoaded] = useState(false);

  const loadSavedData = useCallback(async () => {
    if (initialDataLoaded) return null;

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from('saved_applications')
        .select('data')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;
      
      setInitialDataLoaded(true);
      setLastSavedData(data?.data || null);
      return data?.data || null;
    } catch (err) {
      console.error('Error loading saved data:', err);
      return null;
    }
  }, [initialDataLoaded]);

  const saveData = useCallback(async (data: any) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Only save if data has changed
      if (JSON.stringify(data) === JSON.stringify(lastSavedData)) {
        return;
      }

      const { error } = await supabase
        .from('saved_applications')
        .upsert({
          user_id: user.id,
          data,
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'user_id'
        });

      if (error) throw error;

      setLastSavedData(data);
      setShowSaveNotification(true);
    } catch (err) {
      console.error('Error saving data:', err);
    }
  }, [lastSavedData]);

  return {
    saveData,
    loadSavedData,
    showSaveNotification,
    setShowSaveNotification
  };
}