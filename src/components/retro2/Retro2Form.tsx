import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { RetroQuestionField } from './RetroQuestionField';
import { Sprout, Send, ChevronRight, LogOut, Terminal } from 'lucide-react';
import { AutosaveNotification } from '../AutosaveNotification';
import { useAutosave } from '../../hooks/useAutosave';
import type { ApplicationQuestion } from '../../types/application';
import { supabase } from '../../lib/supabase';
import { useNavigate } from 'react-router-dom';

interface Props {
  questions: ApplicationQuestion[];
  onSubmit: (data: any) => void;
}

export function Retro2Form({ questions, onSubmit }: Props) {
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [currentSection, setCurrentSection] = useState(0);
  const navigate = useNavigate();
  const contentRef = useRef<HTMLDivElement>(null);
  const { saveData, loadSavedData, showSaveNotification, setShowSaveNotification } = useAutosave();

  // Load saved data and check consent status
  useEffect(() => {
    const initializeForm = async () => {
      const savedData = await loadSavedData();
      if (savedData) {
        setFormData(savedData);
        // If user has already consented, skip to next section
        if (savedData[3] === 'As you wish.') {
          setCurrentSection(1);
        }
      }
    };
    initializeForm();
  }, [loadSavedData]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await onSubmit(formData);
      // Clear saved data after successful submission
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase
          .from('saved_applications')
          .delete()
          .eq('user_id', user.id);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (questionId: number, value: any) => {
    const newFormData = {
      ...formData,
      [questionId]: value
    };
    setFormData(newFormData);

    // If this is the consent question and user consents, auto-advance
    if (questionId === 3 && value === 'As you wish.') {
      setTimeout(() => {
        setCurrentSection(1);
      }, 500);
    }
  };

  const handleBlur = () => {
    saveData(formData);
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/');
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

  const isCurrentSectionComplete = () => {
    return currentQuestions.every(question => {
      if (!question.required) return true;
      const value = formData[question.order_number];
      return value !== undefined && value !== '' && value !== null;
    });
  };

  const progress = ((currentSection + 1) / sectionNames.length) * 100;

  useEffect(() => {
    if (contentRef.current) {
      contentRef.current.scrollTop = 0;
    }
  }, [currentSection]);

  return (
    <div className="min-h-screen bg-black text-[#FFBF00] font-mono">
      <div className="fixed top-0 left-0 right-0 z-50 bg-black border-b border-[#FFBF00]/20">
        <div className="max-w-2xl mx-auto px-4">
          <div className="flex items-center justify-between py-4">
            <div className="flex items-center gap-3">
              <Sprout className="w-6 h-6" />
              <h1 className="text-xl font-display">The Garden</h1>
            </div>
            <button
              onClick={handleLogout}
              className="flex items-center gap-2 px-4 py-2 text-sm bg-[#FFBF00]/10 hover:bg-[#FFBF00]/20 transition-colors rounded"
            >
              <LogOut className="w-4 h-4" />
              <span>Sign Out</span>
            </button>
          </div>

          <div className="flex gap-6 py-2 overflow-x-auto scrollbar-none">
            {sectionNames.map((name, index) => (
              <button
                key={name}
                disabled={index > currentSection && !isCurrentSectionComplete()}
                onClick={() => index <= currentSection && setCurrentSection(index)}
                className={`text-sm whitespace-nowrap transition-all ${
                  index === currentSection
                    ? `text-[#FFBF00]`
                    : index < currentSection
                    ? `text-[#FFBF00]/60 hover:text-[#FFBF00]/80`
                    : `text-[#FFBF00]/30`
                }`}
              >
                {name}
              </button>
            ))}
          </div>

          <div className="h-0.5 bg-[#FFBF00]/10">
            <motion.div
              className="h-full bg-[#FFBF00]"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.3 }}
            />
          </div>
        </div>
      </div>

      <div 
        ref={contentRef}
        className="fixed top-[140px] bottom-[80px] left-0 right-0 overflow-y-auto"
      >
        <div className="max-w-2xl mx-auto px-4">
          <motion.div
            key={currentSectionName}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.2 }}
            className="space-y-12 pb-12"
          >
            {currentQuestions.map((question) => (
              <div 
                key={question.order_number}
                data-question={question.order_number}
                className="space-y-4 relative"
              >
                <RetroQuestionField
                  question={question}
                  value={formData[question.order_number]}
                  onChange={(value) => handleChange(question.order_number, value)}
                  onBlur={handleBlur}
                />
                <div className="section-divider relative" />
              </div>
            ))}
          </motion.div>
        </div>
      </div>

      <div className="fixed bottom-4 right-4 left-4 flex justify-between items-center max-w-2xl mx-auto">
        {currentSection > 0 && (
          <button
            type="button"
            onClick={() => setCurrentSection(prev => Math.max(0, prev - 1))}
            className="group px-4 py-2 text-base transition-all bg-[#FFBF00]/10 hover:bg-[#FFBF00]/20 text-[#FFBF00]"
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
            Previous
          </button>
        )}

        {currentSection === sectionNames.length - 1 ? (
          <button
            type="submit"
            disabled={isSubmitting || !isCurrentSectionComplete()}
            onClick={handleSubmit}
            className={`group flex items-center gap-2 bg-[#FFBF00] text-black px-6 py-3 text-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed mx-auto`}
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
            {isSubmitting ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-2 border-black border-t-transparent" />
                Processing...
              </>
            ) : (
              <>
                <Send className="w-5 h-5" />
                Submit
              </>
            )}
          </button>
        ) : currentSection === 0 ? null : (
          <button
            type="button"
            onClick={() => isCurrentSectionComplete() && setCurrentSection(prev => prev + 1)}
            disabled={!isCurrentSectionComplete()}
            className={`group flex items-center gap-2 px-4 py-2 text-base transition-all ${
              isCurrentSectionComplete() 
                ? 'bg-[#FFBF00] text-black' 
                : 'bg-[#FFBF00]/10 text-[#FFBF00]'
            } disabled:opacity-50 disabled:cursor-not-allowed`}
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
            <span>Next</span>
            <ChevronRight className="w-4 h-4" />
          </button>
        )}
      </div>

      <div className="fixed bottom-4 left-4 text-[#FFBF00]/20">
        <Terminal className="w-5 h-5" />
      </div>

      <AutosaveNotification 
        show={showSaveNotification} 
        onClose={() => setShowSaveNotification(false)} 
      />
    </div>
  );
}