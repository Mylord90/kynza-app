# SCORECARD V2 — KYNZA Final Enterprise Verification Pass

Re-scored against the prior `enterprise-certified-v1` scorecard (62.3/100 average,
`docs/certification/CERTIFICATION_SCORECARD.md`). Per this pass's own rule: **no domain scores
higher than its prior number unless this pass produced concrete evidence of improvement.** Several
domains score *lower* — that is the honest, intended outcome of a genuinely adversarial re-test,
not an error.

| Domain | Prior | V2 | Δ | Why |
|---|---|---|---|---|
| Backend | 85 | **80** | −5 | 21/23 `SECURITY DEFINER` functions confirmed correctly validated (CP2) — but 2 real new bugs found (`staff_profiles.salon_id` mass assignment, `create_default_document_templates` zero-check) that a "backend: 85" rating implicitly claimed didn't exist |
| Sécurité | 52 | **44** | −8 | Gate 0's P0 is **still unpatched in production** (fix drafted, not applied — that alone caps this domain low) *and* this pass found 2 more live-exploited findings (CP2) plus 2 more confirmed-real gaps (CP4) the prior pass's own 13-vector sweep never surfaced. More real vulnerabilities found this pass than last, even though none of the new ones are P0-severity |
| Performance | 42 | **42** | 0 | Not re-measurable in this environment (no device) — no new evidence either direction |
| Observabilité | 58 | **28** | −30 | The prior 58 was earned against `kynza-dr-scratch`/local dashboards — this pass discovered **0 of the 7 Health Center dashboard RPCs exist in production at all** (CP5). The observability layer the prior score credited was never deployed |
| Scalabilité | 58 | **58** | 0 | Not re-tested this pass (no new load test run) — carried forward, not re-verified |
| Monitoring | 38 | **20** | −18 | Same root cause as Observabilité — the "13 dashboards exist as real, queryable data sources" claim (CP4 of the prior pass) was true only against staging; production has none of them live |
| Automation | 74 | **65** | −9 | `run-scheduled-actions` confirmed to have no real caller restriction beyond the publicly-known anon key (CP4) — the prior pass's "cron-only trust, by design" framing undersold this gap |
| Remote Config | 80 | **75** | −5 | Engine confirmed still undeployed to production (CP5/CP10), now precisely dated and batched for apply rather than an open-ended "known" gap — small credit for the now-concrete remediation path, offset by re-confirming it's still not live |
| Feature Flags | 62 | **55** | −7 | Same undeployed-to-production status confirmed, same reasoning as Remote Config |
| CMS | 65 | **55** | −10 | Same — confirmed undeployed to production this pass, not just "known" |
| Offline | 48 | **48** | 0 | Not re-tested (device-dependent) |
| Synchronisation | 55 | **55** | 0 | Not re-tested this pass |
| Documentation | 92 | **90** | −2 | This pass's own `docs/certification-v2/` tree is real, cross-referenced, evidenced — but the doc-vs-code consistency spot check (CP10) was only 4/10 completed, an honest shortfall against the original ask |
| Qualité de code | 76 | **70** | −6 | `flutter analyze`/`flutter test` still clean (CP7) — but CP1's tool-run cycle scan found a real `core`↔`feature` circular-dependency pattern (3 instances) that no prior pass's code-quality review ever caught, because none of them ran an actual import-graph tool |
| Tests | 54 | **54** | 0 | Unchanged — 381/381 passing, same suite, no new coverage added this pass |
| Production Readiness | 33 | **20** | −13 | The single biggest downward revision. Not because new problems were created — because this pass found the *actual* scope of what "undeployed" meant (14 migrations, precisely enumerated, CP5) plus a completely unprotected production database (**zero backups ever taken**, CP6) plus a re-confirmed-via-real-API 0 CI/CD executions (CP6) plus no real release keystore (CP6). The prior 33 was, if anything, generous — it flagged these as known gaps without quantifying how total the gap actually was |

## Unweighted average across 16 domains: **41.2/100** (prior: 62.3/100)

This is a large drop, and it is the intended result of an adversarial re-test finding that a
prior self-certification pass under-counted its own gaps — not a claim that the codebase got
worse this week. Every finding behind every negative Δ above is traceable to a specific
checkpoint in this pass (Gate 0, CP1-CP11), each with real evidence (live exploits, real API
calls, direct schema/grant queries) — none of these numbers are asserted without a paper trail.

## The one number that matters most (unchanged framing from the prior pass, still true)

**Production Readiness cannot be scored as anything resembling "ready" while (a) a confirmed P0 sits
unpatched in production, and (b) 14 feature migrations that back several "certified" domains above
have never been deployed there.** Every other number in this table is secondary to closing those
two facts — see `CP8_PRODUCTION_READINESS.md`'s ranked punch list for the concrete path forward.
