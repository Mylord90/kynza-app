-- KYNZA — Phase 1b, Étape 1 — device_tokens (multi-device FCM tokens).
--
-- Closes a real, confirmed-live leak in the single-token design
-- (users.fcm_token): on a salon's shared device, staff A signs out, staff
-- B signs in — the same FCM token gets reissued for B, but nothing ever
-- erased A's row, so notifications meant for A could still land on B's
-- device. Verified directly against production (hhdkjfpgaklhrhfoxlhj):
-- one token was already shared between two real accounts (a client and an
-- owner) before this migration ran.
--
-- No behavior change in this step: nothing reads or writes this table yet
-- (notification_service.dart / send-notification/index.ts are untouched
-- here — that's Étape 2).

CREATE TABLE public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  token TEXT NOT NULL,
  platform TEXT CHECK (platform IN ('android','ios')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- A token belongs to a device, never to two accounts at once — UNIQUE on
-- the token alone, not (user_id, token): the latter would let A's and B's
-- rows coexist for the same physical token, which is the leak itself.
-- Partial on deleted_at IS NULL: a soft-deleted token must never block its
-- own reissue later.
CREATE UNIQUE INDEX idx_device_tokens_token_unique
  ON public.device_tokens(token) WHERE deleted_at IS NULL;

CREATE INDEX idx_device_tokens_user
  ON public.device_tokens(user_id) WHERE deleted_at IS NULL;

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_own_select" ON public.device_tokens
  FOR SELECT USING (user_id = auth.uid());

-- No INSERT policy: all initial writes go through upsert_device_token()
-- below, which handles both the fresh-token and the reassignment case
-- uniformly — RLS alone cannot arbitrate reassignment (proven empirically:
-- a direct cross-account UPDATE raises 42501, RLS "USING expression"
-- violation).
--
-- UPDATE policy scoped to one's own row — used for sign-out's soft-delete,
-- which never touches anyone else's row, a case ordinary RLS already
-- handles correctly without needing any bypass. Note for whoever touches
-- idx_device_tokens_token_unique later: this same policy technically lets
-- a user "resurrect" their own soft-deleted row (deleted_at = NULL) — it's
-- the partial unique index, not this policy, that bounds that: resurrection
-- collides and is rejected if someone else has since claimed the same
-- token as an active row.
CREATE POLICY "device_tokens_own_update" ON public.device_tokens
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- No DELETE policy — soft delete only.

CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON public.device_tokens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Sole write path for a new or reassigned token. user_id is unforgeable by
-- construction — always auth.uid() internally, never a parameter, never
-- EXCLUDED.user_id, regardless of what a caller passes. Targeting is a
-- different property: this is a "Shape B" claim-by-possession mechanism
-- (docs/adr/0002-two-shapes-of-atomic-claim.md, same as validate-qr) —
-- whoever presents a given token claims the row for that token, because no
-- server can verify a caller's device actually owns the FCM token it
-- presents. That's inherent to token-based device registration, not a gap
-- this function introduces or could close.
--
-- Proven empirically (not assumed) that this bypasses RLS as intended:
-- under ENABLE ROW LEVEL SECURITY (this repo's only convention — grepped,
-- 80 uses, zero FORCE anywhere), the function's real owner after
-- `supabase db push` is the `postgres` role, which carries rolbypassrls =
-- true as a direct role attribute (confirmed via pg_roles) — an
-- unconditional bypass, independent of ENABLE/FORCE.
--
-- created_at is reset on reassignment: it should read "since when has the
-- current owner had this token," not linger as the previous owner's
-- registration date once the row changes hands.
--
-- Accumulation of soft-deleted rows on repeated sign-out/sign-in cycles on
-- the same device is accepted, not solved here: negligible at current
-- scale, and this class of cleanup belongs with the already-deferred dead
-- token pruning ticket (blocked on fixing _shared/fcm.ts to actually read
-- FCM's response), not a one-off fix bolted on here.
CREATE OR REPLACE FUNCTION public.upsert_device_token(_token TEXT, _platform TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO public.device_tokens (user_id, token, platform)
  VALUES (auth.uid(), _token, _platform)
  ON CONFLICT (token) WHERE deleted_at IS NULL
  DO UPDATE SET
    user_id = auth.uid(),
    platform = _platform,
    created_at = NOW();
    -- updated_at is NOT set here — device_tokens_updated_at (above)
    -- already does it for every UPDATE, including this ON CONFLICT DO
    -- UPDATE path; setting it twice from two sources was the bug to avoid.
END;
$$;

REVOKE EXECUTE ON FUNCTION public.upsert_device_token(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_device_token(TEXT, TEXT) TO authenticated;

-- Deterministic backfill: the most recently active account wins a shared
-- token (confirmed live before this migration: one token shared between a
-- client and an owner). DISTINCT ON removes the arbitrary-winner risk a
-- plain ON CONFLICT DO NOTHING would have had.
INSERT INTO public.device_tokens (user_id, token, platform)
SELECT DISTINCT ON (fcm_token) id, fcm_token, NULL
FROM public.users
WHERE fcm_token IS NOT NULL AND deleted_at IS NULL
ORDER BY fcm_token, updated_at DESC
ON CONFLICT (token) WHERE deleted_at IS NULL DO NOTHING;
