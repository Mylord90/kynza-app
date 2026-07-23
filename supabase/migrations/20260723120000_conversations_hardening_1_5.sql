-- KYNZA — Messaging V1, Migration 1.5 — `conversations` hardening.
--
-- Closes exactly four decisions opened/spec'd by the "Revue de finalisation de la fondation"
-- (docs/ADR_MESSAGING_FOUNDATION.md, 2026-07-22) and nothing else:
--   DEC-013 — protect_conversation_columns (column-level guard, 7 categories, default-deny)
--   DEC-021 — gap RLS Migration 1 (UPDATE policies with no column restriction) — closed AS A
--             CONSEQUENCE of DEC-013, no separate SQL of its own
--   DEC-022 — staff_id IN (...) subqueries missing is_active/deleted_at — rotation gap
--   DEC-023 — no owner/manager UPDATE policy on `conversations`
--
-- Deliberately NOT in this migration (Rule 8 — one migration, its named decisions, nothing else):
--   - `supabase_realtime` publication for `conversations` (ADR §D.8, residual #5). It is not a
--     DEC, it is an infra action item bundled in the ADR's own roadmap narrative alongside this
--     migration — but it changes a different concern (event delivery, not schema/RLS/trigger) and
--     has its own proof shape (query `pg_publication_tables`, not SQLSTATE). Folding it in here
--     would violate "one migration, one proof". It stays OPEN, tracked in the checklist, to be
--     closed by its own commit before Migration 2 starts relying on Realtime for `messages`.
--   - Anything touching `public.messages` — that table does not exist yet and nothing here creates
--     it, references it, or assumes its shape.
--   - DEC-014/015/016 — those are Migration 2 (`messages`) decisions; DEC-015's columns
--     (`blocked_by`/`blocked_at`) already exist since Migration 1, this migration only places them
--     under `protect_conversation_columns` Category E — no new column, no new FK.
--
-- Design already reviewed, adversarially tested on paper, and LOCKED (design) in the ADR before a
-- single line here was written — see docs/ADR_MESSAGING_FOUNDATION.md, "Revue de finalisation de
-- la fondation", §A (DEC-013), §D.2 (DEC-023), §D.3 (DEC-022). This file implements that spec
-- verbatim; it does not re-derive it.
--
-- ---------------------------------------------------------------------------------------------
-- DEC-023 — owner/manager UPDATE policy on `conversations` (ADR §D.2)
-- ---------------------------------------------------------------------------------------------
-- Migration 1 (20260721160000_conversations_schema.sql:200-205) only defined
-- conversations_client_update_own_state and conversations_staff_update_own_state. For a
-- `client_salon` conversation (staff_id IS NULL, enforced by chk_staff_type/DEC-004), the staff
-- policy's `staff_id IN (...)` can never match NULL — no owner/manager could pin/archive/hide a
-- `client_salon` thread, the salon's shared inbox use case, at all. This policy makes the row
-- reachable for owner/manager; column-level enforcement is still protect_conversation_columns
-- below (RLS scopes rows, the trigger scopes columns — same split of responsibility as DEC-013).
CREATE POLICY "conversations_owner_manager_update_own_state" ON public.conversations
  FOR UPDATE USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );

COMMENT ON POLICY "conversations_owner_manager_update_own_state" ON public.conversations IS
  'DEC-023. Without this policy, no owner/manager can UPDATE a client_salon conversation (staff_id IS NULL never matches the staff policy''s IN (...) clause) — the salon shared-inbox use case (pin/archive/hide) is unreachable. has_role() scopes strictly to salon_id (verified: has_role WHERE u.salon_id = _salon_id), so this grants no cross-salon authority. Column-level protection is still enforced by trg_protect_conversation_columns, not by this policy.';

-- ---------------------------------------------------------------------------------------------
-- DEC-022 — staff_id IN (...) subqueries missing is_active/deleted_at (ADR §D.3)
-- ---------------------------------------------------------------------------------------------
-- staff_profiles.is_active/deleted_at already exist and are already used elsewhere to filter
-- active personnel (idx_staff_salon, 20260623220000_staff_management.sql:23-25). Both existing
-- `staff_id IN (SELECT id FROM staff_profiles WHERE user_id = auth.uid())` policies below omitted
-- this filter — a deactivated or removed staff member kept full, permanent read+write access to
-- their former conversations. Fixed by DROP + CREATE (Postgres has no CREATE OR REPLACE POLICY);
-- the row-selecting condition changes, the policy name and command do not, so no application code
-- or documentation elsewhere needs to change.
DROP POLICY "conversations_staff_select" ON public.conversations;
CREATE POLICY "conversations_staff_select" ON public.conversations
  FOR SELECT USING (
    staff_id IN (
      SELECT id FROM public.staff_profiles
      WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL
    )
  );

DROP POLICY "conversations_staff_update_own_state" ON public.conversations;
CREATE POLICY "conversations_staff_update_own_state" ON public.conversations
  FOR UPDATE USING (
    staff_id IN (
      SELECT id FROM public.staff_profiles
      WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL
    )
  )
  WITH CHECK (
    staff_id IN (
      SELECT id FROM public.staff_profiles
      WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL
    )
  );

