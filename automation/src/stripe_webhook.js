/**
 * AppRadar - Stripe Webhook & Supabase Subscription Sync Service
 * 
 * This service receives real-time webhook events from Stripe whenever a customer
 * completes checkout, updates their subscription, or cancels via Customer Portal.
 * 
 * Usage:
 *   1. Install dependencies:
 *      npm install
 *   2. Set environment variables in automation/.env:
 *      STRIPE_SECRET_KEY=sk_test_...
 *      STRIPE_WEBHOOK_SECRET=whsec_...
 *      SUPABASE_URL=https://<your-project>.supabase.co
 *      SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
 *   3. Test locally with Stripe CLI:
 *      stripe listen --forward-to localhost:4242/webhook
 *   4. Run the server:
 *      npm run webhook
 */

import express from 'express';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

dotenv.config();

const app = express();
const port = process.env.PORT || 4242;

const stripeKey = process.env.STRIPE_SECRET_KEY;
const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn('[Warning] SUPABASE_URL or key missing in environment. Database sync will be simulated.');
}

const supabase = (supabaseUrl && supabaseKey) 
  ? createClient(supabaseUrl, supabaseKey)
  : null;

const stripe = stripeKey ? new Stripe(stripeKey) : null;

// Stripe requires the raw body to verify webhook signature
app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    if (stripe && webhookSecret) {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } else {
      // In development/testing without live secrets, parse json directly
      event = JSON.parse(req.body.toString('utf8'));
    }
  } catch (err) {
    console.error(`❌ Webhook signature verification failed:`, err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log(`🔔 Stripe event received: ${event.type} [${event.id}]`);

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        const userId = session.client_reference_id;
        const customerId = session.customer;
        const subscriptionId = session.subscription;
        const customerEmail = session.customer_details?.email || session.prefilled_email;

        console.log(`✅ Checkout completed for user [${userId}] (email: ${customerEmail})`);

        if (userId && supabase) {
          const { error } = await supabase
            .from('user_subscriptions')
            .upsert({
              user_id: userId,
              tier: 'pro',
              stripe_customer_id: customerId,
              stripe_subscription_id: subscriptionId,
              status: 'active',
              updated_at: new Date().toISOString(),
            }, { onConflict: 'user_id' });

          if (error) {
            console.error('❌ Failed to update user_subscriptions in Supabase:', error);
          } else {
            console.log(`🎉 Pro Builder tier successfully activated in Supabase for user [${userId}]`);
          }
        } else if (!userId) {
          console.warn('⚠️ No client_reference_id found on checkout session. Match by email or customer ID if needed.');
        }
        break;
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const status = subscription.status; // 'active', 'past_due', 'canceled', etc.
        const customerId = subscription.customer;

        console.log(`🔄 Subscription updated for customer [${customerId}]: status = ${status}`);

        if (supabase) {
          const tier = status === 'active' ? 'pro' : 'free';
          const periodEnd = subscription.current_period_end 
            ? new Date(subscription.current_period_end * 1000).toISOString()
            : null;

          await supabase
            .from('user_subscriptions')
            .update({
              tier: tier,
              status: status,
              current_period_end: periodEnd,
              cancel_at_period_end: subscription.cancel_at_period_end,
              updated_at: new Date().toISOString(),
            })
            .eq('stripe_customer_id', customerId);
        }
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const customerId = subscription.customer;

        console.log(`⚠️ Subscription canceled for customer [${customerId}]`);

        if (supabase) {
          await supabase
            .from('user_subscriptions')
            .update({
              tier: 'free',
              status: 'canceled',
              updated_at: new Date().toISOString(),
            })
            .eq('stripe_customer_id', customerId);

          console.log(`ℹ️ User reverted to Free tier in Supabase.`);
        }
        break;
      }

      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (err) {
    console.error('❌ Error processing webhook event:', err);
    res.status(500).json({ error: 'Webhook processing failure' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'AppRadar Stripe Webhook Sync',
    stripeConfigured: Boolean(stripeKey && webhookSecret),
    supabaseConfigured: Boolean(supabase),
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`🚀 AppRadar Stripe Webhook server listening on http://localhost:${port}`);
  console.log(`👉 Webhook endpoint: http://localhost:${port}/webhook`);
});
