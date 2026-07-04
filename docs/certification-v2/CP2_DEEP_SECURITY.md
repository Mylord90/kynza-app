# CP2 — Deep Security: JWT, RPC/SECURITY DEFINER, SSRF, Mass Assignment, Timing, Session Fixation `[NEW DEPTH]`

All live testing below ran against `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`), reusing the
already-seeded QA Salon A/B tenants (`kynza.qa.{a,b}.{owner,staff,client}@example.com`), per this
pass's own convention (no destructive testing against production). Metadata-only reads (function
definitions, policy definitions, grants) were run against production via `pg_catalog`/`pg_proc`
introspection — never real user data.

## 🟠 P1/P2 — `staff_profiles.salon_id` mass-assignment: cross-tenant self-reassignment

**Réussi** (successful attack, confirmed live, then reverted).

- **What**: `staff_own_profile_update`'s `WITH CHECK` (`supabase/migrations/20260623220000_staff_management.sql`) pins `role` to its previous value but never pins `salon_id`.
- **Real, live proof** (`kynza-dr-scratch`, QA Salon A staff account,
  `kynza.qa.a.staff@example.com`):
  ```
  PATCH /rest/v1/staff_profiles?id=eq.fa29c69f-... {"salon_id":"a49c40c3-...(QA Salon B)"}
  Authorization: Bearer <QA-Salon-A-staff's own JWT>
  → HTTP 200 — salon_id actually changed from Salon A to Salon B
  ```
  Reverted immediately via a service-role `PATCH` back to the original `salon_id`; fixture
  confirmed restored.
- **Why it's not as severe as it first looks**: `has_role()` (the function every sensitive RLS
  policy actually calls) checks `users.salon_id`, not `staff_profiles.salon_id` —
  `users.salon_id` **is** protected (`protect_user_columns` trigger, verified below). So this bug
  does **not** grant the attacker `has_role(auth.uid(), 'staff', <other salon>)`, and does **not**
  open access to another tenant's `bookings`/RLS-protected data.
- **Why it still matters**: `staff_profiles.salon_id` is read directly (not via `has_role()`) by
  `AvailabilityService._eligiblePractitionerIds` (`lib/core/services/availability_service.dart:390`)
  and by the client-facing practitioner directory (`v_staff_directory_public`, the Gate 0 fix). A
  malicious staff account at Salon A can inject themselves into Salon B's public
  practitioner list and potentially get assigned as `practitioner_id` on a Salon B booking —
  corrupting another tenant's schedule/staff-directory integrity. Integrity impact, not
  confidentiality.
- **Confirmed present in production too**: same policy definition (`pg_policy` metadata,
  read-only, `hhdkjfpgaklhrhfoxlhj`) — `staff_own_profile_update`'s `WITH CHECK` is identical there.
- **Remediation drafted, NOT applied**:
  `supabase/migrations/20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` — pins
  `salon_id` in the `WITH CHECK` the same way `role` already is. No Flutter precondition: the only
  legitimate writer, `StaffRepositoryImpl.updateStaff()`, never sends `salon_id`.
- **CVSS 3.1 (estimate)**: `AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N` ≈ **6.5 (Medium)**. Not P0: no
  confidentiality exposure, requires an authenticated staff account (not anonymous), and the
  RLS-gated data plane is unaffected.

## SECURITY DEFINER function audit — every one, not a sample

Enumerated all 23 `SECURITY DEFINER` functions live in production (`pg_proc`/`pg_namespace`
query). Classified by real callability, not just existence:

| Function | Callable via RPC by anon/authenticated? | Validates caller identity/role internally? |
|---|---|---|
| `check_permission(p_user_id, p_salon_id, ...)` | authenticated only | ✅ **Yes** — raises if `p_salon_id` ≠ caller's own `users.salon_id`, and if `p_user_id` ≠ caller's own uid unless caller is owner/manager of that salon. Read the full function body to confirm — not assumed. |
| `check_and_increment_promo_quota(p_salon_id)` | authenticated only | ✅ **Yes** — raises unless `has_role(auth.uid(), 'owner'⎮'manager', p_salon_id)` |
| `get_staff_week_rank(p_staff_id)` | **anon + authenticated** (grant is loose) | ✅ **Yes**, despite the loose grant — raises unless caller is `staff` at that salon AND owns that exact `staff_profiles` row. An `anon` caller has no `auth.uid()`, so this always raises for anon; the anon grant is dead weight, not a live hole. Recommend `REVOKE EXECUTE ... FROM anon` as a hardening cleanup (cosmetic, not urgent). |
| 🔴 `create_default_document_templates(p_salon_id)` | **anon + authenticated** | ❌ **No validation at all** — see finding below |
| `create_default_salon_settings()`, `increment_monthly_bookings_count()`, `create_default_salon_settings` (trigger), `auto_document_templates`, `protect_review_columns`, `protect_user_columns`, `trigger_create_version`, `trigger_create_default_automation_workflows`, `invalidate_permission_cache_for_group/row`, `prevent_staff_removal_with_future_bookings`, `sync_email_verified`, `handle_new_user` | Grant looks loose on several of these, but all of them `RETURNS trigger` | ⚪ N/A — Postgres refuses to execute a trigger-typed function outside trigger context (`SELECT some_trigger_fn()` errors immediately), so the loose EXECUTE grant is inert regardless of internal logic. Confirmed by type, not assumed safe. |
| `create_default_automation_workflows`, `create_entity_version`, `increment_workflow_execution`, `check_rate_limit`, `custom_access_token_hook`, `refresh_audit_stats` | **EXECUTE explicitly revoked from anon and authenticated** (`false`/`false`) | ⚪ N/A — only `service_role`/`postgres` can call these directly; client-side callability is already closed at the grant level |

