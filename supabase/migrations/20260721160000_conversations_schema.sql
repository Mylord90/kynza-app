-- KYNZA — Messaging V1, Migration 1/4 — `conversations`.
--
-- Native in-app messaging (docs/KYNZA_MESSAGING_ARCHITECTURE.md), first of 4 tables
-- (conversations -> messages -> message_reports -> device_tokens raccord), one table per
-- migration per commit (Rule 8). `messages`/`message_reports` do not exist yet and are not
-- created here — nothing in this repo reads or writes `conversations` yet, so this migration
-- is purely additive and has no live caller to break.
--
-- Ten locked decisions this migration implements exactly (reviewed and GO'd 2026-07-21):
--
-- 1) FK simple `related_booking_id -> bookings(id)` kept ALONGSIDE the composite FK (2).
--    Under MATCH SIMPLE (Postgres' default), a composite FK is a no-op the moment any one
--    referencing column is NULL. For `type = 'client_salon'`, `staff_id IS NULL` is enforced
--    by `chk_staff_type` below, which makes the composite FK a no-op on that branch BY
--    CONSTRUCTION — so only this simple FK guarantees `related_booking_id`, when set, points
--    to a real booking on `client_salon` rows. Empirically proven (scratch review,
--    2026-07-21): without this FK, a `client_salon` row with a nonexistent
--    `related_booking_id` is ACCEPTED; with it, REJECTED (23503). Existing precedent for the
--    same "optional justification reference" shape: `notification_logs.related_booking_id`
--    (20260624060000_notifications_schema.sql:69), also unconditioned.
--
-- 2) FK composite `(related_booking_id, client_id, staff_id, salon_id) ->
--    bookings(id, client_id, practitioner_id, salon_id)`. Locks the full identity tuple of a
--    `client_staff` conversation against the booking cited as justification. Requires the
--    additive UNIQUE on `bookings` (3) as its backing constraint — Postgres requires a
--    composite FK's referenced columns to be covered exactly by a UNIQUE/PK on the parent.
--
-- 3) Additive `UNIQUE(id, client_id, practitioner_id, salon_id)` on `bookings` — the only
--    change to an existing table in this migration (Maintenance Mode: declarative, additive,
--    no trigger, no data risk: `bookings.id` already PK, so any superset of columns
--    including `id` is trivially already unique for every existing row).
--
-- 4) `chk_staff_type` — biconditional CHECK: `type = 'client_salon' <=> staff_id IS NULL`.
--    Makes the composite FK's MATCH SIMPLE no-op on `client_salon` a proven consequence of
--    the schema, not an assumption: the database physically refuses any `client_salon` row
--    with `staff_id` set, on every write path, `service_role` included.
--
-- 5) `chk_staff_requires_booking` (invariant 1) — `client_staff` requires
--    `related_booking_id IS NOT NULL`. Invariant 6 (staff<->salon consistency) is inherited
--    from `bookings` via the composite FK (2), never re-implemented independently here.
--
-- 6) Trigger invariant 7 — `BEFORE INSERT` rejects any conversation opened against a
--    soft-deleted salon (`salons.deleted_at IS NOT NULL`). Unconditional: no `auth.role()`
--    guard. A guard would exempt `service_role` — the exact role `create-conversation` (a
--    future Edge Function) runs as — and defeat invariant 9 below. Skeleton
--    (`SECURITY DEFINER` + `search_path` + `REVOKE`) follows `protect_user_columns`
--    (20260623120000_users_schema_rls_hardening.sql) minus its `auth.role()` guard; the
--    unconditional shape itself already has a live precedent:
--    `prevent_staff_removal_with_future_bookings` (20260623240000_bookings_schema.sql:87,
--    103-106) — `SECURITY DEFINER`, `search_path` pinned, zero role guard, already in
--    production.
--
-- 7) Invariant 9 — no bypass, `service_role` included. RLS `WITH CHECK` is bypassed by any
--    `BYPASSRLS` role; table constraints and triggers never are. Proven empirically
--    (2026-07-21): the invariant-7 trigger rejects an INSERT against a soft-deleted salon
--    both as `postgres` and as `service_role` (both `rolbypassrls = true`, confirmed via
--    `pg_roles`).
--
-- 8) Anti-duplicate unique indexes: TOTAL uniqueness, never `AND deleted_at IS NULL`.
--    `conversations.deleted_at` (global) has no writer — reserved for a future
--    administrative/GDPR erasure, never set by a user action (per-party removal uses
--    `client_deleted_at`/`salon_deleted_at`, not modeled by these indexes). The product model
--    is reopen-not-recreate: a second row for the same pair must stay a duplicate even after a
--    global `deleted_at` is eventually set. Do NOT copy the partial pattern of
--    `idx_device_tokens_token_unique` (20260717140000_device_tokens.sql) — that table has a
--    real revoke/reissue lifecycle; this one does not.
--
-- 9) `NO ACTION` (no `ON DELETE`/`ON UPDATE` clause) on every FK — aligned with 100% of the
--    soft-delete-only domain's existing FKs (`bookings.salon_id/client_id/practitioner_id`,
--    `notification_logs.related_booking_id`). No `CASCADE`: a physical delete of a referenced
--    row must surface as an error, never cascade silently.
--
--    GDPR TICKET (named, not resolved here): `public.users.id REFERENCES auth.users(id) ON
--    DELETE CASCADE` (20260622182007_foundation.sql:37) is the one exception in this repo. The
--    day a GDPR erasure flow deletes an `auth.users` row, its cascade into `public.users` will
--    be BLOCKED by this table's `NO ACTION` FKs (and later `messages`') until that user's
--    conversations (and future messages) are purged first. No GDPR erasure flow exists yet in
--    this repo — this must be a prerequisite step of whichever flow is built first.
--
-- 10) Naming: repo convention has `chk_`/`uq_`/`idx_`/`trg_` prefixes and zero precedent for a
--     named simple FK (all existing simple FKs are inline, auto-named `<table>_<col>_fkey` by
--     Postgres — confirmed empirically). The composite FK MUST be named (multi-column FKs
--     require `CONSTRAINT` syntax). Both FKs are named explicitly here
--     (`fk_conversations_related_booking_simple`/`_composite`) — a deliberate, minimal
--     deviation from "let Postgres auto-name," chosen only so the two FKs central to decision
--     1/2 carry symmetrical, self-documenting names that `COMMENT ON CONSTRAINT` can target
--     predictably. No other new naming convention is introduced.
--
-- SCOPE GAP, FLAGGED NOT RESOLVED: `docs/KYNZA_MESSAGING_ARCHITECTURE.md` §5.2 also specifies
-- a `protect_conversation_columns` trigger (BEFORE UPDATE, freezes the other party's
-- pinned/archived/hidden/deleted/blocked/counter columns). It is NOT included in this
-- migration: the 10 locked decisions above do not name it, and as literally specified in that
-- doc it would collide with the future `bump_conversation_on_message` trigger (Migration 2 /
-- messages) — both are triggers on/around `conversations`, and the column-protection trigger's
-- unconditional freeze of `last_message_at`/unread counters would silently undo the bump
-- trigger's own legitimate writes. Shipping it unreconciled would be worse than omitting it.
-- CONSEQUENCE: the UPDATE policies below (client/staff "own state") do not restrict which
-- columns may change — a client can currently mutate `salon_pinned`/`blocked_by`/
-- `last_message_at`/unread counts via a direct UPDATE. This must be decided explicitly
-- (trigger, or WITH CHECK column-freezing like `users_self_update_safe`,
-- 20260622182007_foundation.sql:84-97) before Migration 2, not silently left open.

