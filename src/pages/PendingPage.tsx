import React from 'react';
import { Sprout } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { motion } from 'framer-motion';

interface Props {
  status?: 'pending' | 'rejected';
}

export function PendingPage({ status = 'pending' }: Props) {
  return (
    <div className="min-h-screen bg-stone-50 flex items-center justify-center p-4">
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-md w-full bg-white rounded-2xl shadow-sm border border-stone-200 p-8"
      >
        <div className="flex flex-col items-center text-center space-y-6">
          <Sprout className="w-12 h-12 text-emerald-900" />
          
          <h1 className="text-3xl font-display font-light text-stone-900">
            {status === 'pending' ? 'Application Pending' : 'Application Not Accepted'}
          </h1>

          <p className="text-stone-600 leading-relaxed">
            {status === 'pending' ? (
              "Thank you for applying to The Garden. Your application is currently being reviewed. We'll notify you by email once a decision has been made."
            ) : (
              'Unfortunately, your application was not accepted at this time. We appreciate your interest in The Garden and wish you the best in your journey.'
            )}
          </p>

          <button
            onClick={() => supabase.auth.signOut()}
            className="w-full bg-emerald-900 text-white py-3 px-6 rounded-lg hover:bg-emerald-800 transition-colors"
          >
            Sign Out
          </button>
        </div>
      </motion.div>
    </div>
  );
}