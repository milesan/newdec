import React from 'react';
import { X } from 'lucide-react';
import { motion } from 'framer-motion';

interface ApplicationDetailsProps {
  application: any;
  onClose: () => void;
}

export function ApplicationDetails({ application, onClose }: ApplicationDetailsProps) {
  const questions = [
    { id: 1, text: 'Consent to data storage', section: 'Consent' },
    { id: 2, text: 'First Name', section: 'Personal' },
    { id: 3, text: 'Last Name', section: 'Personal' },
    { id: 4, text: "Where aren't you from?", section: 'Personal' },
    { id: 5, text: 'Email address', section: 'Personal' },
    { id: 6, text: 'Referral', section: 'Personal' },
    { id: 7, text: 'Muse or artisan?', section: 'Stay Details' },
    { id: 8, text: 'Applying with someone else?', section: 'Stay Details' },
    { id: 9, text: 'WhatsApp number', section: 'Contact' },
    { id: 10, text: 'Social media presence', section: 'Personal' },
    { id: 11, text: 'Current life status', section: 'Personal' },
    { id: 12, text: 'Why The Garden?', section: 'Motivation' },
    { id: 13, text: 'Photos', section: 'Personal' },
    { id: 14, text: 'Proud creation', section: 'Personal' },
    { id: 15, text: 'Hurt feelings', section: 'Philosophy' },
    { id: 16, text: 'Changed belief', section: 'Philosophy' },
    { id: 17, text: 'If we really knew you', section: 'Personal' },
    { id: 18, text: 'Working on', section: 'Personal' },
    { id: 19, text: 'Getting to know people', section: 'Social' },
    { id: 20, text: 'Questions for strangers', section: 'Social' },
    { id: 21, text: 'Identity', section: 'Philosophy' },
    { id: 22, text: 'Taboo topics', section: 'Philosophy' },
    { id: 23, text: 'Conspiracy theory', section: 'Philosophy' },
    { id: 24, text: 'Unique belief', section: 'Philosophy' },
    { id: 25, text: 'Astrology', section: 'Philosophy' },
    { id: 26, text: 'Logic puzzle', section: 'Philosophy' },
    { id: 27, text: 'MBTI type', section: 'Personal' }
  ];

  const sections = Array.from(new Set(questions.map(q => q.section)));

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col"
      >
        <div className="p-6 border-b border-stone-200 flex justify-between items-center sticky top-0 bg-white z-10">
          <div>
            <h2 className="text-xl font-medium">
              {application.data?.[4]} {application.data?.[5]}
            </h2>
            <p className="text-sm text-stone-600">{application.user_email}</p>
          </div>
          <button 
            onClick={onClose} 
            className="text-stone-400 hover:text-stone-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="overflow-y-auto p-6">
          {sections.map((section) => (
            <div key={section} className="mb-8">
              <h3 className="text-lg font-medium text-stone-900 mb-4">{section}</h3>
              <div className="space-y-6">
                {questions
                  .filter(q => q.section === section)
                  .map((question) => (
                    <div key={question.id} className="bg-stone-50 p-4 rounded-lg">
                      <h4 className="text-sm font-medium text-stone-900 mb-2">
                        {question.text}
                      </h4>
                      <div className="text-stone-600 whitespace-pre-wrap">
                        {application.data?.[question.id]?.selection || 
                         application.data?.[question.id] || 
                         'No response'}
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}