-- ---------------------------------------------------------------------------
-- (3) Additive UNIQUE on bookings — must precede the composite FK below.
-- ---------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD CONSTRAINT uq_booking_tuple UNIQUE (id, client_id, practitioner_id, salon_id);

-- ---------------------------------------------------------------------------
-- conversations
-- ---------------------------------------------------------------------------
CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  type TEXT NOT NULL CHECK (type IN ('client_salon','client_staff')),
  client_id UUID NOT NULL REFERENCES public.users(id),
  staff_id UUID REFERENCES public.staff_profiles(id),
  related_booking_id UUID,

  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  client_unread_count INT NOT NULL DEFAULT 0,
  salon_unread_count INT NOT NULL DEFAULT 0,

  client_pinned BOOLEAN NOT NULL DEFAULT false,
  salon_pinned BOOLEAN NOT NULL DEFAULT false,
  client_hidden_at TIMESTAMPTZ,
  salon_hidden_at TIMESTAMPTZ,
  client_deleted_at TIMESTAMPTZ,
  salon_deleted_at TIMESTAMPTZ,
  client_archived BOOLEAN NOT NULL DEFAULT false,
  salon_archived BOOLEAN NOT NULL DEFAULT false,
  blocked_by UUID REFERENCES public.users(id),
  blocked_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,

  CONSTRAINT chk_staff_type CHECK (
    (type = 'client_salon' AND staff_id IS NULL) OR
    (type = 'client_staff' AND staff_id IS NOT NULL)
  ),
  CONSTRAINT chk_staff_requires_booking CHECK (
    type = 'client_salon' OR (type = 'client_staff' AND related_booking_id IS NOT NULL)
  ),
  CONSTRAINT fk_conversations_related_booking_simple
    FOREIGN KEY (related_booking_id) REFERENCES public.bookings(id),
  CONSTRAINT fk_conversations_related_booking_composite
    FOREIGN KEY (related_booking_id, client_id, staff_id, salon_id)
    REFERENCES public.bookings(id, client_id, practitioner_id, salon_id)
);

