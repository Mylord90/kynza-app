-- ================================================================
-- KYNZA — Migration 018 — Fix custom_access_token_hook crashing on
-- every brand-new signup (salon_id IS NULL).
--
-- Root cause: jsonb_set() is STRICT — if its `new_value` argument is
-- SQL NULL (not the same as the jsonb 'null'!), the entire jsonb_set()
-- call returns NULL, and every subsequent jsonb_set() in the chain
-- inherits that NULL. to_jsonb(rec.salon_id::text) evaluates to SQL
-- NULL whenever salon_id is NULL — true for every new signup, since
-- salon_id is only populated once an Owner creates a salon. The hook
-- therefore returned NULL instead of valid claims on every signup,
-- which Supabase Auth surfaces as "Database error saving new user" /
-- "Database error creating new user" — discovered while verifying
-- Phase 2's E2E booking flow (no auth.users row had ever been created
-- successfully in this project before this fix).
-- ================================================================

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE claims jsonb; rec record;
BEGIN
  SELECT u.role, u.salon_id, u.preferred_currency,
         u.country_code, u.email, u.auth_provider
  INTO rec
  FROM public.users u
  WHERE u.id = (event->>'user_id')::uuid LIMIT 1;
  claims := event->'claims';
  claims := jsonb_set(claims,'{role}',to_jsonb(COALESCE(rec.role,'client')));
  -- COALESCE(to_jsonb(...), 'null'::jsonb) — salon_id is legitimately
  -- NULL for any user who hasn't created/joined a salon yet; the claim
  -- must become JSON null, never SQL NULL (which would blank out every
  -- jsonb_set() call chained after it).
  claims := jsonb_set(claims,'{salon_id}',COALESCE(to_jsonb(rec.salon_id), 'null'::jsonb));
  claims := jsonb_set(claims,'{preferred_currency}',to_jsonb(COALESCE(rec.preferred_currency,'BIF')));
  claims := jsonb_set(claims,'{country_code}',to_jsonb(COALESCE(rec.country_code,'BI')));
  RETURN jsonb_set(event,'{claims}',claims);
END; $$;
