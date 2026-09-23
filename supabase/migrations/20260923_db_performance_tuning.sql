-- ============================================================================
-- Migration: 20260923_db_performance_tuning
-- Description: Adds B-tree indexes on foreign keys, categories, metrics, and dates
--              to eliminate sequential table scans and optimize multi-table joins.
--              Introduces app_intelligence_view for fast single-roundtrip queries.
-- ============================================================================

-- 1. Indexes for app_analysis (foreign keys & sorting)
-- Eliminates full table scan during nested joins and pipeline deletions
CREATE INDEX IF NOT EXISTS idx_app_analysis_app_id 
  ON app_analysis(app_id);

CREATE INDEX IF NOT EXISTS idx_app_analysis_opp_score 
  ON app_analysis(opportunity_score DESC NULLS LAST);

-- 2. Indexes for apps (filtering & sorting)
-- Accelerates category filters, platform filters, and leaderboard rankings
CREATE INDEX IF NOT EXISTS idx_apps_category 
  ON apps(category);

CREATE INDEX IF NOT EXISTS idx_apps_platform 
  ON apps(platform);

CREATE INDEX IF NOT EXISTS idx_apps_rating 
  ON apps(rating DESC);

CREATE INDEX IF NOT EXISTS idx_apps_review_count 
  ON apps(review_count DESC);

CREATE INDEX IF NOT EXISTS idx_apps_category_rating 
  ON apps(category, rating DESC);

-- 3. Indexes for app_metrics (latest metric lookup & sorting)
-- Enables instant lookup of the most recent metric date per application
CREATE INDEX IF NOT EXISTS idx_app_metrics_app_id_date_desc 
  ON app_metrics(app_id, metric_date DESC);

CREATE INDEX IF NOT EXISTS idx_app_metrics_downloads 
  ON app_metrics(downloads DESC);

CREATE INDEX IF NOT EXISTS idx_app_metrics_revenue 
  ON app_metrics(revenue_estimate DESC);

-- 4. Indexes for reports & watchlists
-- Accelerates getLatestDailyReport and user watchlist cascade checks
CREATE INDEX IF NOT EXISTS idx_reports_report_date 
  ON reports(report_date DESC);

CREATE INDEX IF NOT EXISTS idx_user_watchlists_app_id 
  ON user_watchlists(app_id);

-- 5. High-performance pre-joined view for App Intelligence
-- Fetches apps, AI analysis, and ONLY the single latest daily metric row
-- using a lateral join. Avoids downloading all historical metrics into client memory.
CREATE OR REPLACE VIEW app_intelligence_view WITH (security_invoker = true) AS
SELECT 
  a.id,
  a.name,
  a.developer,
  a.category,
  a.platform,
  a.description,
  a.app_url,
  a.icon_url,
  a.screenshot_urls,
  a.rating,
  a.review_count,
  a.price,
  an.opportunity_score,
  an.growth_signal,
  an.market_signal,
  an.revenue_signal,
  an.review_signal,
  an.ranking_signal,
  an.target_user,
  an.core_features,
  an.monetization,
  an.user_pain_points,
  an.market_opportunity,
  an.build_opportunity,
  an.mvp_features,
  an.risks,
  an.ai_summary,
  m.rank,
  m.downloads,
  m.revenue_estimate,
  m.growth_rate,
  m.metric_date
FROM apps a
LEFT JOIN app_analysis an ON an.app_id = a.id
LEFT JOIN LATERAL (
  SELECT rank, downloads, revenue_estimate, growth_rate, metric_date
  FROM app_metrics m
  WHERE m.app_id = a.id
  ORDER BY m.metric_date DESC
  LIMIT 1
) m ON true;
