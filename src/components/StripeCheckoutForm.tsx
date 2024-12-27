import { useCallback } from "react";
import { loadStripe } from '@stripe/stripe-js';
import {
  EmbeddedCheckoutProvider,
  EmbeddedCheckout
} from '@stripe/react-stripe-js';

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLIC_KEY_PROD);

interface Props {
  description: string,
  total: number,
  authToken: string,
  onSuccess?: () => void
}

export function StripeCheckoutForm({ total, authToken, description, onSuccess }: Props) {
  const fetchClientSecret = useCallback(() => {
    // Create a Checkout Session
    return fetch(import.meta.env.VITE_SUPABASE_URL + "/functions/v1/stripe-webhook", {
      method: "POST",
      mode: 'cors',
      headers: {
        Authorization: 'Bearer ' + authToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ total, description })
    })
      .then((res) => res.json())
      .then((data) => {
        if (data.clientSecret) {
          return data.clientSecret;
        }
        throw new Error('Failed to create checkout session');
      });
  }, [total, authToken, description]);

  const options = { 
    fetchClientSecret,
    onComplete: () => {
      if (onSuccess) {
        onSuccess();
      }
    }
  };

  return (
    <div id="checkout" className="w-full">
      <EmbeddedCheckoutProvider
        stripe={stripePromise}
        options={options}
      >
        <EmbeddedCheckout />
      </EmbeddedCheckoutProvider>
    </div>
  );
}