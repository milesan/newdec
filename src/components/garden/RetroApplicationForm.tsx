import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { RetroQuestionField } from './RetroQuestionField';
import { Send, ChevronRight, LogOut } from 'lucide-react';
import { ThemeToggle } from '../ThemeToggle';
import { useTheme } from '../../contexts/ThemeContext';
import type { ApplicationQuestion } from '../../types/application';
import { supabase } from '../../lib/supabase';

interface Props {
  questions: ApplicationQuestion[];
  onSubmit: (data: any) => void;
}

export function RetroApplicationForm({ questions, onSubmit }: Props) {
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentSection, setCurrentSection] = useState(0);
  const { theme } = useTheme();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSubmit(formData);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (questionId: number, value: any) => {
    setFormData(prev => ({
      ...prev,
      [questionId]: value
    }));
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  const handleAutoAdvance = () => {
    setCurrentSection(prev => Math.min(sectionNames.length - 1, prev + 1));
  };

  const sections = questions.reduce((acc, question) => {
    const section = question.section || 'Other';
    if (!acc[section]) {
      acc[section] = [];
    }
    acc[section].push(question);
    return acc;
  }, {} as Record<string, ApplicationQuestion[]>);

  const sectionNames = Object.keys(sections);
  const currentSectionName = sectionNames[currentSection];
  const currentQuestions = sections[currentSectionName] || [];
  
  const progress = ((currentSection + 1) / sectionNames.length) * 100;

  return (
    <div className="min-h-screen bg-garden-dark text-garden-gold font-mono p-4 md:p-8">
      <ThemeToggle />
      <div className="max-w-2xl mx-auto">
        <motion.div 
          className="flex flex-col md:flex-row items-center justify-between mb-8 md:mb-16 space-y-4 md:space-y-0"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex items-center gap-4">
            <div className="relative">
              <img 
                src="https://raw.githubusercontent.com/milesan/synesthesia/refs/heads/main/Enso%20Zen%20Soto%20Symbol.png"
                alt="Logo"
                className="w-12 h-12 md:w-16 md:h-16"
                style={{ filter: 'invert(1) sepia(1) saturate(10000%) hue-rotate(330deg)' }}
              />
            </div>
            <div>
              <h1 className="text-3xl md:text-5xl font-display mb-2">The Garden</h1>
              <div className="relative">
                <div className={`w-full bg-garden-${theme}/20 h-1`}>
                  <motion.div 
                    className={`h-full bg-garden-${theme}`}
                    initial={{ width: 0 }}
                    animate={{ width: `${progress}%` }}
                    transition={{ duration: 0.3 }}
                  />
                </div>
              </div>
            </div>
          </div>
          
          <button
            onClick={handleLogout}
            className={`group flex items-center gap-2 px-4 py-2 text-garden-${theme} hover:text-garden-${theme} transition-colors pixel-corners relative`}
          >
            <LogOut className="w-4 h-4" />
            <span>Sign Out</span>
            <pre className={`absolute -bottom-4 left-0 text-[8px] text-garden-${theme}/40 group-hover:text-garden-${theme}/60 transition-colors`}>
              └──┘
            </pre>
          </button>
        </motion.div>

        {/* Rest of the component remains the same */}
      </div>
    </div>
  );
}