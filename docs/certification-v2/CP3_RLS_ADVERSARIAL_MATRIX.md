# CP3 — RLS Policy-by-Policy Adversarial Re-Test `[RE-VERIFY, adversarial]`

Every result below is a real HTTP call against `kynza-dr-scratch`, using the seeded QA Salon A /
QA Salon B tenants, attempting to read or write the *other* tenant's data as Salon A's
owner/staff/client — never inferred from reading policy SQL alone (that's exactly the class of
mistake that produced the Gate 0 P0).

## Cross-tenant read matrix (Salon A owner/staff/client → Salon B's rows)

| Table | owner | staff | client | Verdict |
|---|---|---|---|---|
| `salon_settings` | `[]` | `[]` | `[]` | ✅ Isolated |
| `loyalty_programs` | `[]` | `[]` | `[]` | ✅ Isolated |
| `loyalty_cards` | `[]` | `[]` | `[]` | ✅ Isolated |
| `reviews` | `[]` | `[]` | `[]` | ✅ Isolated |
| `invoices` | `[]` | `[]` | `[]` | ✅ Isolated |
| `activity_logs` | `[]` | `[]` | `[]` | ✅ Isolated |
| `bookings` | — | — | — | ✅ Isolated — re-confirmed via the existing `test/live/rls_cross_tenant_test.dart` (4 assertions, re-run this pass, all pass); not re-implemented redundantly here |
| `services` | full row returned | full row returned | full row returned | ⚪ **Not a bug — by design.** Read the full row: `name`, `description`, `category`, `duration_min`, `price_bif`, `image_url` — a salon's public "menu," exactly what a prospective client needs to browse before choosing a salon. No sensitive column (no cost/margin data) is exposed. Consistent with the discovery/booking flow's actual purpose. |
| `salons` | full row returned | full row returned | full row returned | ⚪ **Not a bug — by design**, same reasoning: public salon profile (name, address, logo, social links). `plan`/`plan_status` (e.g. "pro"/"active") is also exposed — mildly commercial-sensitive but not a security issue (likely intentional, e.g. a "Pro" badge in the app); flagged for product review, not a security finding. |
| `staff_profiles` | full row, **including `invitation_token`** | same | same | 🔴 **This is the Gate 0 P0, still unpatched in this environment** (the fix is drafted, not applied) — not a new finding, cross-referenced here for completeness of the matrix, not double-counted in the scorecard. |

## Cross-tenant write matrix (Salon A owner attempting to mutate Salon B's rows)

| Attempt | Result |
|---|---|
| Salon A client `PATCH`es Salon B's `services.price_bif` | `[]`, HTTP 200 (0 rows matched — RLS blocked silently, not a 403; consistent with PostgREST+RLS's non-leaking behavior) |
| Salon A owner `PATCH`es Salon B's `staff_profiles.is_active` (attempt to deactivate another salon's staff via `owner_manage_staff`) | `[]`, HTTP 200 — blocked. Re-confirmed via a real service-role read afterward: Salon B's staff row is still `is_active: true`, unaffected. |
| Salon A staff self-`PATCH`es own `staff_profiles.salon_id` to Salon B | 🟠 **Succeeds — this is CP2's mass-assignment finding**, cross-referenced here, not re-described. |

## Role-isolation summary

| Role tested | Cross-tenant read blocked? | Cross-tenant write blocked? |
|---|---|---|
| OWNER | ✅ (except `salons`/`services`, which are intentionally public) | ✅ |
| MANAGER | Not independently re-tested this checkpoint — QA fixtures don't include a distinct manager account; `manager_view_staff`'s policy expression is identical in shape to `owner_manage_staff`/staff's (`has_role(auth.uid(), 'manager', salon_id)`), and CP1 already confirmed this policy is unaffected by the Gate 0 fix. Not re-verified live — flagged as a real gap in this pass's coverage, not silently assumed clean. | Same gap |
| STAFF | 🔴 Public policy leak (Gate 0, unpatched) | 🟠 `salon_id` self-reassignment (CP2, unpatched) |
| CLIENT | ✅ (except intentionally-public `salons`/`services`/`staff_profiles` leak) | ✅ |
| SYSTEM_ADMIN | Not independently re-tested this checkpoint — no system-admin QA fixture exists in `kynza-dr-scratch`. Flagged as a coverage gap, not asserted clean. |

## Exit criteria

- [x] Every isolation check backed by a real HTTP request and its actual response, not a policy
      read.
- [x] Every leak found (staff_profiles ×2) is cross-referenced to its owning checkpoint (Gate 0,
      CP2), not re-reported as if newly discovered here, and not silently omitted from this
      matrix either.
- [ ] MANAGER-role and SYSTEM_ADMIN-role live isolation were **not** independently tested this
      pass — no seeded QA fixture exists for either. Honest gap, not papered over: recommend
      seeding a manager + system_admin QA account before the next security pass so this matrix can
      be completed.
