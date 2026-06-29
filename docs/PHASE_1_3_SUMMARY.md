# PHASE 1.3 — Data Versioning — Summary

## Scope
The Phase 1 combined acceptance checklist only requires "Versioning :
trigger actif sur services + subscriptions" — a backend-only bar. This
phase is SQL-only; no Flutter changes.

## What changed

**Migration:** `supabase/migrations/20260629120000_entity_versioning.sql`
- `entity_versions` (generic version-snapshot table: `entity_type`,
  `entity_id`, `version_number`, full-row `data` JSONB,
  `changed_fields` diff array, `changed_by`, `change_reason`, `is_current`).
- `create_entity_version()` — marks the prior current version non-current,
  computes the next version number, diffs against the previous snapshot
  for `changed_fields`, inserts the new version. `SECURITY DEFINER`,
  `REVOKE`d from `authenticated`/`anon` (only called internally by the
  trigger below, never directly).
- `trigger_create_version()` — generic `AFTER INSERT OR UPDATE` trigger
  function using `TG_TABLE_NAME` as `entity_type`.
- Applied to `services` and `invoices`.

**Deviation from the brief (found while auditing, before writing SQL):**
There is no `subscriptions` table anywhere in this codebase — checked
every migration and every Flutter/Edge-Function call site for `subscriptions`. Subscription state actually lives on `salons.plan`/
`plan_status` (flipped atomically by `mark_invoice_paid()`) and on
`public.invoices` (the real billing/plan-change record: pending → paid →
void). Versioning `salons` wholesale would snapshot every unrelated edit
(name, address, hours, logo...) as "subscription history" — far noisier
than intended, and not what the brief actually wants tracked. Applied the
trigger to `invoices` instead, as the real analogue, and documented the
substitution rather than silently inventing a `subscriptions` table or
skipping this requirement.

Checked update frequency before committing to this design (a versioning
trigger on a hot-path table would be noisy/wasteful): `services` only
changes via deliberate owner edits in the services management screen;
`invoices` is created once (`create-manual-invoice`) and updated exactly
once by `mark_invoice_paid()` — no `check-subscription` Edge Function or
recurring job touches either table (that function doesn't exist either,
despite being listed as already-existing in the original brief).

## Verification
Both triggers tested directly against the remote DB inside a rolled-back
transaction (no data left behind):
- `services`: INSERT created version 1 (`changed_fields: null`, no prior
  version to diff against); UPDATE of `price_bif` created version 2 with
  `changed_fields: ['price_bif']`, old version flipped to
  `is_current = false`, new version's JSONB snapshot correctly shows the
  new price.
- `invoices`: same pattern — INSERT → version 1 (`status: pending`);
  UPDATE to `status = 'paid'` → version 2 with
  `changed_fields: ['status', 'paid_at']`.
- `flutter analyze` → No issues found (no Dart files touched this phase).

## Remaining known gaps
- No Flutter `EntityVersionService`/UI consumer yet — same treatment as
  `mv_audit_stats` in Phase 1.2: the backend mechanism is verified
  working, but nothing surfaces it in the app yet. No natural integration
  point exists today (e.g. a "price history" panel on the services edit
  screen) and none was asked for.
- No `compare()` (diff) or `restore()` capability. `restore()` in
  particular would need either dynamic SQL keyed off `entity_type` or
  per-entity-type Dart logic, plus a decision on how to handle restoring
  over a row that's since been edited concurrently — real complexity not
  worth building speculatively. `getHistory()` alone (read-only) would be
  cheap to add once a screen actually wants it.
- `changed_by` is `NULL` when a version is created by a service-role Edge
  Function (e.g. `create-manual-invoice`) rather than an authenticated
  user session — `auth.uid()` has no value in that context. Expected, not
  a bug: there's no per-call "acting user" visible to a plain SQL trigger
  when the connection itself is the service role.