-- ============================================================================
-- Migration: 20260921_security_and_rls_hardening
-- Description: Revokes public write access on core intelligence tables and
--              locks down user_subscriptions so users cannot self-assign Pro tiers.
-- ============================================================================

-- 1. Revoke insecure public write policies on apps, metrics, analysis, and reports
drop policy if exists "Allow public insert on apps" on apps;
drop policy if exists "Allow public update on apps" on apps;

drop policy if exists "Allow public insert on app_metrics" on app_metrics;
drop policy if exists "Allow public update on app_metrics" on app_metrics;

drop policy if exists "Allow public insert on app_analysis" on app_analysis;
drop policy if exists "Allow public update on app_analysis" on app_analysis;

drop policy if exists "Allow public insert on reports" on reports;
drop policy if exists "Allow public update on reports" on reports;

-- Ensure public READ policies are active
drop policy if exists "Allow public read on apps" on apps;
create policy "Allow public read on apps" on apps for select using (true);

drop policy if exists "Allow public read on app_metrics" on app_metrics;
create policy "Allow public read on app_metrics" on app_metrics for select using (true);

drop policy if exists "Allow public read on app_analysis" on app_analysis;
create policy "Allow public read on app_analysis" on app_analysis for select using (true);

drop policy if exists "Allow public read on reports" on reports;
create policy "Allow public read on reports" on reports for select using (true);

-- 2. Lock down user_subscriptions to eliminate client-side tier tampering
-- Revoke insecure client self-update policy
drop policy if exists "Users can update own subscription" on user_subscriptions;

-- Users can view their own subscription
drop policy if exists "Users can view own subscription" on user_subscriptions;
create policy "Users can view own subscription" on user_subscriptions
  for select using (auth.uid() = user_id);

-- Users can only initialize a default 'free' subscription record upon registration
drop policy if exists "Users can insert own subscription" on user_subscriptions;
create policy "Users can insert own subscription" on user_subscriptions
  for insert with check (auth.uid() = user_id and tier = 'free');

-- Note: All tier upgrades ('pro', 'agency') and status modifications must strictly
-- be performed by the backend service_role key (Stripe webhook / Edge function).
