-- ============================================================================
-- Migration: 20261005_grant_pro_to_owner
-- Description: Sets permanent lifetime Pro Builder subscription for project owner
-- ============================================================================

INSERT INTO public.user_subscriptions (user_id, tier, status, current_period_end, updated_at)
SELECT id, 'pro', 'active', '2099-12-31 23:59:59+00'::timestamptz, now()
FROM auth.users
WHERE email = 'metanestshop@gmail.com'
ON CONFLICT (user_id) 
DO UPDATE SET 
  tier = 'pro', 
  status = 'active', 
  current_period_end = '2099-12-31 23:59:59+00'::timestamptz,
  updated_at = now();
