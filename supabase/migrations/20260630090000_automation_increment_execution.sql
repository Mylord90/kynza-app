-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 2 follow-up.
-- Supabase's JS .update() can't express `count = count + 1` — atomic
-- increment of automation_workflows.execution_count needs a function.
-- ================================================================

CREATE OR REPLACE FUNCTION public.increment_workflow_execution(p_workflow_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  UPDATE public.automation_workflows
  SET execution_count = execution_count + 1,
      last_executed_at = NOW()
  WHERE id = p_workflow_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_workflow_execution(UUID) FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.increment_workflow_execution(UUID) TO service_role;