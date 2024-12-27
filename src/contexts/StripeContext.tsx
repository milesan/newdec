import React, { createContext, useContext } from 'react';
import { loadStripe } from '@stripe/stripe-js';

interface StripeContextType {
  isReady: boolean;
}

const StripeContext = createContext<StripeContextType>({
  isReady: false,
});

export function useStripe() {
  return useContext(StripeContext);
}

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLIC_KEY_PROD || '');

export function StripeProvider({ children }: { children: React.ReactNode }) {
  if (!stripePromise) {
    return <div>Loading Stripe...</div>;
  }

  return (
    <StripeContext.Provider value={{ isReady: true }}>
      {children}
    </StripeContext.Provider>
  );
}