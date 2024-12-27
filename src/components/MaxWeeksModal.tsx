import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';

interface Props {
  isOpen: boolean;
  onClose: () => void;
}

export function MaxWeeksModal({ isOpen, onClose }: Props) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
        >
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.95, opacity: 0 }}
            className="bg-white rounded-lg max-w-md w-full p-6"
          >
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-xl font-serif">Hold Your Horses!</h3>
              <button 
                onClick={onClose}
                className="text-stone-400 hover:text-stone-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <p className="text-stone-600 mb-6">
              You may only spend 3 months at the Garden every 6 months. Give the rest of the world a chance ❧
            </p>
            <button
              onClick={onClose}
              className="w-full bg-emerald-900 text-white py-2 transition-colors hover:bg-emerald-800"
            >
              Cool
            </button>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}