import { loadStripe } from '@stripe/stripe-js';

const STRIPE_LIVE_KEY = import.meta.env.VITE_STRIPE_LIVE_KEY;
const stripePromise = loadStripe(STRIPE_LIVE_KEY);

export async function redirectToCheckout(
  title: string,
  checkIn: Date,
  checkOut: Date,
  amount: number
) {
  try {
    const stripe = await stripePromise;
    if (!stripe) throw new Error('Stripe failed to load');

    const { error } = await stripe.redirectToCheckout({
      mode: 'payment',
      lineItems: [{
        price_data: {
          currency: 'eur',
          product_data: {
            name: title,
            description: `Stay from ${checkIn.toLocaleDateString()} to ${checkOut.toLocaleDateString()}`,
          },
          unit_amount: amount * 100, // Convert to cents
        },
        quantity: 1,
      }],
      successUrl: `${window.location.origin}/success`,
      cancelUrl: `${window.location.origin}/cancel`,
    });

    if (error) throw error;
  } catch (err) {
    console.error('Error creating checkout session:', err);
    throw err;
  }
}

// Re-export the function with the expected name
export const createCheckoutSession = redirectToCheckout;