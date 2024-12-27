import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { LandingPage } from './pages/LandingPage';
import { PendingPage } from './pages/PendingPage';
import { AuthenticatedApp } from './components/AuthenticatedApp';
import { ConfirmationPage } from './pages/ConfirmationPage';
import { Retro2Page } from './pages/Retro2Page';
import { ErrorBoundary } from './components/ErrorBoundary';
import { StripeProvider } from './contexts/StripeContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import { useSession } from './hooks/useSession';

export default function App() {
  const session = useSession();
  const [loading, setLoading] = useState(true);
  const [metadata, setMetadata] = useState<any>(null);

  useEffect(() => {
    let mounted = true;

    const checkUserStatus = async () => {
      try {
        // If no session, show public routes
        if (!session?.user) {
          if (mounted) setLoading(false);
          return;
        }

        const { data: { user }, error } = await supabase.auth.getUser();
        if (error) throw error;
        if (!mounted) return;

        // Get user metadata
        const userMetadata = user?.user_metadata || {};
        setMetadata(userMetadata);
      } catch (err) {
        console.error('Error checking user status:', err);
      } finally {
        if (mounted) setLoading(false);
      }
    };

    checkUserStatus();

    return () => {
      mounted = false;
    };
  }, [session]);

  // Show public routes while loading or no session
  if (loading || !session) {
    return (
      <ErrorBoundary>
        <ThemeProvider>
          <Router>
            <Routes>
              <Route path="/" element={<LandingPage />} />
              <Route path="/confirmation" element={<ConfirmationPage />} />
            </Routes>
          </Router>
        </ThemeProvider>
      </ErrorBoundary>
    );
  }

  // Get user metadata with proper type checking
  const isAdmin = metadata?.is_admin === true;
  const hasApplied = metadata?.has_applied === true;
  const applicationStatus = metadata?.application_status;

  // If user is admin or has an approved application, show full app
  if (isAdmin || applicationStatus === 'approved') {
    return (
      <ErrorBoundary>
        <ThemeProvider>
          <Router>
            <StripeProvider>
              <Routes>
                <Route path="/*" element={<AuthenticatedApp />} />
                <Route path="/confirmation" element={<ConfirmationPage />} />
              </Routes>
            </StripeProvider>
          </Router>
        </ThemeProvider>
      </ErrorBoundary>
    );
  }

  // If they haven't applied yet, show Retro2 application page
  if (!hasApplied) {
    return (
      <ErrorBoundary>
        <ThemeProvider>
          <Router>
            <Routes>
              <Route path="*" element={<Retro2Page />} />
            </Routes>
          </Router>
        </ThemeProvider>
      </ErrorBoundary>
    );
  }

  // If they've applied but application is pending or rejected
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <PendingPage status={applicationStatus} />
      </ThemeProvider>
    </ErrorBoundary>
  );
}