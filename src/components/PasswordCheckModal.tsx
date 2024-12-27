import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export function PasswordCheckModal({ isOpen, onClose, onSuccess }: Props) {
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      checkWhitelistStatus();
    }
  }, [isOpen]);

  const checkWhitelistStatus = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user?.email) return;

      // Call RPC function to check whitelist status
      const { data, error } = await supabase.rpc('check_whitelist_status', {
        p_email: user.email
      });

      if (error) throw error;

      if (data?.is_whitelisted) {
        // Refresh session to get updated metadata
        await supabase.auth.refreshSession();
        onSuccess();
      } else {
        // Auto-click "No" after 20ms
        setTimeout(() => {
          onClose();
        }, 20);
      }
    } catch (err) {
      console.error('Error checking whitelist:', err);
      // Auto-click "No" after 20ms if there's an error
      setTimeout(() => {
        onClose();
      }, 20);
    }
  };

  // Return an empty div with opacity 0 to make it invisible
  return <div style={{ opacity: 0 }} />;
}