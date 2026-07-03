-- DRAFT — reviewed but NOT applied to the remote project as part of the
-- Enterprise Hardening & Production Readiness pass, Phase 3 (Legal Center
-- Infrastructure). This repo has no local Supabase/Docker stack;
-- `supabase db push` hits the live project (hhdkjfpgaklhrhfoxlhj) directly.
-- Apply manually after review, per the pass's Rule 8 (no draft migration
-- touches the live remote without explicit per-file approval).
--
-- Adds the full Legal Center data model: documents + versioned content,
-- per-user acceptance ledger, per-user consent toggles, and data-deletion
-- requests. Purely additive — touches zero existing table/column/policy.
--
-- Design notes (documented, not silently assumed):
-- 1. `legal_documents.current_version_id` and `legal_document_versions.document_id`
--    are mutually referential, so `current_version_id`'s FK constraint is added
--    via ALTER TABLE after both tables exist (standard circular-FK resolution).
-- 2. A document can have multiple *locale* variants of the same version
--    (e.g. fr + en of "v1") — `current_version_id` points at the canonical
--    (fr) row for display/admin convenience, but the actual freshness check
--    in `LegalAcceptanceService` compares `version_number` per `document_id`,
--    not raw row-id equality, so it stays correct regardless of which
--    locale row a given user actually accepted.
-- 3. `user_legal_acceptances` intentionally has NO `deleted_at` and NO
--    `updated_at` — it's an immutable audit ledger (a user's past acceptance
--    of a specific document version is a permanent legal fact, never
--    edited or soft-deleted), matching this codebase's existing precedent
--    for `activity_logs`, `entity_versions`, and `loyalty_stamp_logs`
--    (docs/DATABASE_ARCHITECTURE.md §4). `legal_consent_settings` and
--    `data_deletion_requests` DO get `deleted_at` even though the original
--    brief's column list omitted it, per this pass's Rule 4 (every new
--    table gets soft-delete) — that list also omits created_at/updated_at
--    for every table, so it's clearly non-exhaustive shorthand, not a
--    literal exclusion.

-- 1. legal_documents — one row per legal document *type* (privacy policy,
-- ToS, etc.), pointing at whichever version is currently in force.
CREATE TABLE IF NOT EXISTS public.legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN (
    'privacy_policy', 'terms_of_service', 'cookie_policy',
    'acceptable_use_policy', 'refund_policy', 'community_guidelines',
    'data_deletion_policy', 'support_policy', 'legal_notices'
  )),
  current_version_id UUID, -- FK added below, after legal_document_versions exists
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_legal_documents_active
  ON public.legal_documents (is_active) WHERE deleted_at IS NULL;

ALTER TABLE public.legal_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "legal_documents_public_select" ON public.legal_documents
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);
-- No INSERT/UPDATE/DELETE policy for `authenticated` — legal copy is
-- service_role/Edge-Function managed only, mirrors the existing
-- categories / notification_templates pattern.

CREATE TRIGGER legal_documents_updated_at
  BEFORE UPDATE ON public.legal_documents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 2. legal_document_versions — full version history, retained forever.
-- `is_current` flips on publish; old rows are never overwritten or deleted.
CREATE TABLE IF NOT EXISTS public.legal_document_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.legal_documents(id) ON DELETE CASCADE,
  version_number INT NOT NULL CHECK (version_number > 0),
  locale TEXT NOT NULL DEFAULT 'fr' CHECK (locale IN ('fr', 'en')),
  content_markdown TEXT NOT NULL,
  published_at TIMESTAMPTZ,
  is_current BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (document_id, version_number, locale)
);

ALTER TABLE public.legal_documents
  ADD CONSTRAINT legal_documents_current_version_fk
  FOREIGN KEY (current_version_id) REFERENCES public.legal_document_versions(id);

CREATE INDEX IF NOT EXISTS idx_legal_document_versions_document
  ON public.legal_document_versions (document_id, locale) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_legal_document_versions_current
  ON public.legal_document_versions (document_id, is_current) WHERE deleted_at IS NULL;

ALTER TABLE public.legal_document_versions ENABLE ROW LEVEL SECURITY;

-- Any non-deleted version of an active document is publicly readable, not
-- just the current one — PolicyVersionHistoryScreen needs to show prior
-- versions too, and published legal text has no confidentiality concern.
-- (The brief's "users can only read active/current versions" is satisfied
-- for the *gating* check, which is done in application code by comparing
-- version_number, not by narrowing this SELECT policy to is_current rows.)
CREATE POLICY "legal_document_versions_public_select" ON public.legal_document_versions
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.legal_documents d
      WHERE d.id = legal_document_versions.document_id
        AND d.is_active AND d.deleted_at IS NULL
    )
  );

CREATE TRIGGER legal_document_versions_updated_at
  BEFORE UPDATE ON public.legal_document_versions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 3. user_legal_acceptances — immutable per-user acceptance ledger.
