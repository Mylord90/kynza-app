-- KYNZA — Messaging V1, Migration 2 — `messages` (Phase 1 of the locked 5-phase roadmap,
-- docs/ADR_MESSAGING_FOUNDATION.md, "Feuille de route à 5 phases", 2026-07-23).
--
-- Closes DEC-014 (counters trigger), DEC-016 (category-2 eligibility, booking-active check) and
-- the realtime residual #5 (ADR §D.8) for both `conversations` and `messages`. Implements the
-- `messages` table sketched in docs/KYNZA_MESSAGING_ARCHITECTURE.md §5.3, adjusted by three
-- decisions taken before this file was written (adversarial pre-write review found the sketch
-- under-specified on exactly these points; none was invented here, all three were confirmed
-- explicitly before writing a line of SQL):
--
--   1. Soft-delete model: single `deleted_at`, author-only ("delete for everyone"), NOT the
--      per-party (`client_deleted_at`/`salon_deleted_at`) model the 5-phase roadmap's prose
--      literally suggested ("miroir du patron conversations") — the roadmap text and the
--      canonical schema draft disagreed; single-column was chosen as the simpler, already-drafted
--      option with no documented "delete for me" product requirement at message granularity.
--   2. Message editing (`modifier_message`) is entirely deferred, not part of this migration — no
--      edit-window decision exists anywhere in the locked docs, and no `edited_at`/`is_edited`
--      column exists in the canonical draft. V1 ships send + soft-delete only.
--   3. DEC-016's "booking must still be active" gate (client_staff) is now mirrored for
--      `client_salon`: a message cannot be inserted into an already-open `client_salon` thread
--      once its salon becomes soft-deleted after the thread was opened. ADR residual #3 explicitly
--      left this "non tranché, à décider explicitement à la conception RLS de Migration 2" — it is
--      decided here, symmetric with DEC-016, same idiom as invariant 7 / check_conversation_salon_active.
--
-- A fourth gap found in the same pre-write review, NOT a new product decision but a mechanical
-- application of two already-LOCKED precedents to a policy the canonical draft simply never
-- updated to match (same class of omission as DEC-022/023 on `conversations`, fixed the same way
-- without re-asking): `messages_recipient_mark_read` in the canonical draft (1) omitted the
-- `is_active`/`deleted_at` filter on `staff_id IN (...)` (DEC-022's own rule, stated in that
-- migration's protective comment as applying to "messages_participant_select (Migration 2) —
-- that draft must be written with this filter from the start"), and (2) never let owner/manager
-- mark a `client_salon` message read at all (DEC-023's shared-inbox precedent implies owner/manager
-- need read+write parity on `client_salon`, not read-only supervision — mark-read is a write).
-- Both are fixed here, in the initial write, never unfiltered-then-patched.
--
-- A fifth issue found by adversarial review of THIS file's own design, not the ADR's: a bare
-- `sender_id = auth.uid()` UPDATE policy (needed for soft-delete) has no column-level restriction
-- of its own (Postgres RLS policies OR their WITH CHECK clauses together when several permissive
-- policies apply to the same command — one policy's trivial WITH CHECK does not constrain columns
-- a *different* applicable policy would have restricted). This is exactly the DEC-021 class of gap
-- (row-reachability without column-level enforcement) already fixed once for `conversations` via
-- `protect_conversation_columns` — `protect_message_columns` below is the same mechanism, applied
-- to `messages` from its first line of SQL rather than discovered later as a second finalisation
-- review. It also closes a second, smaller gap found while writing it: `read_at` must never be
-- trusted verbatim from an authenticated caller (a recipient could otherwise rewrite the timestamp
-- on an already-read message without ever going through a genuine unread->read transition) — it is
-- frozen to OLD and only ever advanced by the trigger itself, the same "dedicated system writer"
-- posture already used for `users.email_verified` (`sync_email_verified`,
-- 20260623120000_users_schema_rls_hardening.sql).
--
-- Deliberately NOT in this migration (Rule 8 — one migration, its named decisions, nothing else):
--   - `message_reports` (Migration 3) — no table, no FK, no reference to it anywhere below.
--   - Any Edge Function (Phase 2) — create-conversation/send-message/toggle-conversation-block/etc.
--     are not touched; the RLS below is the *base* guarantee those functions build on, per the
--     ADR's own "who guarantees what" table, not a duplicate of function-level logic.
--   - Message editing, `edited_at`/`is_edited` — explicitly deferred (decision 2 above).
--   - Any Flutter code, any screen.
--
-- Proof set (recon against hhdkjfpgaklhrhfoxlhj, read-only, before this file was written):
--   - `to_regclass('public.messages')` = NULL (table does not exist yet).
--   - `conversations` live columns/policies/triggers match Migration 1 + 1.5 exactly (23/23 cols,
--     6 policies incl. DEC-022/023 fixes, 3 triggers incl. trg_protect_conversation_columns).
--   - `supabase_realtime` publication currently = {bookings, notification_logs,
--     owner_journey_progress, proxipay_sessions, services, staff_profiles} — neither
--     `conversations` nor `messages`, confirming ADR §D.8 residual #5 is still open.
--   - `has_role(_uid, _role, _salon_id DEFAULT NULL)` SQL/STABLE/SECURITY INVOKER, scoped by
--     `u.salon_id = _salon_id` — safe to reuse verbatim, no cross-salon leak by construction.
--   - `bookings_status_check` = {pending_payment, confirmed, in_progress, completed, cancelled,
--     no_show} — DEC-016's `NOT IN ('cancelled','no_show')` idiom matches the live CHECK exactly,
--     same idiom already in production at `20260623240000_bookings_schema.sql:95` and
--     `bookings_practitioner_id` staff-removal guard.
--   - `check_conversation_salon_active()` (invariant 7, DEC-006) confirms the exact idiom mirrored
--     below for the new client_salon send-time gate: `EXISTS (SELECT 1 FROM salons WHERE id = ...
--     AND deleted_at IS NOT NULL)`.
--   - `update_updated_at()` is the shared BEFORE UPDATE function already used by
--     `conversations_updated_at` — reused verbatim for `messages_updated_at`, not reinvented.

-- ---------------------------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------------------------
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id),
  sender_id UUID NOT NULL REFERENCES public.users(id),
  client_message_id UUID NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN (
    'text','image','gif','promotion','booking_confirmation'
  )),
  body TEXT,
  attachment JSONB,
  status TEXT NOT NULL CHECK (status IN ('sent','delivered','read')) DEFAULT 'sent',
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  is_flagged BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT uq_message_client_dedup UNIQUE (conversation_id, sender_id, client_message_id)
);

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_messages_client_message_id ON public.messages(client_message_id);

