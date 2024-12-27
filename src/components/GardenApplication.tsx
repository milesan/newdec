import React, { useState } from 'react';
import { AsciiIntro } from './AsciiIntro';
import { RetroApplicationForm } from './garden/RetroApplicationForm';
import type { ApplicationQuestion } from '../types/application';
import { motion } from 'framer-motion';

interface Props {
  questions: ApplicationQuestion[];
  onSubmit: (data: any) => void;
}

export function GardenApplication({ questions, onSubmit }: Props) {
  const [showForm, setShowForm] = useState(false);

  return (
    <div className="fixed inset-0 bg-garden-dark overflow-hidden">
      <motion.div
        className="absolute inset-0"
        animate={{
          y: showForm ? '-100%' : '0%'
        }}
        transition={{
          duration: 0.4,
          ease: [0.8, 0.2, 0.2, 0.8]
        }}
      >
        <AsciiIntro onComplete={() => setShowForm(true)} />
      </motion.div>

      <motion.div
        className="absolute inset-0"
        initial={{ y: '100%' }}
        animate={{
          y: showForm ? '0%' : '100%'
        }}
        transition={{
          duration: 0.4,
          ease: [0.8, 0.2, 0.2, 0.8]
        }}
      >
        <RetroApplicationForm questions={questions} onSubmit={onSubmit} />
      </motion.div>
    </div>
  );
}