import React, { useState } from 'react';
import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';
import { supabase } from '../lib/supabase';
import { X } from 'lucide-react';

export function LoginButton() {
  const [showLogin, setShowLogin] = useState(false);

  return (
    <>
      <button
        onClick={() => setShowLogin(true)}
        className="bg-emerald-900 text-white px-6 py-2 rounded-full hover:bg-emerald-800 transition-colors text-sm font-body"
      >
        Log In
      </button>

      {showLogin && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-xl font-display font-light">Log In</h2>
              <button onClick={() => setShowLogin(false)} className="text-stone-500 hover:text-stone-700">
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <Auth
              supabaseClient={supabase}
              appearance={{
                theme: ThemeSupa,
                variables: {
                  default: {
                    colors: {
                      brand: '#064E3B',
                      brandAccent: '#065F46',
                    }
                  }
                }
              }}
              providers={[]}
            />
          </div>
        </div>
      )}
    </>
  );
}