CREATE TABLE IF NOT EXISTS public.user_legal_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  document_version_id UUID NOT NULL REFERENCES public.legal_document_versions(id),
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ip_hash TEXT, -- SHA-256 of the client IP, never the raw IP (privacy-by-design)
  app_version TEXT,
  platform TEXT CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, document_version_id)
);

CREATE INDEX IF NOT EXISTS idx_user_legal_acceptances_user
  ON public.user_legal_acceptances (user_id, accepted_at DESC);

ALTER TABLE public.user_legal_acceptances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_legal_acceptances_own_select" ON public.user_legal_acceptances
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "user_legal_acceptances_own_insert" ON public.user_legal_acceptances
  FOR INSERT WITH CHECK (user_id = auth.uid());
-- No UPDATE/DELETE policy for anyone but service_role — the ledger is
-- append-only by design, matching activity_logs.

-- 4. legal_consent_settings — one row per (user, consent_type), toggled
-- via `granted`; never a reason to hard-delete a consent record, but
-- `deleted_at` is included per Rule 4.
CREATE TABLE IF NOT EXISTS public.legal_consent_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL CHECK (consent_type IN (
    'marketing_emails', 'analytics', 'push_notifications', 'data_processing'
  )),
  granted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (user_id, consent_type)
);

CREATE INDEX IF NOT EXISTS idx_legal_consent_settings_user
  ON public.legal_consent_settings (user_id) WHERE deleted_at IS NULL;

ALTER TABLE public.legal_consent_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "legal_consent_settings_own_manage" ON public.legal_consent_settings
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE TRIGGER legal_consent_settings_updated_at
  BEFORE UPDATE ON public.legal_consent_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 5. data_deletion_requests — a user's request to delete their account/data.
-- Status transitions (in_review/completed/rejected) are service_role/admin
-- only — a user must never be able to self-approve their own request.
CREATE TABLE IF NOT EXISTS public.data_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'in_review', 'completed', 'rejected'
  )),
  processed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_data_deletion_requests_user
  ON public.data_deletion_requests (user_id) WHERE deleted_at IS NULL;

ALTER TABLE public.data_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "data_deletion_requests_own_select" ON public.data_deletion_requests
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "data_deletion_requests_own_insert" ON public.data_deletion_requests
  FOR INSERT WITH CHECK (user_id = auth.uid());
-- No UPDATE policy for `authenticated` — only service_role processes a
-- request's status, enforced structurally (policy omission), same pattern
-- as proxipay_sessions' write-lock in docs/DATABASE_ARCHITECTURE.md §3.4.

-- 6. Seed the 9 document types with a single fr+en placeholder version each,
-- explicitly marked as requiring legal review before this ships to real
-- users. No document is left without at least one version, so the app
-- never has to handle a "document exists but has zero versions" state.
DO $$
DECLARE
  v_doc_id UUID;
  v_version_id UUID;
  v_slug TEXT;
  v_type TEXT;
BEGIN
  FOR v_slug, v_type IN
    SELECT * FROM (VALUES
      ('privacy-policy', 'privacy_policy'),
      ('terms-of-service', 'terms_of_service'),
      ('cookie-policy', 'cookie_policy'),
      ('acceptable-use-policy', 'acceptable_use_policy'),
      ('refund-policy', 'refund_policy'),
      ('community-guidelines', 'community_guidelines'),
      ('data-deletion-policy', 'data_deletion_policy'),
      ('support-policy', 'support_policy'),
      ('legal-notices', 'legal_notices')
    ) AS t(slug, type)
  LOOP
    INSERT INTO public.legal_documents (slug, type)
    VALUES (v_slug, v_type)
    ON CONFLICT (slug) DO NOTHING
    RETURNING id INTO v_doc_id;

    IF v_doc_id IS NULL THEN
      SELECT id INTO v_doc_id FROM public.legal_documents WHERE slug = v_slug;
      CONTINUE; -- already seeded in a prior run, don't duplicate versions
    END IF;

    INSERT INTO public.legal_document_versions
      (document_id, version_number, locale, content_markdown, published_at, is_current)
    VALUES
      (v_doc_id, 1, 'fr',
       '⚠️ PLACEHOLDER — legal review required. Contenu de démonstration pour "' || v_slug || '".',
       NOW(), true)
    RETURNING id INTO v_version_id;

    INSERT INTO public.legal_document_versions
      (document_id, version_number, locale, content_markdown, published_at, is_current)
    VALUES
      (v_doc_id, 1, 'en',
       '⚠️ PLACEHOLDER — legal review required. Demo content for "' || v_slug || '".',
       NOW(), true);

    UPDATE public.legal_documents SET current_version_id = v_version_id WHERE id = v_doc_id;
  END LOOP;
END $$;