CREATE UNIQUE INDEX uq_conversations_client_salon
  ON public.conversations(salon_id, client_id) WHERE type = 'client_salon';
CREATE UNIQUE INDEX uq_conversations_client_staff
  ON public.conversations(staff_id, client_id) WHERE type = 'client_staff';
CREATE INDEX idx_conversations_client ON public.conversations(client_id, last_message_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_conversations_staff ON public.conversations(staff_id, last_message_at DESC)
  WHERE deleted_at IS NULL AND staff_id IS NOT NULL;
CREATE INDEX idx_conversations_salon ON public.conversations(salon_id, last_message_at DESC)
  WHERE deleted_at IS NULL;

-- Invariant 7 — unconditional, no auth.role() guard (see decision 6/7 above).
CREATE OR REPLACE FUNCTION public.check_conversation_salon_active()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.salons WHERE id = NEW.salon_id AND deleted_at IS NOT NULL) THEN
    RAISE EXCEPTION 'conversations.salon_id % is soft-deleted (invariant 7): cannot open a conversation against an inactive salon', NEW.salon_id;
  END IF;
  RETURN NEW;
END; $$;

REVOKE EXECUTE ON FUNCTION public.check_conversation_salon_active() FROM authenticated, anon, public;

CREATE TRIGGER trg_check_conversation_salon_active
  BEFORE INSERT ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.check_conversation_salon_active();

CREATE TRIGGER conversations_updated_at BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversations_client_select" ON public.conversations
  FOR SELECT USING (client_id = auth.uid());

CREATE POLICY "conversations_staff_select" ON public.conversations
  FOR SELECT USING (
    staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "conversations_owner_manager_select" ON public.conversations
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "conversations_client_update_own_state" ON public.conversations
  FOR UPDATE USING (client_id = auth.uid()) WITH CHECK (client_id = auth.uid());

CREATE POLICY "conversations_staff_update_own_state" ON public.conversations
  FOR UPDATE USING (staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid()))
  WITH CHECK (staff_id IN (SELECT id FROM public.staff_profiles WHERE user_id = auth.uid()));

-- No INSERT policy for `authenticated`: creation only via the future create-conversation
-- Edge Function (service_role), which applies the anti-spam eligibility rule (bookings
-- history). No DELETE policy: soft delete only.

COMMENT ON CONSTRAINT fk_conversations_related_booking_simple ON public.conversations IS
  'DO NOT DROP. Protects the client_salon branch, where the composite FK is a MATCH SIMPLE no-op (staff_id IS NULL, enforced by chk_staff_type). Without this FK, a related_booking_id pointing to a nonexistent booking would be accepted on client_salon rows. Proven empirically: review 2026-07-21, scratch scratch_conv_review.';

COMMENT ON CONSTRAINT fk_conversations_related_booking_composite ON public.conversations IS
  'Does not replace fk_conversations_related_booking_simple (see its comment). Locks (client_id, staff_id, salon_id) against the cited booking only when staff_id is set (client_staff).';

COMMENT ON INDEX uq_conversations_client_salon IS
  'TOTAL uniqueness, deliberate: never add AND deleted_at IS NULL. Global deleted_at is reserved for a future administrative/GDPR erasure, never written by a user action. Product model is reopen, not recreate. Do not copy the partial pattern of idx_device_tokens_token_unique (20260717140000_device_tokens.sql) — that table has a real revoke/reissue lifecycle; this one does not.';

COMMENT ON INDEX uq_conversations_client_staff IS
  'See uq_conversations_client_salon — same rule, same reason.';

COMMENT ON FUNCTION public.check_conversation_salon_active() IS
  'Invariant 7, unconditional by construction. NEVER add an auth.role() = ''authenticated'' guard: it would exempt service_role and break invariant 9 (the future create-conversation Edge Function runs as service_role). Modeled on prevent_staff_removal_with_future_bookings (20260623240000_bookings_schema.sql).';

COMMENT ON CONSTRAINT chk_staff_type ON public.conversations IS
  'Biconditional: type and staff_id determine each other. Makes the composite FK''s MATCH SIMPLE no-op on client_salon a proven consequence of the schema, not an assumption.';

COMMENT ON CONSTRAINT chk_staff_requires_booking ON public.conversations IS
  'Invariant 1. Invariant 6 (staff<->salon consistency) is inherited from bookings via the composite FK, never re-implemented independently here.';
