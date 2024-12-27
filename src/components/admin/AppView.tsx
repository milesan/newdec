import React, { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle, XCircle, X } from 'lucide-react';

interface Application {
  id: string;
  user_id: string;
  data: Record<string, any>;
  status: string;
  created_at: string;
  user_email: string;
}

interface FullApplicationModalProps {
  application: Application;
  onClose: () => void;
}

function FullApplicationModal({ application, onClose }: FullApplicationModalProps) {
  const renderAnswer = (value: any) => {
    if (!value) return 'Not answered';
    if (typeof value === 'object') {
      if (value.answer) {
        let text = value.answer;
        if (value.role) text += `\nRole: ${value.role}`;
        if (value.partnerName) text += `\nPartner Name: ${value.partnerName}`;
        if (value.partnerEmail) text += `\nPartner Email: ${value.partnerEmail}`;
        return text;
      }
      return JSON.stringify(value, null, 2);
    }
    return String(value);
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col"
      >
        <div className="p-6 border-b border-stone-200 flex justify-between items-center sticky top-0 bg-white z-10">
          <div>
            <h2 className="text-xl font-medium">
              {application.data[4]} {application.data[5]}
            </h2>
            <p className="text-stone-600">{application.user_email}</p>
          </div>
          <button 
            onClick={onClose}
            className="text-stone-400 hover:text-stone-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="overflow-y-auto p-6">
          {Object.entries(application.data).map(([key, value]) => (
            <div key={key} className="mb-6">
              <h3 className="font-medium text-stone-900 mb-2">Question {key}</h3>
              <div className="bg-stone-50 p-4 rounded-lg">
                <p className="text-stone-600 whitespace-pre-wrap">{renderAnswer(value)}</p>
              </div>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  );
}

function AnswerTooltip({ children, content }: { children: React.ReactNode; content: any }) {
  const [showTooltip, setShowTooltip] = useState(false);

  const renderContent = (value: any) => {
    if (!value) return 'Not provided';
    if (typeof value === 'object') {
      if (value.answer) {
        let text = value.answer;
        if (value.role) text += `\nRole: ${value.role}`;
        if (value.partnerName) text += `\nPartner Name: ${value.partnerName}`;
        if (value.partnerEmail) text += `\nPartner Email: ${value.partnerEmail}`;
        return text;
      }
      return JSON.stringify(value, null, 2);
    }
    return String(value);
  };

  return (
    <div className="relative">
      <div 
        onMouseEnter={() => setShowTooltip(true)}
        onMouseLeave={() => setShowTooltip(false)}
        onClick={() => setShowTooltip(!showTooltip)}
        className="cursor-pointer"
      >
        {children}
      </div>
      {showTooltip && (
        <div className="absolute z-50 bg-black text-white p-4 rounded-lg shadow-lg max-w-md whitespace-pre-wrap">
          {renderContent(content)}
        </div>
      )}
    </div>
  );
}

export function AppView() {
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedApplication, setSelectedApplication] = useState<Application | null>(null);
  const [activeTab, setActiveTab] = useState<'pending' | 'approved' | 'rejected'>('pending');

  React.useEffect(() => {
    loadApplications();
  }, []);

  const loadApplications = async () => {
    try {
      const { data, error: queryError } = await supabase
        .from('application_details')
        .select('*')
        .order('created_at', { ascending: false });

      if (queryError) throw queryError;
      setApplications(data || []);
    } catch (err) {
      console.error('Error loading applications:', err);
      setError(err instanceof Error ? err.message : 'Failed to load applications');
    } finally {
      setLoading(false);
    }
  };

  const updateApplicationStatus = async (id: string, status: string) => {
    try {
      if (status === 'approved') {
        const { error } = await supabase.rpc('approve_application', {
          p_application_id: id
        });
        if (error) throw error;
      } else if (status === 'rejected') {
        const { error } = await supabase.rpc('reject_application', {
          p_application_id: id
        });
        if (error) throw error;
      }
      await loadApplications();
    } catch (err) {
      console.error('Error updating application:', err);
      setError(err instanceof Error ? err.message : 'Failed to update application');
    }
  };

  const renderPhotoGrid = (photos: any) => {
    if (!photos) return null;

    let photoArray: string[] = [];
    try {
      if (typeof photos === 'string') {
        const parsed = JSON.parse(photos);
        photoArray = Array.isArray(parsed) ? parsed : [];
      } else if (Array.isArray(photos)) {
        photoArray = photos;
      }
    } catch (e) {
      return null;
    }

    const validPhotos = photoArray.filter(photo => typeof photo === 'string' && photo.trim() !== '');
    if (validPhotos.length === 0) return null;

    const gridConfig = {
      1: 'grid-cols-1',
      2: 'grid-cols-2',
      3: 'grid-cols-2',
      4: 'grid-cols-2'
    };

    return (
      <div className={`grid ${gridConfig[Math.min(validPhotos.length, 4) as keyof typeof gridConfig]} gap-2 aspect-square`}>
        {validPhotos.slice(0, 4).map((photo, index) => (
          <img
            key={index}
            src={photo}
            alt={`Applicant photo ${index + 1}`}
            className={`w-full h-full object-cover rounded-lg ${
              validPhotos.length === 3 && index === 2 ? 'col-span-2' : ''
            }`}
          />
        ))}
      </div>
    );
  };

  const renderAnswer = (value: any) => {
    if (!value) return 'Not provided';
    if (typeof value === 'object') {
      if (value.answer) return value.answer;
      return JSON.stringify(value);
    }
    return String(value);
  };

  const renderApplicationCard = (application: Application) => {
    const {
      data: {
        13: photos,
        25: astrology,
        29: mbti,
        23: conspiracy,
        26: logicPuzzle,
        24: uniqueBelief,
        19: gettingToKnow,
        21: identity,
        17: reallyKnowYou
      }
    } = application;

    return (
      <motion.div
        layout
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -20 }}
        className="bg-white p-6 rounded-xl shadow-sm border border-stone-200 space-y-6"
      >
        <div className="flex justify-between items-start">
          <div>
            <button
              onClick={() => setSelectedApplication(application)}
              className="font-medium text-lg hover:text-emerald-600 transition-colors text-left group"
            >
              <span className="group-hover:underline">
                {application.data[4]} {application.data[5]}
              </span>
            </button>
            <p className="text-stone-600">{application.user_email}</p>
          </div>
          <div className="flex gap-2">
            {application.status === 'pending' && (
              <>
                <button
                  onClick={() => updateApplicationStatus(application.id, 'approved')}
                  className="p-2 rounded-lg bg-emerald-100 text-emerald-600 hover:bg-emerald-200 transition-colors"
                >
                  <CheckCircle className="w-4 h-4" />
                </button>
                <button
                  onClick={() => updateApplicationStatus(application.id, 'rejected')}
                  className="p-2 rounded-lg bg-rose-100 text-rose-600 hover:bg-rose-200 transition-colors"
                >
                  <XCircle className="w-4 h-4" />
                </button>
              </>
            )}
            <span className={`px-3 py-1 rounded-full text-xs font-medium ${
              application.status === 'pending'
                ? 'bg-yellow-100 text-yellow-800'
                : application.status === 'approved'
                ? 'bg-emerald-100 text-emerald-800'
                : 'bg-rose-100 text-rose-800'
            }`}>
              {application.status}
            </span>
          </div>
        </div>

        {renderPhotoGrid(photos)}

        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-stone-500">Astrology:</span>
            <AnswerTooltip content={astrology}>
              <p className="mt-1 line-clamp-2">{renderAnswer(astrology)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">MBTI:</span>
            <AnswerTooltip content={mbti}>
              <p className="mt-1 line-clamp-2">{renderAnswer(mbti)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">Conspiracy Theory:</span>
            <AnswerTooltip content={conspiracy}>
              <p className="mt-1 line-clamp-2">{renderAnswer(conspiracy)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">Logic Puzzle:</span>
            <AnswerTooltip content={logicPuzzle}>
              <p className="mt-1 line-clamp-2">{renderAnswer(logicPuzzle)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">Unique Belief:</span>
            <AnswerTooltip content={uniqueBelief}>
              <p className="mt-1 line-clamp-2">{renderAnswer(uniqueBelief)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">Getting to Know People:</span>
            <AnswerTooltip content={gettingToKnow}>
              <p className="mt-1 line-clamp-2">{renderAnswer(gettingToKnow)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">Identity:</span>
            <AnswerTooltip content={identity}>
              <p className="mt-1 line-clamp-2">{renderAnswer(identity)}</p>
            </AnswerTooltip>
          </div>
          <div>
            <span className="text-stone-500">If we really knew you:</span>
            <AnswerTooltip content={reallyKnowYou}>
              <p className="mt-1 line-clamp-2">{renderAnswer(reallyKnowYou)}</p>
            </AnswerTooltip>
          </div>
        </div>
      </motion.div>
    );
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center p-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6 text-rose-600 bg-rose-50 rounded-lg">
        {error}
      </div>
    );
  }

  const filteredApplications = applications.filter(app => app.status === activeTab);

  return (
    <div className="p-6">
      <div className="flex gap-4 mb-6">
        {(['pending', 'approved', 'rejected'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded-lg transition-colors ${
              activeTab === tab
                ? 'bg-emerald-900 text-white'
                : 'bg-white text-stone-600 hover:bg-stone-50 border border-stone-200'
            }`}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-6">
        <AnimatePresence>
          {filteredApplications.map(app => (
            <div key={app.id}>
              {renderApplicationCard(app)}
            </div>
          ))}
        </AnimatePresence>
      </div>

      <AnimatePresence>
        {selectedApplication && (
          <FullApplicationModal
            application={selectedApplication}
            onClose={() => setSelectedApplication(null)}
          />
        )}
      </AnimatePresence>
    </div>
  );
}