CREATE TRIGGER messages_updated_at BEFORE UPDATE ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

COMMENT ON TABLE public.messages IS
  'Migration 2. V1 ships send + soft-delete only — no editing (see file header, decision 2). Single deleted_at = author-only "delete for everyone" (decision 1), not per-party.';

-- ---------------------------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------------------------
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- owner/manager clause is deliberately UNCONDITIONAL (not gated by c.type): the ADR's "Note
-- volontaire" (doc canonique, after §5.3) grants owner/manager read-only SUPERVISION over
-- client_staff threads too, not just client_salon — only the WRITE side (insert/mark-read) is
-- type-gated to client_salon. Gating this SELECT policy by type as well would silently remove that
-- supervision; caught by adversarial review of this file's own draft before it was ever tested.
CREATE POLICY "messages_participant_select" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (
          c.client_id = auth.uid()
          OR c.staff_id IN (
                SELECT id FROM public.staff_profiles
                WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL)
          OR public.has_role(auth.uid(), 'owner', c.salon_id)
          OR public.has_role(auth.uid(), 'manager', c.salon_id)
        )
    )
  );

COMMENT ON POLICY "messages_participant_select" ON public.messages IS
  'DEC-022 filter applied from the first write (is_active/deleted_at on the staff_id subquery) — never the unfiltered Migration-1 pattern, per the protective comment already posted on conversations_staff_select. owner/manager clause is unconditional on purpose (read-only supervision over client_staff too, per the canonical doc''s "Note volontaire") — do not gate it by c.type, that would silently remove supervision. Contrast with messages_participant_insert/_recipient_mark_read, which ARE correctly type-gated (write stays staff-only on client_staff).';

