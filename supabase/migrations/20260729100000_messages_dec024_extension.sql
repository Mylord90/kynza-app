-- KYNZA — Messaging, DEC-024 extension — closes residual #7 (ADR "Résidus", additive).
--
-- Governance closed in docs/ADR_MESSAGING_FOUNDATION.md, "Amendement — Extension de portée
-- DEC-024 (chemin d'envoi, préparation Lot 1.2)": DEC-024's irrecoverability principle
-- ("une conversation deleted_at IS NOT NULL est définitivement irrécupérable") was scoped, at
-- the time it was written, only to create-conversation's reopening path. `messages_participant_
-- insert` (20260723180000_messages_schema_migration_2.sql:144-174) never checked
-- `conversations.deleted_at` — proven, not assumed: full re-read of that policy plus an
-- exhaustive search of every trigger/FK/CHECK/other policy/Edge Function on this domain found
-- zero indirect guard (no BEFORE INSERT trigger exists on `messages` at all; the FK on
-- `conversation_id` only requires the row to exist, never checks its state).
--
-- Single change, nothing else: `messages_participant_insert`'s WITH CHECK gains one flat clause,
-- `AND c.deleted_at IS NULL`, at the same level as the existing `c.blocked_by IS NULL` —
-- unconditional, applies to both `client_salon` and `client_staff` alike (unlike the DEC-016/
-- decision-3 clauses, which are each conditioned to one type). No other policy, no other table,
-- no trigger, no column added. `completed` bookings remain deliberately unaffected — DEC-016's
-- own wording already excludes only `cancelled`/`no_show` (ADR §B.3), untouched here.
DROP POLICY IF EXISTS "messages_participant_insert" ON public.messages;

CREATE POLICY "messages_participant_insert" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = messages.conversation_id
        AND c.blocked_by IS NULL
        AND c.deleted_at IS NULL
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
  'DEC-016 (client_staff: bookings.status NOT IN (cancelled,no_show), read at send time not open time) + decision 3 (client_salon: salons.deleted_at IS NULL at send time, symmetric with invariant 7/DEC-006 but re-checked on every send, not just at open) + DEC-022 filter on staff_id + DEC-024 extended (c.deleted_at IS NULL — an administratively-erased conversation can never receive a new message, same irrecoverability principle as create-conversation''s reopening machine, extended here — 20260729100000_messages_dec024_extension.sql). Each gate is unconditionally applied and vacuously true for the other conversation type where relevant — never a deduced ELSE branch (ADR §B.2).';
