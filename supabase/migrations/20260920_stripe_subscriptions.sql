-- ============================================================================
-- Migration: 20260920_stripe_subscriptions
-- Description: User subscription tiers, Stripe customer/subscription references,
--              and Row Level Security (RLS) policies for AppRadar SaaS.
-- ============================================================================

create table if not exists user_subscriptions (
  user_id uuid references auth.users(id) on delete cascade primary key,
  tier text not null default 'free' check (tier in ('free', 'pro', 'agency')),
  stripe_customer_id text,
  stripe_subscription_id text,
  stripe_price_id text,
  status text not null default 'active',
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index for lookup by Stripe customer and subscription IDs
create index if not exists idx_user_subscriptions_stripe_customer 
  on user_subscriptions(stripe_customer_id);

create index if not exists idx_user_subscriptions_stripe_sub 
  on user_subscriptions(stripe_subscription_id);

-- Enable Row Level Security
alter table user_subscriptions enable row level security;

-- Policies:
-- 1. Authenticated users can view their own subscription tier & status
create policy "Users can view own subscription" on user_subscriptions
  for select using (auth.uid() = user_id);

-- 2. Authenticated users can initialize their own free subscription record
create policy "Users can insert own subscription" on user_subscriptions
  for insert with check (auth.uid() = user_id);

-- 3. Authenticated users can update their own subscription record
create policy "Users can update own subscription" on user_subscriptions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Auto-update updated_at timestamp trigger
create or replace function update_user_subscriptions_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists tr_user_subscriptions_updated_at on user_subscriptions;
create trigger tr_user_subscriptions_updated_at
before update on user_subscriptions
for each row execute function update_user_subscriptions_updated_at();
