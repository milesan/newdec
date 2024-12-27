import React, { useState, useEffect } from 'react';
import { RetroApplicationForm } from '../components/garden/RetroApplicationForm';
import { AsciiIntro } from '../components/AsciiIntro';
import { Sprout, Wand2 } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { motion } from 'framer-motion';

export function ApplyPage() {
  const [questions, setQuestions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAscii, setShowAscii] = useState(true);

  useEffect(() => {
    loadQuestions();
  }, []);

  const loadQuestions = async () => {
    try {
      const { data, error } = await supabase
        .from('application_questions')
        .select('*')
        .order('order_number');

      if (error) throw error;
      setQuestions(data || []);
    } catch (err) {
      console.error('Error loading questions:', err);
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
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-garden-gold"></div>
      </div>
    );
  }

  if (showAscii) {
    return <AsciiIntro onComplete={() => setShowAscii(false)} />;
  }

  return (
    <RetroApplicationForm questions={questions} onSubmit={handleSubmit} />
  );
}