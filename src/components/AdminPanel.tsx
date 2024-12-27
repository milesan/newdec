import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface AdminPanelProps {
  onClose: () => void;
}

interface Application {
  id: string;
  user_id: string;
  data: any;
  status: string;
  created_at: string;
  user: {
    email: string;
  };
  linked_applications?: {
    linked_name: string;
    linked_email: string;
    linked_application?: {
      id: string;
      user: {
        email: string;
      };
    };
  }[];
}

export function AdminPanel({ onClose }: AdminPanelProps) {
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadApplications();
  }, []);

  const loadApplications = async () => {
    try {
      const { data, error } = await supabase
        .from('applications')
        .select(`
          *,
          user:user_id (
            email
          ),
          linked_applications (
            linked_name,
            linked_email,
            linked_application:linked_application_id (
              id,
              user:user_id (
                email
              )
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setApplications(data || []);
    } catch (err) {
      console.error('Error loading applications:', err);
    } finally {
      setLoading(false);
    }
  };

  const getLinkedApplications = (application: Application) => {
    if (!application.linked_applications?.length) return null;

    return (
      <div className="mt-2 space-y-1">
        <p className="text-sm font-medium text-emerald-900">Linked Applications:</p>
        {application.linked_applications.map((link, index) => (
          <div key={index} className="flex items-center gap-2 text-sm">
            <span className="text-stone-600">{link.linked_name}</span>
            <span className="text-stone-400">•</span>
            <span className="text-stone-600">{link.linked_email}</span>
            {link.linked_application && (
              <>
                <span className="text-stone-400">•</span>
                <span className="text-emerald-600">Applied</span>
              </>
            )}
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg w-full max-w-4xl h-[90vh] flex flex-col">
        <div className="p-4 border-b flex justify-between items-center">
          <h2 className="text-xl font-semibold">Applications</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="flex-1 overflow-auto p-4">
          {loading ? (
            <div className="flex justify-center items-center h-full">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-900"></div>
            </div>
          ) : (
            <div className="space-y-4">
              {applications.map((application) => (
                <div 
                  key={application.id}
                  className="bg-white p-4 rounded-lg border border-stone-200 hover:border-emerald-900/20 transition-colors"
                >
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="font-medium">
                        {application.data[2]} {application.data[3]}
                      </h3>
                      <p className="text-sm text-stone-600">
                        {application.user.email}
                      </p>
                      {getLinkedApplications(application)}
                    </div>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      application.status === 'pending'
                        ? 'bg-yellow-100 text-yellow-800'
                        : application.status === 'approved'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {application.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}