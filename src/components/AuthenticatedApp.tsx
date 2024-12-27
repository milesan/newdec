import React, { useState, useEffect } from 'react';
import { MyBookings } from './MyBookings';
import { Book2Page } from '../pages/Book2Page';
import { AdminPage } from '../pages/AdminPage';
import { ConfirmationPage } from '../pages/ConfirmationPage';
import { useSession } from '../hooks/useSession';
import { supabase } from '../lib/supabase';
import { Routes, Route, useNavigate, Navigate } from 'react-router-dom';
import { PaymentPage } from '../pages/PaymentPage';
import { useAccommodations } from '../hooks/useAccommodations';
import { WhitelistWelcomeModal } from './WhitelistWelcomeModal';

export function AuthenticatedApp() {
  const [currentPage, setCurrentPage] = useState<'calendar' | 'my-bookings' | 'admin'>('calendar');
  const [showWelcomeModal, setShowWelcomeModal] = useState(false);
  const session = useSession();
  const navigate = useNavigate();
  const isAdmin = session?.user?.email === 'andre@thegarden.pt';
  const { accommodations, refresh: refreshAccommodations } = useAccommodations();

  useEffect(() => {
    checkWhitelistStatus();
  }, []);

  const checkWhitelistStatus = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user?.email) return;

      // Check if user is whitelisted and hasn't seen welcome
      const { data: metadata } = await supabase.auth.getUser();
      const isWhitelisted = metadata.user?.user_metadata?.is_whitelisted;
      const hasSeenWelcome = metadata.user?.user_metadata?.has_seen_welcome;

      if (isWhitelisted && !hasSeenWelcome) {
        setShowWelcomeModal(true);
      }
    } catch (err) {
      console.error('Error checking whitelist status:', err);
    }
  };

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      window.location.href = '/';
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const handleWelcomeClose = async () => {
    try {
      await supabase.auth.updateUser({
        data: {
          has_seen_welcome: true
        }
      });

      await supabase.rpc('mark_whitelist_welcome_seen', {
        p_email: session?.user?.email
      });

      setShowWelcomeModal(false);
    } catch (err) {
      console.error('Error updating welcome status:', err);
      setShowWelcomeModal(false);
    }
  };

  if (!session) {
    return <Navigate to="/" replace />;
  }

  const handleNavigation = (page: 'calendar' | 'my-bookings' | 'admin') => {
    setCurrentPage(page);
    navigate(page === 'calendar' ? '/' : `/${page}`);
  };

  return (
    <div className="min-h-screen bg-stone-50">
      <header className="sticky top-0 z-50 bg-white border-b border-stone-200">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="text-black flex items-center gap-3">
              <img 
                src="https://raw.githubusercontent.com/milesan/synesthesia/refs/heads/main/Enso%20Zen%20Soto%20Symbol.png" 
                alt="Logo" 
                className="w-[42px] h-[42px]"
              />
              <div>
                <h1 className="text-2xl font-display font-light tracking-wide">The Garden</h1>
                <p className="text-sm text-stone-600 hidden md:block font-['EB_Garamond'] italic tracking-wide">
                  a new kind of place
                </p>
              </div>
            </div>
            <div className="flex items-center gap-6">
              <nav className="flex gap-6">
                <button
                  onClick={() => handleNavigation('calendar')}
                  className={`text-sm font-body transition-colors ${
                    currentPage === 'calendar' 
                      ? 'text-emerald-900 font-medium' 
                      : 'text-stone-600 hover:text-emerald-900'
                  }`}
                >
                  Calendar
                </button>
                <button
                  onClick={() => handleNavigation('my-bookings')}
                  className={`text-sm font-body transition-colors ${
                    currentPage === 'my-bookings' 
                      ? 'text-emerald-900 font-medium' 
                      : 'text-stone-600 hover:text-emerald-900'
                  }`}
                >
                  My Account
                </button>
                {isAdmin && (
                  <button
                    onClick={() => handleNavigation('admin')}
                    className="bg-emerald-900 text-white px-4 py-2 rounded-lg hover:bg-emerald-800 transition-colors text-sm font-body"
                  >
                    Admin Panel
                  </button>
                )}
              </nav>
              <button 
                onClick={handleSignOut}
                className="bg-stone-100 text-stone-600 px-6 py-2 hover:bg-stone-200 transition-colors text-sm font-body rounded-lg"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="relative">
        <Routes>
          <Route path="/" element={<Book2Page />} />
          <Route path="/my-bookings" element={<MyBookings />} />
          {isAdmin && <Route path="/admin" element={<AdminPage />} />}
          <Route path="/confirmation" element={<ConfirmationPage />} />
          <Route path="/payment" element={<PaymentPage />} />
        </Routes>
      </main>

      <WhitelistWelcomeModal
        isOpen={showWelcomeModal}
        onClose={handleWelcomeClose}
      />
    </div>
  );
}