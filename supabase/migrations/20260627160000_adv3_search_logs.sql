-- ================================================================
-- ADV.3 — Advanced search: search_logs backs the "popular searches"
-- aggregation; recent searches stay client-side (Hive), no table needed.
-- ================================================================

CREATE TABLE IF NOT EXISTS public.search_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id),
  query TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_search_logs_query
  ON public.search_logs(query, created_at DESC);

ALTER TABLE public.search_logs ENABLE ROW LEVEL SECURITY;

-- A user can log their own search, but never read anyone's individual
-- query history (including their own) — only the aggregate view below.
CREATE POLICY "authenticated_insert_own_search_log" ON public.search_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Deliberately NOT security_invoker — this is a cross-user aggregate by
-- design (site-wide "popular searches", same idea as any e-commerce
-- trending-searches widget), and search_logs has no SELECT policy at all,
-- so a security_invoker view here would just return zero rows. Plain
-- queries (e.g. exact text) only, never anything sensitive.
CREATE OR REPLACE VIEW public.v_popular_searches AS
SELECT query, COUNT(*) AS search_count
FROM public.search_logs
WHERE created_at >= NOW() - INTERVAL '30 days' AND length(query) >= 2
GROUP BY query
ORDER BY search_count DESC
LIMIT 10;

GRANT SELECT ON public.v_popular_searches TO authenticated, anon;