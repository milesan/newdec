import React from 'react';
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';

interface StripePaymentProps {
  amount: number;
  onSuccess: () => void;
  onError: (error: string) => void;
}

export function StripePayment({ amount, onSuccess, onError }: StripePaymentProps) {
  const stripe = useStripe();
  const elements = useElements();

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!stripe || !elements) {
      onError('Stripe not initialized');
      return;
    }

    const { error } = await stripe.createPaymentMethod({
      type: 'card',
      card: elements.getElement(CardElement)!,
    });

    if (error) {
      onError(error.message);
      return;
    }

    onSuccess();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="p-4 bg-white rounded-lg border border-stone-200">
        <CardElement
          options={{
            style: {
              base: {
                fontSize: '16px',
                color: '#1f2937',
                fontFamily: 'Fraunces, serif',
                '::placeholder': {
                  color: '#6b7280',
                },
                iconColor: '#064e3b',
              },
              invalid: {
                color: '#ef4444',
                iconColor: '#ef4444',
              },
            },
            hidePostalCode: true,
          }}
        />
      </div>
      <button
        type="submit"
        disabled={!stripe}
        className="w-full bg-emerald-900 text-white py-3 px-6 rounded-lg hover:bg-emerald-800 disabled:bg-stone-300 disabled:cursor-not-allowed transition-colors text-sm font-body"
      >
        Pay €{amount}
      </button>
    </form>
  );
}