-- DEC-016 (client_staff booking-active) + the new symmetric client_salon salon-active gate
-- (decision 3, ADR residual #3) both applied at INSERT time, never at conversation-open time —
-- distinct from create-conversation's anti-spam eligibility (ADR §B.3, never re-merged here).
CREATE POLICY "messages_participant_insert" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND c.blocked_by IS NULL
        AND (
          c.client_id = auth.uid()
          OR (c.type = 'client_staff' AND c.staff_id IN (
                SELECT id FROM public.staff_profiles
                WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL))
          OR (c.type = 'client_salon' AND (
                public.has_role(auth.uid(), 'owner', c.salon_id)
                OR public.has_role(auth.uid(), 'manager', c.salon_id)))
        )
        AND (
          c.type <> 'client_staff'
          OR NOT EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = c.related_booking_id AND b.status IN ('cancelled','no_show')
          )
        )
        AND (
          c.type <> 'client_salon'
          OR NOT EXISTS (
            SELECT 1 FROM public.salons s WHERE s.id = c.salon_id AND s.deleted_at IS NOT NULL
          )
        )
    )
  );

COMMENT ON POLICY "messages_participant_insert" ON public.messages IS
  'DEC-016 (client_staff: bookings.status NOT IN (cancelled,no_show), read at send time not open time) + decision 3 (client_salon: salons.deleted_at IS NULL at send time, symmetric with invariant 7/DEC-006 but re-checked on every send, not just at open) + DEC-022 filter on staff_id. Each gate is unconditionally applied and vacuously true for the other conversation type — never a deduced ELSE branch (ADR §B.2).';

-- Non-sender participant marks a message read. DEC-022 filter + DEC-023-consistent owner/manager
-- parity for client_salon (the canonical draft's mark-read clause only had client_id/staff_id —
-- under chk_staff_type, staff_id IS NULL for client_salon, so owner/manager could never mark a
-- client_salon message read at all; fixed here, in the first write, same class of gap as DEC-023).
-- Column-level enforcement (which columns may actually change, and that read_at is never a client
-- value) is trg_protect_message_columns below — this WITH CHECK only proves the target value.
CREATE POLICY "messages_recipient_mark_read" ON public.messages
  FOR UPDATE USING (
    sender_id <> auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND (
          c.client_id = auth.uid()
          OR (c.type = 'client_staff' AND c.staff_id IN (
                SELECT id FROM public.staff_profiles
                WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL))
          OR (c.type = 'client_salon' AND (
                public.has_role(auth.uid(), 'owner', c.salon_id)
                OR public.has_role(auth.uid(), 'manager', c.salon_id)))
        )
    )
  )
  WITH CHECK (status = 'read');

COMMENT ON POLICY "messages_recipient_mark_read" ON public.messages IS
  'DEC-022 filter + owner/manager parity for client_salon added in the first write (canonical draft omitted both — see file header, finding 4). read_at is never taken from this policy''s WITH CHECK; trg_protect_message_columns overwrites it server-side.';

-- Author soft-delete (decision 1/2: single deleted_at, delete-for-everyone, no editing). Row-level
-- only — column-level scope (deleted_at is the only column this identity may actually move) is
-- enforced by trg_protect_message_columns, same split of responsibility as DEC-013 on conversations.
CREATE POLICY "messages_sender_soft_delete" ON public.messages
  FOR UPDATE USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

COMMENT ON POLICY "messages_sender_soft_delete" ON public.messages IS
  'Row-level only (author owns this row forever, sender_id is IDENTITY_IMMUTABLE post-insert). Does not by itself restrict which columns move — trg_protect_message_columns is the actual column-level guard, deliberately, same split as protect_conversation_columns/DEC-013.';

-- ---------------------------------------------------------------------------------------------
-- Column-level guard — protect_message_columns (closes the 5th finding, file header)
-- ---------------------------------------------------------------------------------------------
-- Partition of all 14 messages columns into categories, default-deny, same discipline as
-- protect_conversation_columns (DEC-013): every branch is a positive check, a final to_jsonb()
-- diff rejects any changed column named in no branch (including a future column a migration
-- forgets to categorize here). No `nested`/pg_trigger_depth() guard is needed here (unlike
-- conversations): no trigger on `messages` performs an internal UPDATE on `messages` itself — the
-- counters triggers below write to `conversations`, not back onto `messages`.
CREATE OR REPLACE FUNCTION public.protect_message_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  is_sender    BOOLEAN := auth.uid() = OLD.sender_id;
  is_recipient BOOLEAN := auth.uid() IS DISTINCT FROM OLD.sender_id AND EXISTS (
                  SELECT 1 FROM public.conversations c
                  WHERE c.id = OLD.conversation_id
                    AND (
                      c.client_id = auth.uid()
                      OR (c.type = 'client_staff' AND c.staff_id IN (
                            SELECT id FROM public.staff_profiles
                            WHERE user_id = auth.uid() AND is_active = true AND deleted_at IS NULL))
                      OR (c.type = 'client_salon' AND (
                            public.has_role(auth.uid(), 'owner', c.salon_id)
                            OR public.has_role(auth.uid(), 'manager', c.salon_id)))
                    )
                );
  is_system    BOOLEAN := COALESCE(auth.role() <> 'authenticated', true); -- see conversations' finding, same fix
  drift_keys   TEXT[];
