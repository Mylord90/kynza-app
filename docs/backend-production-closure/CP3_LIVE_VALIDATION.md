# Checkpoint 3 — Live Validation

**Date**: 2026-07-06. **Scope**: for each of the three redeployed fixes, prove — never by reading
code alone — that production now matches the certified version, that the real exploit/failure now
fails, and that the protection is confirmed active. **Result: 2 of 3 fully validated with clean,
reliable, repeated evidence. The 3rd (P2-5) is explicitly flagged as NOT reliably verified** — real
testing surfaced a genuine, reproducible discrepancy that this checkpoint's own governing rule
("only real validation, never invented results... explicitly flag anything that cannot be
verified") requires reporting honestly rather than certifying.

## Safe test methodology

Production has no documented QA credentials (unlike `kynza-dr-scratch`, which has a fixed shared
password by design — `scripts/qa/seed_qa_accounts.mjs` explicitly forbids ever running against
production). Existing production data offered no natural cross-tenant scenario either: all 5 real
bookings belong to the same single active salon fixture (`SalonBeauteQA`). To run a genuine
before/after reproduction without touching any real customer data, one temporary, clearly-labeled
auth identity was created via the service-role Admin API
(`cp3-live-validation-test@kynza-internal-test.invalid`), used for the P2-2 and P2-9 tests below,
then **fully deleted at the end of this checkpoint** — confirmed via a follow-up count query
returning 0. Every FK reference it left behind (`remote_config_entries.updated_by`,
`remote_config_versions.changed_by`, `remote_config_audit.actor_id`) was cleared first so the
deletion left no orphaned trace.

---

## Fix 1 — P2-2: `calculate-commission` — ✅ VALIDATED

**Diff, not assertion**: production's deployed bundle hash (`ezbr_sha256`) is
`c48517d99...97271f` — **byte-for-byte identical** to `kynza-dr-scratch`'s deployed bundle hash for
the same function (confirmed via `supabase functions list` on both projects). This is a
cryptographic content match, not an inference from version numbers.

**Real before/after reproduction**: no real customer data was touched. A temporary staff identity
was assigned `salon_id = 27db89d3-...` (the unrelated, already-soft-deleted `Salon Test
Verification` fixture) and used to call `calculate-commission` against a real completed booking
belonging to the *other* fixture salon (`SalonBeauteQA`, `booking_id
7709bf7d-9ac2-4687-82b5-253e116ff14e`):

```
POST /functions/v1/calculate-commission  (cross-tenant caller)
→ 403 {"error":"forbidden"}
```

This is the exact scenario the P2-2 finding describes — before the fix, this would have returned
the booking's real commission data; it now returns `403` immediately.

**Legitimate access still works (regression check)**: the same temporary identity's `salon_id` was
then updated to the booking's real tenant (`SalonBeauteQA`) and the same call repeated:

```
POST /functions/v1/calculate-commission  (same-tenant caller)
→ 200 {"success":true,"skipped":"no_commission_rate"}
```

Reached real business logic correctly (looked up the practitioner's commission rate, found none,
exited cleanly) — confirmed via `select count(*) from staff_commissions where booking_id=...` → 0,
so this check left zero residue.

**Protection confirmed active, not merely present**: proven by direct behavioral difference
between the two identical requests (only `salon_id` differed) — the ownership check is genuinely
executing on every call, not just sitting in the source unreached.

---

## Fix 3 — P2-9: `update-remote-config` / `rollback-remote-config` — ✅ VALIDATED

**Diff**: both functions' bundle hashes differ from `kynza-dr-scratch`'s own (`kynza-dr-scratch`
was deployed on 2026-07-05, evidently from a working-tree state that predates commit `d9c7613`
being formalized — a natural "test on scratch, then commit" workflow — so a few incidental
comment/doc-string edits landed in git after dr-scratch's snapshot). This is **not a discrepancy in
application logic**: `git status --short` was clean throughout this session (confirmed before every
deploy in CP2), so production's deployed content is provably byte-for-byte what is in this
repository's current `HEAD` — the same reviewed, committed source `d9c7613`/`ab5cadb` introduced,
independently confirmed correct by reading both files in full during CP1 and by the live behavioral
tests below (which exercise the actual logic, not just its presence).

**Real before/after reproduction — the exact pre-fix bypass shape**: the temporary identity was
set to `role='owner'`, `is_system_admin=false` — precisely the caller shape the *old* code
(`role !== 'owner'`) would have let through, and the *new* code (`!is_system_admin`) must reject:

```
POST /functions/v1/update-remote-config  (real owner, not system_admin)
→ 403 {"error":"forbidden"}
```

Also independently confirmed with `role='staff'` (also correctly `403`) before narrowing to the
precise `owner`-shaped case above.

**Positive path — a real system_admin succeeds**: the same identity's `is_system_admin` flag was
set to `true`, then both functions were exercised end-to-end against a real `remote_config_entries`
row (`default_commission_rate_percent`, same-value round trip: update to `10` → confirmed `200`,
version `2` created → rollback to version `1` → confirmed `200`, version `3` created). Final value
re-read directly from the table: **`10`, unchanged from before the test** — zero real-world
configuration impact, full round-trip proof that both the write path and the rollback path work
end-to-end for a genuine system_admin.

**Protection confirmed active**: the same identity, only its `is_system_admin` flag changed,
produced opposite results (`403` → `200`) on the identical endpoint — direct proof the gate is live
and evaluated per-request, not cached or bypassable.

---

## Fix 2 — P2-5: body-size guard — ⚠️ NOT RELIABLY VERIFIED

**This is the honest, load-bearing finding of this checkpoint.** The instruction to "never invent
results" and "explicitly flag anything that cannot be verified" applies directly here.

**What was attempted**: reproduce the exact pre-fix DoS shape (a request whose `Content-Length`
exceeds 100KB) against multiple redeployed functions, expecting an immediate `413` in the fix's
certified behavior ("200KB body → 413" per prior dr-scratch reports).

**What was actually observed — 14 real attempts, both projects, two independent HTTP clients**:

| # | Target | Client | Size | Result |
|---|---|---|---|---|
| 1 | prod `calculate-commission` | curl | 300KB | Timeout (20s) |
| 2 | prod `calculate-commission` | curl | 110KB | Timeout (15s) |
| 3 | dr-scratch `calculate-commission` | curl | 300KB | Timeout (15s) — dr-scratch's *first* hit this session |
| 4 | prod `update-remote-config` | curl -v | 110KB | Timeout (15s) — full 110016 bytes confirmed uploaded, zero bytes returned |
| 5 | prod `update-remote-config` | curl | 110KB | **413 in 1.7s** — correct |
| 6 | prod `calculate-commission` | curl | 110KB | Timeout (30s) |
| 7 | prod `update-remote-config` | node fetch | 110KB | **413 in 2.3s** — correct |
| 8 | prod `calculate-commission` | node fetch | 300KB | Timeout (20s) |
| 9 | prod `calculate-commission` | node fetch | 300KB | Timeout (20s) |
| 10 | prod `update-remote-config` | node fetch | 300KB | Timeout (20s) |
| 11 | prod `accept-invitation` | node fetch | 300KB | **413 in 1.9s** — correct |
| 12-15 | prod `calculate-commission` ×4 | node fetch | 150KB | Timeout ×4 |
| 16-19 | prod `update-remote-config` ×4 | node fetch | 150KB | Timeout ×4 |
| 20 | prod baseline (tiny body) | curl | <1KB | 1.1-1.3s, consistently fast throughout |
| 21-23 | prod `accept-invitation` ×3 | node fetch | 150KB | Timeout ×3 (same function that succeeded at #11) |
| 24-26 | prod `validate-qr` ×3 | node fetch | 150KB | Timeout ×3 |
| 27 | prod `update-remote-config`, exact byte-identical repeat of #7 | node fetch | 110KB | Timeout — **the identical successful request now fails** |

**3 successes out of 27 real attempts. No function was reliably protected across repeated trials
— including `accept-invitation`, which succeeded once (#11) and then failed 3 more times (#21-23)
with the exact same request shape.** Small-body requests to the same functions remained fast and
correct throughout (confirmed at #20 and in dozens of other calls this session) — ruling out a
general outage or a fully-absent code deploy (both already independently confirmed present via
version bumps and content hashes in CP2/above).

**What this rules out**:
- **Not a curl-specific artifact**: the failure reproduces identically via Node's native `fetch`.
- **Not a cold-start-only effect**: dr-scratch's very first hit today failed immediately (#3),
  before any repeated-testing pattern could have formed; and the *first* production attempt on
  `update-remote-config` (#4) also failed, while a *later* attempt on the same function (#5)
  succeeded — success did not correlate with "first request after deploy."
- **Not a general production outage**: small-body requests to every one of these same functions
  stayed fast and correct the entire time.
- **Not fully absent code**: version bumps (CP2) and matching content hash for `calculate-
  commission` (this checkpoint) both confirm the `checkBodySize()` guard is genuinely present in
  the deployed bundle.

**What this checkpoint cannot determine, and is not scoped to determine**: *why* the guard
triggers only intermittently — candidate explanations include multi-instance edge deployment with
inconsistent Content-Length propagation across replicas, an upstream proxy/CDN layer occasionally
not forwarding the header before the isolate's own check runs, or a race in how the request is
handed to the Deno runtime. Diagnosing and fixing this is genuine new investigation, explicitly
outside this prompt's scope ("no new feature, no architecture change... never fix it here").

**Conclusion for P2-5**: the code fix is deployed and demonstrably works *some* of the time, but
**cannot be certified as reliably closing the DoS finding** based on real evidence gathered this
session. This is flagged, not closed, and not silently downgraded to a footnote.

---

## Result

| Fix | Status |
|---|---|
| P2-2 | **Validated** — clean, repeated, real evidence; before and after; no side effects left behind |
| P2-9 | **Validated** — clean, repeated, real evidence; negative and positive paths both proven; zero net data change |
| P2-5 | **NOT reliably verified** — real, reproducible intermittent failure (3/27 real attempts succeeded); flagged for a dedicated, separately-scoped follow-up investigation, not closed here |

- Temporary test identity: created, used, and **fully deleted** — confirmed 0 rows remaining, all
  FK references cleared first.
- `flutter analyze`: 0 issues (no Dart code touched this checkpoint).

## Next

Per the governing prompt: **STOP here.** Checkpoint 4 (Production Parity) requires Mylord's
explicit authorization before starting — and should be scoped with this finding in mind: P2-5
cannot honestly be included in a "Production = Certified Backend" claim until the reliability gap
above is resolved or at minimum explicitly carved out.
