-- Phase 9 (Backend Enterprise Completion) — CMS Enterprise
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8.
--
-- Schema exactly as specified in the brief. Reuses the versioning pattern
-- established by Legal Center (append-only version history on every
-- content change) rather than inventing a third pattern in this codebase —
-- simpler than legal_documents/legal_document_versions' current_version_id
-- indirection because cms_content_versions here is purely historical
-- (no "is_current" pointer needed: the live value is always cms_content's
-- own row). Legal documents remain in their own table — never migrated
-- into cms_content, per the brief's own instruction (distinct
-- legal-acceptance semantics).

CREATE TABLE IF NOT EXISTS public.cms_content (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  type           TEXT        NOT NULL CHECK (type IN (
                    'faq', 'help_article', 'announcement', 'tutorial',
                    'onboarding_step', 'guide', 'banner', 'promotion',
                    'beauty_tip', 'support_info'
                  )),
  slug           TEXT        NOT NULL,
  locale         TEXT        NOT NULL DEFAULT 'fr' CHECK (locale IN ('fr', 'en')),
  title          TEXT        NOT NULL,
  body_markdown  TEXT        NOT NULL,
  status         TEXT        NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'unpublished')),
  published_at   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at     TIMESTAMPTZ,
  UNIQUE (slug, locale)
);
ALTER TABLE public.cms_content ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_cms_content_type_status
  ON public.cms_content (type, status, locale) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_cms_content_updated_at
  BEFORE UPDATE ON public.cms_content
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Public/authenticated read of published content only.
CREATE POLICY "cms_content_public_select"
  ON public.cms_content FOR SELECT
  USING (deleted_at IS NULL AND status = 'published');

-- SYSTEM_ADMIN full manage (this is platform-wide content, not a salon-tenant
-- concern — same ownership model as remote_config_entries/Phase 2's
-- dashboards, not a new access pattern).
CREATE POLICY "cms_content_admin_all"
  ON public.cms_content FOR ALL TO authenticated
  USING (public.has_system_admin(auth.uid()))
  WITH CHECK (public.has_system_admin(auth.uid()));

-- ─── Version history (append-only, mirrors remote_config_versions) ────────

CREATE TABLE IF NOT EXISTS public.cms_content_versions (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id     UUID        NOT NULL REFERENCES public.cms_content(id) ON DELETE CASCADE,
  version_number INT         NOT NULL,
  body_markdown  TEXT        NOT NULL,
  changed_by     UUID        REFERENCES public.users(id),
  changed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (content_id, version_number)
);
ALTER TABLE public.cms_content_versions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_cms_content_versions_content
  ON public.cms_content_versions (content_id, version_number DESC);

CREATE POLICY "cms_content_versions_admin_select"
  ON public.cms_content_versions FOR SELECT TO authenticated
  USING (public.has_system_admin(auth.uid()));

-- Auto-version on every body_markdown change — belongs in the database, not
-- client discipline, so a version is never silently missed regardless of
-- which admin path writes the content.
CREATE OR REPLACE FUNCTION public.version_cms_content()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_next_version INT;
BEGIN
  IF TG_OP = 'INSERT' OR NEW.body_markdown IS DISTINCT FROM OLD.body_markdown THEN
    SELECT COALESCE(MAX(version_number), 0) + 1 INTO v_next_version
    FROM public.cms_content_versions WHERE content_id = NEW.id;

    INSERT INTO public.cms_content_versions (content_id, version_number, body_markdown, changed_by)
    VALUES (NEW.id, v_next_version, NEW.body_markdown, auth.uid());
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_cms_content_version
  AFTER INSERT OR UPDATE ON public.cms_content
  FOR EACH ROW EXECUTE FUNCTION public.version_cms_content();
