-- ============================================================================
-- Script: 20261005_production_cleanup_and_lockdown
-- Description: Run this in Supabase SQL Editor BEFORE going live with Stripe.
--              It resets/cleans test user subscriptions and re-locks RLS so only
--              the Stripe Webhook service role can assign Pro subscriptions.
-- ============================================================================

-- 1. Reset all test accounts back to 'free' (retaining owner metanestshop@gmail.com)
UPDATE public.user_subscriptions
SET 
  tier = 'free',
  status = 'active',
  stripe_customer_id = null,
  stripe_subscription_id = null,
  current_period_end = null,
  updated_at = now()
WHERE user_id NOT IN (
  SELECT id FROM auth.users WHERE email = 'metanestshop@gmail.com'
);

-- (Optional) If you prefer completely deleting test user subscription rows:
-- DELETE FROM public.user_subscriptions 
-- WHERE user_id NOT IN (SELECT id FROM auth.users WHERE email = 'metanestshop@gmail.com');

-- 2. Revoke client-side self-update policy (Strict Production Security)
DROP POLICY IF EXISTS "Users can update own subscription" ON public.user_subscriptions;

-- 3. Lock insert so users can only create default 'free' subscriptions upon sign-up
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscription" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id AND tier = 'free');

-- 4. Ensure users can still read their own subscription
DROP POLICY IF EXISTS "Users can view own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);
