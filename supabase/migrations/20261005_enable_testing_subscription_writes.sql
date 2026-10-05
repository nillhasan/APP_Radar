-- ============================================================================
-- Migration: 20261005_enable_testing_subscription_writes
-- Description: Enables authenticated users to insert and update their own subscription
--              tier directly in Supabase. This allows test users to upgrade to Pro
--              and have their Pro status persist across logout and second logins.
-- ============================================================================

-- 1. Allow authenticated users to insert their subscription record with any tier during testing
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscription" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 2. Allow authenticated users to update their own subscription record
DROP POLICY IF EXISTS "Users can update own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscription" ON public.user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Ensure authenticated users can view their own subscription
DROP POLICY IF EXISTS "Users can view own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);