COMMENT ON POLICY "conversations_staff_select" ON public.conversations IS
  'DEC-022. MUST keep AND is_active = true AND deleted_at IS NULL on the staff_profiles subquery. Without it, a deactivated or salon-removed staff member keeps permanent read access to every client_staff conversation they were ever assigned to. Do not copy the unfiltered form from Migration 1 (20260721160000_conversations_schema.sql:189-192) into any future policy on this domain, including messages_participant_select (Migration 2) — that draft must be written with this filter from the start, never unfiltered-then-fixed.';

COMMENT ON POLICY "conversations_staff_update_own_state" ON public.conversations IS
  'DEC-022 — see conversations_staff_select, same rule, same reason, write side.';

-- ---------------------------------------------------------------------------------------------
-- DEC-013 / DEC-021 — protect_conversation_columns (ADR §A.3)
-- ---------------------------------------------------------------------------------------------
-- Closes DEC-021 (Migration 1's UPDATE policies bound rows, never columns) as a direct
-- consequence: this trigger is the column-level guard DEC-021 named as its own closing mechanism.
-- Partition of the 23 columns of `conversations` into 7 categories, each verified live against
-- information_schema before this file was written (23/23 accounted for, ADR §A.1). Refusal is the
-- default: every branch below is a POSITIVE check for an allowed write, never a deduced ELSE
-- (ADR §B.2) ; a final to_jsonb() diff rejects any changed column not named in any branch above —
-- including a column added by a future migration that forgot to update this function.
CREATE OR REPLACE FUNCTION public.protect_conversation_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  is_client     BOOLEAN := auth.uid() = OLD.client_id;
  is_salon_side BOOLEAN := EXISTS (
                    SELECT 1 FROM public.staff_profiles sp
                    WHERE sp.id = OLD.staff_id AND sp.user_id = auth.uid()
                      AND sp.is_active = true AND sp.deleted_at IS NULL
                  )
                  OR public.has_role(auth.uid(), 'owner', OLD.salon_id)
                  OR public.has_role(auth.uid(), 'manager', OLD.salon_id);
  nested        BOOLEAN := pg_trigger_depth() > 1;                       -- see DEC-014, ADR §A.4
  is_system     BOOLEAN := COALESCE(auth.role() <> 'authenticated', true); -- see finding below
  drift_keys    TEXT[];
BEGIN
  -- A — IDENTITY_IMMUTABLE: invariant, no role exception at all (same posture as the invariant-7
  -- trigger / DEC-006) — not even service_role may rewrite a row's identity post-INSERT.
  IF NEW.id IS DISTINCT FROM OLD.id OR NEW.salon_id IS DISTINCT FROM OLD.salon_id
     OR NEW.type IS DISTINCT FROM OLD.type OR NEW.client_id IS DISTINCT FROM OLD.client_id
     OR NEW.staff_id IS DISTINCT FROM OLD.staff_id
     OR NEW.related_booking_id IS DISTINCT FROM OLD.related_booking_id
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'conversations: identity columns are immutable (id/salon_id/type/client_id/staff_id/related_booking_id/created_at)';
  END IF;

  -- B — SYSTEM_COUNTERS: only a nested trigger (future bump/reset, any role) or service_role writes.
  IF (NEW.last_message_at IS DISTINCT FROM OLD.last_message_at
      OR NEW.last_message_preview IS DISTINCT FROM OLD.last_message_preview
      OR NEW.client_unread_count IS DISTINCT FROM OLD.client_unread_count
      OR NEW.salon_unread_count IS DISTINCT FROM OLD.salon_unread_count)
     AND NOT (nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: last_message_*/*_unread_count are system-managed only';
  END IF;

  -- E — BLOCK_STATE: service_role only (never a direct authenticated UPDATE — DEC-015).
  IF (NEW.blocked_by IS DISTINCT FROM OLD.blocked_by OR NEW.blocked_at IS DISTINCT FROM OLD.blocked_at)
     AND NOT is_system THEN
    RAISE EXCEPTION 'conversations: blocked_by/blocked_at are writable only via toggle-conversation-block (service_role)';
  END IF;

  -- F — ADMIN_GLOBAL: service_role only (future GDPR/admin erasure flow).
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at AND NOT is_system THEN
    RAISE EXCEPTION 'conversations: deleted_at (global) is writable only by an administrative/GDPR flow';
  END IF;

  -- C / C' — CLIENT_OWN_SIDE.
  IF (NEW.client_pinned IS DISTINCT FROM OLD.client_pinned
      OR NEW.client_archived IS DISTINCT FROM OLD.client_archived
      OR NEW.client_deleted_at IS DISTINCT FROM OLD.client_deleted_at)
     AND NOT (is_client OR is_system) THEN
    RAISE EXCEPTION 'conversations: client_pinned/client_archived/client_deleted_at are client-only';
  END IF;
  IF NEW.client_hidden_at IS DISTINCT FROM OLD.client_hidden_at
     AND NOT (is_client OR nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: client_hidden_at is client-only or system auto-unhide';
  END IF;

  -- D / D' — SALON_OWN_SIDE.
  IF (NEW.salon_pinned IS DISTINCT FROM OLD.salon_pinned
      OR NEW.salon_archived IS DISTINCT FROM OLD.salon_archived
      OR NEW.salon_deleted_at IS DISTINCT FROM OLD.salon_deleted_at)
     AND NOT (is_salon_side OR is_system) THEN
    RAISE EXCEPTION 'conversations: salon_pinned/salon_archived/salon_deleted_at require current salon-side authority';
  END IF;
  IF NEW.salon_hidden_at IS DISTINCT FROM OLD.salon_hidden_at
     AND NOT (is_salon_side OR nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: salon_hidden_at requires current salon-side authority or system auto-unhide';
  END IF;

  -- Anti-drift net: any changed column absent from every list above fails loudly instead of
  -- silently passing — including a column a future migration adds without updating this function.
  -- updated_at (Category G) is deliberately excluded: it is delegated to conversations_updated_at
  -- (see protective comment on this function, ordering proof ADR §A.4).
  SELECT array_agg(n.key) INTO drift_keys
  FROM jsonb_each(to_jsonb(NEW)) n JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
  WHERE n.value IS DISTINCT FROM o.value
    AND n.key NOT IN (
      'id','salon_id','type','client_id','staff_id','related_booking_id','created_at',
      'last_message_at','last_message_preview','client_unread_count','salon_unread_count',
      'blocked_by','blocked_at','deleted_at',
      'client_pinned','client_archived','client_deleted_at','client_hidden_at',
      'salon_pinned','salon_archived','salon_deleted_at','salon_hidden_at',
      'updated_at'
    );
  IF drift_keys IS NOT NULL THEN
    RAISE EXCEPTION 'protect_conversation_columns: uncategorized column(s) % changed — this is schema drift, categorize before allowing this write', drift_keys;
  END IF;

  RETURN NEW;
END; $$;

REVOKE EXECUTE ON FUNCTION public.protect_conversation_columns() FROM authenticated, anon, public;

CREATE TRIGGER trg_protect_conversation_columns BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.protect_conversation_columns();

-- Ordering proof (ADR §A.4): conversations already carries `conversations_updated_at` (Migration
-- 1, 20260721160000_conversations_schema.sql:181-182). Postgres fires same-event triggers in
-- alphabetical order of trigger name: 'conversations_updated_at' < 'trg_protect_conversation_columns'
-- (c < t) — updated_at is already forced to NOW() by the time this function's snapshot of OLD/NEW
-- runs, and this function never inspects or touches updated_at (excluded from the drift list
-- above). Confirmed live before this migration was written: pg_trigger with tgrelid =
-- 'public.conversations'::regclass returned exactly {conversations_updated_at,
-- trg_check_conversation_salon_active} pre-migration (the third trigger created by this file did
-- not exist yet to query) — re-verified post-push as part of this migration's proof set, see ADR.

COMMENT ON FUNCTION public.protect_conversation_columns() IS
  'DEC-013/DEC-021. 7-category partition of all 23 conversations columns, default-deny: every branch is a positive check, the final to_jsonb() diff rejects any changed column named in no branch (including a future column a migration forgot to categorize here). is_system MUST stay COALESCE(auth.role() <> ''authenticated'', true) — TWO REJECTED ALTERNATIVES, both tried and empirically disproved during Migration 1.5 review, do not reintroduce either: (1) bare auth.role() <> ''authenticated'' — auth.role() reads a JWT-claims GUC that PostgREST always sets for real traffic but is NULL on any raw/direct connection (superuser sessions, maintenance scripts); under PL/pgSQL three-valued logic NULL <> ''authenticated'' is NULL and IF NULL silently behaves as false, so is_system was never actually PROVEN true for those callers, only accidentally permissive. (2) current_user IN (''service_role'',''postgres'') — WRONG, empirically disproved: inside a SECURITY DEFINER function current_user is the FUNCTION OWNER (here, postgres), not the caller, for the entire duration of the call — this made is_system unconditionally true for every single invocation regardless of who issued the UPDATE, disabling every category B/C/D/E/F check. auth.role() is GUC-based and is NOT affected by the SECURITY DEFINER ownership switch, which is exactly why it is the correct primitive here despite (1)''s NULL edge case; COALESCE(...,true) makes the NULL-is-system choice explicit and provable instead of an accidental side effect of IF-with-NULL semantics — it assumes no authenticated end-user can ever reach this table via a raw Postgres connection that bypasses PostgREST''s claims-setting (true today; re-verify this assumption if that ever changes). NEVER add an auth.role() = ''authenticated'' guard at the top level the way check_conversation_salon_active explicitly must NOT (inversion vs. that trigger, ADR §6): Category A here is deliberately unconditional (blocks service_role too), while Categories B/C/D/E/F deliberately DO let service_role/nested-trigger writers through — read ADR §A.3-A.4 in full before changing any branch, the two triggers on this table follow opposite rules for opposite reasons.';

-- ---------------------------------------------------------------------------------------------
-- Realtime, deliberately NOT done here (see header) — tracked as its own open item.
-- ---------------------------------------------------------------------------------------------
