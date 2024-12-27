import React from 'react';
import { motion } from 'framer-motion';
import clsx from 'clsx';

interface Props {
  name: string;
  rate: number;
  imageUrl: string;
  isSelected: boolean;
  onSelect: () => void;
}

export function CabinCard({
  name,
  rate,
  imageUrl,
  isSelected,
  onSelect
}: Props) {
  return (
    <motion.button
      onClick={onSelect}
      className={clsx(
        'relative overflow-hidden pixel-corners transition-all duration-300',
        isSelected ? 'border-emerald-600 shadow-lg' : 'border-stone-200'
      )}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="aspect-[4/3] relative">
        <img
          src={imageUrl}
          alt={name}
          className="absolute inset-0 w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
      </div>
      <div className="p-4 bg-white">
        <h3 className="text-xl font-display">{name}</h3>
        <p className="text-stone-600">€{rate} per week</p>
      </div>
    </motion.button>
  );
}