import React from 'react';
import { motion } from 'framer-motion';
import { useTheme } from '../contexts/ThemeContext';
import { Palette } from 'lucide-react';

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();

  return (
    <motion.button
      onClick={toggleTheme}
      className={`fixed top-4 right-4 z-50 p-2 transition-colors ${
        theme === 'matrix' 
          ? 'bg-garden-matrix/20 text-garden-matrix hover:bg-garden-matrix/30' 
          : 'bg-garden-gold/20 text-garden-gold hover:bg-garden-gold/30'
      }`}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      style={{
        clipPath: `polygon(
          0 4px, 4px 4px, 4px 0,
          calc(100% - 4px) 0, calc(100% - 4px) 4px, 100% 4px,
          100% calc(100% - 4px), calc(100% - 4px) calc(100% - 4px),
          calc(100% - 4px) 100%, 4px 100%, 4px calc(100% - 4px),
          0 calc(100% - 4px)
        )`
      }}
    >
      <Palette className="w-6 h-6" />
    </motion.button>
  );
}