BEGIN
  -- read_at is never trusted verbatim from an authenticated caller: frozen to OLD before anything
  -- below inspects it, then advanced exactly once, by this function itself, on a genuine
  -- unread->read transition (see the C' branch). Prevents a recipient re-sending status='read' on
  -- an already-read message from rewriting its read_at to an arbitrary value.
  IF NOT is_system THEN
    NEW.read_at := OLD.read_at;
  END IF;

  -- A — IDENTITY_IMMUTABLE: no role exception at all, ever (post-INSERT) — same posture as
  -- protect_conversation_columns Category A (blocks service_role too).
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.conversation_id IS DISTINCT FROM OLD.conversation_id
     OR NEW.sender_id IS DISTINCT FROM OLD.sender_id
     OR NEW.client_message_id IS DISTINCT FROM OLD.client_message_id
     OR NEW.kind IS DISTINCT FROM OLD.kind
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'messages: identity columns are immutable (id/conversation_id/sender_id/client_message_id/kind/created_at)';
  END IF;

  -- B — CONTENT, deliberately closed for V1 (decision 2: editing deferred). Not merged into
  -- Category A: this is a temporary product choice, not a structural invariant. A future
  -- edit-window migration adds a positive branch here; it must not need to touch Category A.
  IF NEW.body IS DISTINCT FROM OLD.body OR NEW.attachment IS DISTINCT FROM OLD.attachment THEN
    RAISE EXCEPTION 'messages: body/attachment editing is not implemented in V1 (deferred, see migration header)';
  END IF;

  -- C — SYSTEM_STATE (delivered_at, is_flagged): service_role only. No writer exists for either
  -- in this migration (delivered_at is Phase 2/push-delivery; is_flagged is Migration 3/reports) —
  -- both are pre-declared columns with no path yet, not oversights.
  IF (NEW.delivered_at IS DISTINCT FROM OLD.delivered_at OR NEW.is_flagged IS DISTINCT FROM OLD.is_flagged)
     AND NOT is_system THEN
    RAISE EXCEPTION 'messages: delivered_at/is_flagged are system-managed only';
  END IF;

  -- C' — RECIPIENT_MARK_READ (status). read_at's own movement is decided below, never by the
  -- client (see the freeze above and the override at the end of this branch).
  IF NEW.status IS DISTINCT FROM OLD.status AND NOT (is_recipient OR is_system) THEN
    RAISE EXCEPTION 'messages: status is writable only by the conversation''s non-sender participant (mark-read) or system';
  END IF;
  IF NEW.status = 'read' AND OLD.status IS DISTINCT FROM 'read' AND NOT is_system THEN
    NEW.read_at := NOW();
  END IF;

  -- D — SENDER_DELETE (deleted_at): the author only, or system (future admin/GDPR flow).
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at AND NOT (is_sender OR is_system) THEN
    RAISE EXCEPTION 'messages: deleted_at is writable only by the message''s author or an administrative/GDPR flow';
  END IF;

  -- Anti-drift net (ADR §A.3 discipline): any changed column absent from every branch above fails
  -- loudly. updated_at (delegated to messages_updated_at, fires first — see ordering proof below)
  -- is deliberately excluded.
  SELECT array_agg(n.key) INTO drift_keys
  FROM jsonb_each(to_jsonb(NEW)) n JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
  WHERE n.value IS DISTINCT FROM o.value
    AND n.key NOT IN (
      'id','conversation_id','sender_id','client_message_id','kind','created_at',
      'body','attachment',
      'delivered_at','is_flagged',
      'status','read_at',
      'deleted_at',
      'updated_at'
    );
  IF drift_keys IS NOT NULL THEN
    RAISE EXCEPTION 'protect_message_columns: uncategorized column(s) % changed — this is schema drift, categorize before allowing this write', drift_keys;
  END IF;

  RETURN NEW;
END; $$;

REVOKE EXECUTE ON FUNCTION public.protect_message_columns() FROM authenticated, anon, public;

CREATE TRIGGER trg_protect_message_columns BEFORE UPDATE ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.protect_message_columns();

-- Ordering proof (mirrors ADR §A.4 for conversations): 'messages_updated_at' < 'trg_protect_message_columns'
-- alphabetically (m < t) — Postgres fires same-event BEFORE UPDATE triggers in name order, so
-- updated_at is already NOW() by the time this function's OLD/NEW snapshot runs, and this function
-- never inspects/touches updated_at (excluded from the drift list above).

COMMENT ON FUNCTION public.protect_message_columns() IS
  'Column-level guard for messages, same discipline as protect_conversation_columns (DEC-013). is_system MUST stay COALESCE(auth.role() <> ''authenticated'', true) — see the long comment on protect_conversation_columns for the two rejected alternatives (bare auth.role(), current_user) and why both are wrong; identical reasoning applies verbatim here, not re-derived. No pg_trigger_depth()/nested guard: nothing on this table performs an internal UPDATE on messages itself (the counters triggers below write to conversations, a different table).';

-- ---------------------------------------------------------------------------------------------
-- DEC-014 — unread counters (SECURITY DEFINER, locked design, ADR §A.4/§F)
-- ---------------------------------------------------------------------------------------------
-- SECURITY DEFINER per the LOCKED design even though DEC-023 (conversations_owner_manager_update_own_state,
-- already live since Migration 1.5) now also gives owner/manager a matching SECURITY-INVOKER path —
-- that closes one of the two original reasons (ADR §A.4's RLS-gap argument), not both, and does not
-- contradict the locked decision (no "preuve formelle d'une contradiction" exists) — implemented
-- exactly as specified, not re-derived. pg_trigger_depth() > 1 is what actually lets the nested
-- UPDATE on conversations pass trg_protect_conversation_columns's Category B check, independent of
-- role — that part of the mechanism is unchanged by DEC-023.
CREATE OR REPLACE FUNCTION public.bump_conversation_on_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  UPDATE public.conversations SET
    last_message_at = NEW.created_at,
    last_message_preview = LEFT(COALESCE(NEW.body, '[' || NEW.kind || ']'), 140),
    client_unread_count = CASE
      WHEN NEW.sender_id <> client_id THEN client_unread_count + 1
      ELSE client_unread_count
    END,
    salon_unread_count = CASE
      WHEN NEW.sender_id = client_id THEN salon_unread_count + 1
      ELSE salon_unread_count
    END,
    client_hidden_at = CASE WHEN NEW.sender_id <> client_id THEN NULL ELSE client_hidden_at END,
    salon_hidden_at = CASE WHEN NEW.sender_id = client_id THEN NULL ELSE salon_hidden_at END,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.bump_conversation_on_message() FROM authenticated, anon, public;

CREATE TRIGGER trg_bump_conversation_on_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.bump_conversation_on_message();

COMMENT ON FUNCTION public.bump_conversation_on_message() IS
  'DEC-014. SECURITY DEFINER per the locked ADR design (§A.4) — the internal UPDATE conversations fires trg_protect_conversation_columns, which lets it through via pg_trigger_depth() > 1 (nested), independent of role or SECURITY DEFINER/INVOKER. Protective comment (ADR finalisation review, Partie B.2, Application 2): the CASE WHEN NEW.sender_id <> client_id THEN client ELSE salon END binary split depends on the 3-branch exhaustiveness of messages_participant_insert (client XOR active assigned staff XOR owner/manager) — any future 4th sender category (e.g. a platform moderator) must revise this trigger first, or it will attribute unread counts to the wrong side.';

CREATE OR REPLACE FUNCTION public.reset_unread_on_read()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.status = 'read' AND OLD.status <> 'read' THEN
    UPDATE public.conversations c SET
      client_unread_count = CASE WHEN NEW.sender_id <> c.client_id
        THEN GREATEST(client_unread_count - 1, 0) ELSE client_unread_count END,
      salon_unread_count = CASE WHEN NEW.sender_id = c.client_id
        THEN GREATEST(salon_unread_count - 1, 0) ELSE salon_unread_count END
    WHERE c.id = NEW.conversation_id;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.reset_unread_on_read() FROM authenticated, anon, public;

CREATE TRIGGER trg_reset_unread_on_read
  AFTER UPDATE OF status ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.reset_unread_on_read();

-- ---------------------------------------------------------------------------------------------
-- Realtime (ADR §D.8 residual #5) — both tables, neither was in the publication before this file.
-- ---------------------------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
