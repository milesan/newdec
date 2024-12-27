import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@13.10.0?target=deno';

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY_PROD') ?? '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req) => {
    
  // Set up CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders, status: 200 })
  }

  // Handle stripe checkout
  try {

    
    const body = await req.json();
    const { total, description } = body;
    
    const session = await stripe.checkout.sessions.create({
        ui_mode: 'embedded',
        line_items: [{
            price_data: {
              currency: "eur",
              tax_behavior: "inclusive",
              unit_amount: total * 100,
              product_data: {
                name: "Donation to the Garden Associação, " + description,
              },
            },
            quantity: 1,
          }],
        mode: 'payment',
        automatic_tax: {enabled: true},
        redirect_on_completion: 'never'
      });

    return new Response(JSON.stringify({clientSecret: session.client_secret}), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, // Be sure to add CORS headers here too
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, // and here
      status: 400,
    })
  }
})