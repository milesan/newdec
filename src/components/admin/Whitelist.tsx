import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Plus, Trash2, Upload, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface WhitelistEntry {
  id: string;
  email: string;
  notes: string;
  created_at: string;
  last_login: string | null;
  has_seen_welcome: boolean;
  has_created_account: boolean;
  account_created_at: string | null;
}

export function Whitelist() {
  const [entries, setEntries] = useState<WhitelistEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newEmail, setNewEmail] = useState('');
  const [newNotes, setNewNotes] = useState('');
  const [showUpload, setShowUpload] = useState(false);

  useEffect(() => {
    loadWhitelist();

    const subscription = supabase
      .channel('whitelist_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'whitelist' 
        }, 
        () => {
          loadWhitelist();
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const loadWhitelist = async () => {
    try {
      setLoading(true);
      const { data, error: queryError } = await supabase
        .from('whitelist')
        .select('*')
        .order('created_at', { ascending: false });

      if (queryError) throw queryError;
      setEntries(data || []);
    } catch (err) {
      console.error('Error loading whitelist:', err);
      setError(err instanceof Error ? err.message : 'Failed to load whitelist');
    } finally {
      setLoading(false);
    }
  };

  const addToWhitelist = async () => {
    if (!newEmail) return;

    try {
      const { error } = await supabase
        .from('whitelist')
        .insert({ email: newEmail, notes: newNotes });

      if (error) throw error;
      
      setNewEmail('');
      setNewNotes('');
      await loadWhitelist();
    } catch (err) {
      console.error('Error adding to whitelist:', err);
      setError(err instanceof Error ? err.message : 'Failed to add to whitelist');
    }
  };

  const removeFromWhitelist = async (id: string) => {
    try {
      const { error } = await supabase
        .from('whitelist')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await loadWhitelist();
    } catch (err) {
      console.error('Error removing from whitelist:', err);
      setError(err instanceof Error ? err.message : 'Failed to remove from whitelist');
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      const text = await file.text();
      const emails = text.split('\n')
        .map(line => line.trim())
        .filter(email => email && email.includes('@'));

      const { error } = await supabase
        .from('whitelist')
        .insert(
          emails.map(email => ({
            email,
            notes: 'Added via CSV upload'
          }))
        );

      if (error) throw error;
      
      setShowUpload(false);
      await loadWhitelist();
    } catch (err) {
      console.error('Error uploading CSV:', err);
      setError(err instanceof Error ? err.message : 'Failed to upload CSV');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center p-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {error && (
        <div className="mb-6 p-4 bg-rose-50 text-rose-600 rounded-lg">
          {error}
        </div>
      )}

      <div className="bg-white p-6 rounded-lg border border-stone-200 mb-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium">Add to Whitelist</h3>
          <button
            onClick={() => setShowUpload(true)}
            className="flex items-center gap-2 text-emerald-600 hover:text-emerald-700"
          >
            <Upload className="w-4 h-4" />
            Upload CSV
          </button>
        </div>

        <div className="flex gap-4">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="Email address"
            className="flex-1 p-2 border border-stone-200 rounded-lg focus:ring-2 focus:ring-emerald-900 focus:border-emerald-900"
          />
          <input
            type="text"
            value={newNotes}
            onChange={(e) => setNewNotes(e.target.value)}
            placeholder="Notes (optional)"
            className="flex-1 p-2 border border-stone-200 rounded-lg focus:ring-2 focus:ring-emerald-900 focus:border-emerald-900"
          />
          <button
            onClick={addToWhitelist}
            className="flex items-center gap-2 bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add
          </button>
        </div>
      </div>

      <div className="space-y-4">
        {entries.map((entry) => (
          <motion.div
            key={entry.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="bg-white p-4 rounded-lg border border-stone-200 flex justify-between items-center"
          >
            <div>
              <div className="font-medium">{entry.email}</div>
              {entry.notes && (
                <div className="text-sm text-stone-600 mt-1">{entry.notes}</div>
              )}
              <div className="flex gap-4 mt-2">
                {entry.has_created_account ? (
                  <span className="text-sm text-emerald-600">Has Account</span>
                ) : (
                  <span className="text-sm text-stone-500">No Account Yet</span>
                )}
                {entry.has_seen_welcome && (
                  <span className="text-sm text-emerald-600">Has Seen Welcome</span>
                )}
                {entry.last_login && (
                  <span className="text-sm text-stone-500">
                    Last login: {new Date(entry.last_login).toLocaleString()}
                  </span>
                )}
              </div>
            </div>
            <button
              onClick={() => removeFromWhitelist(entry.id)}
              className="p-2 text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </motion.div>
        ))}
      </div>

      <AnimatePresence>
        {showUpload && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
          >
            <motion.div
              initial={{ scale: 0.95 }}
              animate={{ scale: 1 }}
              exit={{ scale: 0.95 }}
              className="bg-white rounded-lg max-w-md w-full p-6"
            >
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-medium">Upload CSV</h3>
                <button
                  onClick={() => setShowUpload(false)}
                  className="text-stone-400 hover:text-stone-600"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
              <p className="text-stone-600 mb-4">
                Upload a CSV file containing one email address per line.
              </p>
              <input
                type="file"
                accept=".csv,text/csv"
                onChange={handleFileUpload}
                className="w-full"
              />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}