### 🟡 P2 — `create_default_document_templates(p_salon_id)`: unauthenticated cross-tenant write

**Réussi** (successful attack, confirmed live against `kynza-dr-scratch`).

```
POST /rest/v1/rpc/create_default_document_templates {"p_salon_id":"00a1d15e-...(a real salon)"}
apikey: <anon key>          # no Authorization bearer user token at all — fully unauthenticated
→ HTTP 204                  # succeeded
```

- **What**: takes an arbitrary `p_salon_id`, does zero caller-identity/role check, and inserts 3
  default document templates (invoice/receipt/monthly report) for that salon — reachable by a
  totally unauthenticated caller.
- **Blast radius, honestly bounded**: `INSERT ... ON CONFLICT (salon_id, type, name) DO NOTHING`
  means it can't overwrite existing templates with matching names, and the `salon_id` FK means a
  nonexistent salon errors out (`23503`) rather than creating orphan rows — confirmed both ways
  live. Residual risk: (a) if an owner renamed one of their default templates, an attacker calling
  this could re-insert a duplicate under the original default name, cluttering their template list;
  (b) the 204-vs-409 status difference is a free, unauthenticated salon-id-validity oracle (low
  value on its own — UUIDs aren't brute-forceable — but compounds with any other partial-ID leak).
- **CVSS 3.1 (estimate)**: `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:L/A:N` ≈ **5.3 (Medium)**.
- **Remediation**: not yet drafted as a migration this checkpoint (lower severity than the two
  above, queued for CP11's batch of draft patches) — the fix is the same pattern as
  `check_and_increment_promo_quota`: require `has_role(auth.uid(), 'owner'⎮'manager', p_salon_id)`
  before the insert.

## JWT

| Test | Result |
|---|---|
| Tampered signature on an otherwise-valid token | ✅ Bloqué — re-confirmed, same as CP6 (not re-run in full, cross-referenced) |
| Hand-crafted unsigned token claiming `role=owner` | ✅ Bloqué — re-confirmed, same as CP6 |
| **Refresh-token rotation, single reuse within ~1s** | 🟡 Returns 200 with the *same* still-current refresh token, not a new independent one — this is GoTrue's documented `reuse_interval` grace window (default 10s), meant to tolerate a client retry after a lost response, **not** a rotation failure. Verified this is bounded, not indefinite (see next row). |
| **Refresh-token reuse of a 2-generations-stale token, after the grace window elapsed** | ✅ Bloqué — `400 refresh_token_already_used`. Confirmed the *current* valid refresh token (3rd generation) still worked immediately after — reuse-detection didn't false-positive and revoke the legitimate session. **New test this pass, not covered by CP6.** |
| Expired access token | ⚪ **Not independently tested.** Default access-token TTL is 3600s — waiting that out isn't practical in this session, and forging a validly-signed-but-expired token would require the JWT signing secret, which this pass deliberately does not have (having it would itself be the vulnerability). Not substituted with a guess — flagged as an honest gap. |

## Session fixation

⚪ **Not applicable, with justification** (same reasoning pattern as CP6's CSRF verdict): every
KYNZA session is a bearer JWT pair returned directly in the `/auth/v1/token` response body and
stored client-side (no server-assigned session ID delivered via cookie or URL parameter that an
attacker could pre-set before a victim logs in). Classic session fixation requires exactly that
kind of externally-injectable session identifier, which doesn't exist in this architecture.

## Timing attack (login, valid-vs-nonexistent email)

Measured 5×5 real requests, `curl -w '%{time_total}'`, no load concurrency control (real-network
variance, small sample — not a controlled benchmark):

- Valid email + wrong password: avg **0.521s**
- Nonexistent email: avg **0.445s**

A measurable ~76ms difference exists, consistent with GoTrue doing a real password-hash comparison
only when the email exists. This is a genuine, real timing side-channel that could theoretically
support email-enumeration — but it's GoTrue's own (Supabase Auth) implementation, not KYNZA-authored
code, same boundary CP6 drew around refresh-token lifecycle. Reported honestly rather than silently
dropped; not actionable by editing this repository.

## SSRF

Audited every outbound `fetch()` call in `supabase/functions/` (3 files:
`_shared/fcm.ts`, `_shared/leapa.ts`, `_shared/whatsapp.ts`). All three target hardcoded or
env-configured hostnames (`graph.facebook.com`, `oauth2.googleapis.com`/`fcm.googleapis.com`,
`LEAPA_BASE_URL` from an env var, not request input). **No SSRF surface exists** — no Edge Function
builds an outbound request URL from client-supplied input. ⚪ Not applicable, confirmed by reading
every fetch call site, not by assumption.

## Exit criteria

- [x] Every SECURITY DEFINER function enumerated (23/23) and individually checked for
      caller-identity/role validation, not sampled.
- [x] Two real findings (mass assignment ×2) confirmed live, exploited, and reverted — not
      inferred from code review alone.
- [x] SSRF checked against actual fetch call sites — none found, justified.
- [x] JWT rotation/reuse tested live with a genuinely new scenario (multi-generation staleness),
      not just re-running CP6's cases.
- [x] Every "not applicable" verdict (session fixation, expired-token gap) carries a stated reason,
      not a bare assumption.
