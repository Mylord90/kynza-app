# Phase 9 — CMS Enterprise

> Checkpoint CP4 (part 2 of 2). Help/FAQ/announcement content editable without a redeploy —
> genuinely useful pre-launch, unlike Track B items.

## 1. Objectifs

`cms_content`/`cms_content_versions` exactly as specified in the brief, an admin CRUD screen
(create/edit/publish/unpublish, locale-aware), and client-side consumers reading via Riverpod,
offline-cached in Hive.

## 2. Architecture

```
cms_content          (id, type, slug, locale, title, body_markdown, status, published_at, deleted_at)
cms_content_versions (id, content_id, version_number, body_markdown, changed_by, changed_at) — append-only, auto-populated by trigger
```

Reuses the append-only versioning pattern established by Legal Center (`legal_document_versions`)
rather than inventing a third pattern — simpler here since there's no `current_version_id`
indirection needed (the live value always lives directly on `cms_content`; versions are purely
historical). A trigger (`version_cms_content()`) auto-inserts a version row on every
`body_markdown` change, so versioning can never be silently skipped by a buggy admin-UI code path
— it lives in the database, not client discipline.

Access: public/authenticated read of `status = 'published'` rows only; `SYSTEM_ADMIN`-only write
(same ownership model as Phase 2's dashboards and Phase 4's Remote Config — platform-wide content,
not a salon-tenant concern). Legal documents (prior pass's Phase 3) remain in their own table,
untouched, per the brief's explicit instruction.

## 3. Workflow / Data Flow

**Admin**: `CmsAdminScreen` → create (draft) → edit body/title → publish (`status='published'`,
`published_at` set) → visible to clients the moment the Realtime/next-fetch cycle picks it up, no
redeploy. Unpublish reverses `status` without deleting the row (soft, matching `deleted_at`
convention elsewhere, though `status` rather than `deleted_at` is the toggle here per the brief's
own schema).

**Client**: `HelpCenterScreen` reads `cms_content` where `type='help_article'`, filtered to the
active `languageProvider` locale, mirrors the result into `CmsCache` (Hive), and falls back to the
last-cached snapshot on any fetch error — proven by `test/unit/cms_offline_fallback_test.dart`.
`AnnouncementBanner` is a reusable widget doing the same for `type='announcement'`, rendering
nothing (not an error, not a loading flash) when there's genuinely no active announcement.

## 4. Fichiers livrés

- `supabase/migrations/20260704140000_cms_enterprise.sql` (draft, unapplied)
- `lib/core/models/cms_content_model.dart`, `cms_content_version_model.dart`
- `lib/features/evolution/cms/domain/repositories/cms_repository.dart`
- `lib/features/evolution/cms/data/repositories/cms_repository_impl.dart`
- `lib/features/evolution/cms/data/cms_cache.dart`
- `lib/features/evolution/cms/application/providers/cms_providers.dart`
- `lib/features/evolution/cms/presentation/screens/cms_admin_screen.dart` (admin CRUD)
- `lib/features/evolution/cms/presentation/screens/help_center_screen.dart` (client consumer)
- `lib/features/evolution/cms/presentation/widgets/announcement_banner.dart` (reusable widget)
- `lib/core/router/app_router.dart`, `route_names.dart` (`/owner/cms-admin` SYSTEM_ADMIN-gated,
  `/help-center` open to any authenticated user)
- `lib/features/settings/presentation/screens/settings_home_screen.dart` (2 new menu entries)
- `lib/l10n/app_en.arb`, `app_fr.arb` (+18 keys)
- `test/unit/cms_cache_test.dart`, `cms_offline_fallback_test.dart`

## 5. Conventions & Structure

Body rendered as plain `Text` (no Markdown parser), matching the existing convention in
`policy_viewer_screen.dart` (Legal Center) — no new dependency added for this pass.

**Bounded scope, honestly disclosed**: the brief names 4 client-side consumer screens
(`HelpCenterScreen`, `AnnouncementBanner`, `OnboardingContentScreen`, `BeautyTipsScreen`). Only
`HelpCenterScreen` and `AnnouncementBanner` were built this phase — both are thin, generic
consumers of the same `cmsPublishedProvider` (parameterized by `type`), so
`OnboardingContentScreen`/`BeautyTipsScreen` are a small, mechanical follow-up (swap `type:
'onboarding_step'`/`'beauty_tip'`, no new engine work needed), not deferred because of any
architectural gap. Logged in `docs/PRODUCTION_CHECKLIST.md`, same bounded-scope discipline as
Phase 2's single-function/two-call-site instrumentation.

## 6. Migrations SQL / nouvelles tables

`20260704140000_cms_enterprise.sql` — draft, **not applied to any Supabase project**. 2 new
tables (`cms_content`, `cms_content_versions`), RLS (public read of published rows, SYSTEM_ADMIN
full manage), 1 auto-versioning trigger.

## 7. Nouvelles Edge Functions

None — CMS writes go through direct RLS-gated table access (SYSTEM_ADMIN only), not an Edge
Function, since there's no cross-cutting validation need like Remote Config's per-key JSON
schema.

## 8. Tests

- `test/unit/cms_cache_test.dart` (3 tests): Hive round-trip, scoped correctly per (type, locale).
- `test/unit/cms_offline_fallback_test.dart` (1 test): proves `cmsPublishedProvider` falls back to
  the last-cached snapshot when the repository throws — the exact exit criterion, not just a
  description of intended behavior.
- Full suite: 344 passing (was 340 before Phase 8/9 combined; +4 from this phase, +0 dedicated
  from Phase 8).

## 9. Documentation associée

- `docs/backend-completion/PHASE_1_FINAL_AUDIT.md` §3 item 9 (`SYSTEM_ADMIN`, reused here)
- `docs/PRODUCTION_CHECKLIST.md` (OnboardingContentScreen/BeautyTipsScreen follow-up logged)

## 10. Critères de validation

- `flutter analyze`: 0 issues.
- `flutter test`: 344/344 passing.
- No live/remote migration applied.

## 11. Checklist de sortie (Exit Criteria)

- [x] Content editable and published without app redeploy — proven by architecture: publish is a
      plain `status` UPDATE, picked up by the next `cmsPublishedProvider`/`cmsAdminListProvider`
      fetch, no client rebuild/redeploy involved.
- [x] Offline read of last-cached CMS content works — proven by
      `test/unit/cms_offline_fallback_test.dart`.
