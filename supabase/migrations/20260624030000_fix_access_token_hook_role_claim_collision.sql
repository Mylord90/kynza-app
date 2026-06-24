-- ================================================================
-- KYNZA — Migration 020 — Fix custom_access_token_hook clobbering the
-- reserved `role` JWT claim, which broke EVERY authenticated REST /
-- Realtime / Storage request for EVERY logged-in user.
--
-- Root cause: the standard Supabase JWT `role` claim tells PostgREST
-- which Postgres database role to assume for the request (normally
-- "authenticated"). The hook was overwriting it with the app-level
-- role name ("owner"/"manager"/"staff"/"client") — none of which are
-- real Postgres roles — so PostgREST failed every single request with
-- `role "<app role>" does not exist` (error 22023), even though
-- GoTrue's own sign-in/sign-up succeeded and returned a token.
--
-- Verified no app-level RLS policy or Dart code reads
-- auth.jwt()->>'role' for the app role (every policy uses has_role(),
-- which queries public.users directly) — only GoTrue/PostgREST itself
-- consumes this claim, so removing the overwrite is a pure fix with
-- no other call site to update. salon_id/preferred_currency/
-- country_code remain available as custom claims for any future use
-- that genuinely needs them off the JWT instead of a table lookup.
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
  claims := jsonb_set(claims,'{app_role}',to_jsonb(COALESCE(rec.role,'client')));
  claims := jsonb_set(claims,'{salon_id}',COALESCE(to_jsonb(rec.salon_id), 'null'::jsonb));
  claims := jsonb_set(claims,'{preferred_currency}',to_jsonb(COALESCE(rec.preferred_currency,'BIF')));
  claims := jsonb_set(claims,'{country_code}',to_jsonb(COALESCE(rec.country_code,'BI')));
  RETURN jsonb_set(event,'{claims}',claims);
END; $$;
