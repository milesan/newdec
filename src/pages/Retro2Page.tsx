import React, { useState } from 'react';
import { Terminal } from 'lucide-react';
import { motion } from 'framer-motion';
import { supabase } from '../lib/supabase';
import { Retro2Form } from '../components/retro2/Retro2Form';
import { Retro2Intro } from '../components/retro2/Retro2Intro';

export function Retro2Page() {
  const [showForm, setShowForm] = useState(false);
  const [questions, setQuestions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  React.useEffect(() => {
    loadQuestions();
  }, []);

  const loadQuestions = async () => {
    try {
      setLoading(true);
      const { data, error: queryError } = await supabase
        .from('application_questions')
        .select('*')
        .order('order_number');

      if (queryError) throw queryError;
      setQuestions(data || []);
    } catch (err) {
      console.error('Error loading questions:', err);
      setError(err instanceof Error ? err.message : 'Failed to load questions');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (data: any) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Check if this is a linked application
      const isLinkedApplication = data[9]?.answer === "Yes";
      const linkedName = isLinkedApplication ? data[9].partnerName : null;
      const linkedEmail = isLinkedApplication ? data[9].partnerEmail : null;

      // Submit the application
      const { data: application, error: applicationError } = await supabase
        .from('applications')
        .insert({
          user_id: user.id,
          data: data,
          status: 'pending'
        })
        .select()
        .single();

      if (applicationError) throw applicationError;

      // If there's a linked application, create the link
      if (isLinkedApplication && linkedName && linkedEmail && application) {
        const { error: linkError } = await supabase
          .from('linked_applications')
          .insert({
            primary_application_id: application.id,
            linked_name: linkedName,
            linked_email: linkedEmail
          });

        if (linkError) throw linkError;
      }

      // Update user metadata
      const { error: updateError } = await supabase.auth.updateUser({
        data: { 
          has_applied: true,
          application_status: 'pending'
        }
      });

      if (updateError) throw updateError;

      // Refresh the session to reflect the changes
      await supabase.auth.refreshSession();

    } catch (error) {
      console.error('Error submitting application:', error);
      throw error;
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#FFBF00]"></div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black overflow-hidden">
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
        <Retro2Intro onComplete={() => setShowForm(true)} />
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
        <Retro2Form questions={questions} onSubmit={handleSubmit} />
      </motion.div>
    </div>
  );
}