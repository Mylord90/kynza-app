# Backend Governance — Phase 1: Documentary Unification

**Date**: 2026-07-07. **Scope**: apply the two corrections already proposed by
`docs/final-doc-verification/FINAL_DECISION.md`, then inventory every reference document in the
repository, classify each as canonical or superseded/historical with evidence, and verify every
internal link still resolves. **No code, no migration, no Edge Function, no Flutter change** —
purely documentary.

---

## 1. The two pre-identified corrections — applied

### 1.1 `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` declared the single canonical Master Inventory

`docs/remediation/MASTER_ISSUES_MATRIX.md` now carries an explicit banner at its top: **"⚠️
SUPERSEDED (2026-07-07)"**, stating it is historical evidence only, citing the live
re-verification that found it stale (`docs/final-doc-verification/P0_VERIFICATION.md`,
`P1_VERIFICATION.md`), and pointing to `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 as
the canonical source. The file is not deleted, and no finding within it was altered except the ID
renumbering below — it remains the Remediation v1 pass's evidentiary record.

### 1.2 The `P2-22` ID collision resolved — renumbered to `P2-28`

The P2-5 ECR's new finding (platform body-delivery ceiling, `docs/p2-5-ecr/CP3_TESTS.md` Sections
G-H) was filed as `P2-22` in `MASTER_ISSUES_MATRIX.md`, colliding with an unrelated,
already-closed `P2-22` (the bulk-write trigger ceiling fix) already present in
`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:81`. Every cross-reference updated:

| File | Change |
|---|---|
| `docs/remediation/MASTER_ISSUES_MATRIX.md` | Entry heading `### P2-22` → `### P2-28`, with a renumbering note explaining why; executive-summary count line updated; the P2-5 entry's own cross-reference to "P2-22" updated to "P2-28"; the end-of-file cross-reference table updated |
| `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` | New row added: `P2-28` (the platform ceiling finding was previously **absent** from this document entirely — it post-dates this document's last update, 2026-07-06 13:45); total-item count updated 68→69 |

`P2-28` was chosen as the next free ID in `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s own
numbering space (its highest prior P2 entry is `P2-27`, paired with `P2-6`).

### 1.3 A third, related staleness found and corrected in the same pass: `P2-5`'s own row

`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s P2-5 row still read "Ouvert (re-scoped —
redeployed but not reliably validated)" — the state as of Backend Production Closure (2026-07-06
13:45), before the P2-5 RCA and ECR (2026-07-07) root-caused and fixed it. Updated to `Fermé
(preuve)`, citing the RCA and ECR's actual evidence (`docs/p2-5-ecr/CP3_TESTS.md` Section H:
100% deterministic vs. 0-20% for the pre-fix code; `docs/p2-5-ecr/CP5_VALIDATION.md`).

### 1.4 A fourth staleness found and corrected: the canonical document's own internal contradiction

`docs/final-doc-verification/FINAL_DECISION.md` (Question 3) had already found that
`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s §2 (Master Inventory table) was updated in
place through 2026-07-06, but its §1 (Executive Summary) and §19-20 (Final Executive Decision)
were never revised to match — they still narrate P0-1 as "unpatched... today" and list closing
P0-1/P1-2/P1-3/P1-4 as a pending trigger condition, when §2 already shows 3 of those 4 closed. A
prominent notice was inserted immediately after the document's own "supersedes all eight" line,
stating the correct current state with citations, and explicitly directing readers to §2 over the
stale prose in §1/§19/§20 (kept, unmodified, as historical narrative of the reasoning trail — not
deleted, per this session's "propose the correction, don't silently delete" discipline applied to
the pattern of keeping history rather than erasing it).

---

## 2. Full document inventory — canonical vs. historical, by group

210 markdown files existed under `docs/` at the start of this phase (211 once this report itself
is saved). Individually justifying each would produce a document
longer than any single file it describes; instead, every file is accounted for in one of the
groups below, each with its member count, its classification, and the evidence for that
classification (spot-checked against file headers where a genuine ambiguity existed — not
assumed from directory name alone).

| Group | Files | Classification | Evidence |
|---|---|---|---|
| **`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`** | 1 | **CANONICAL** — the single Master Inventory for current issue/status tracking | Declared canonical this phase (§1.1); already self-described as superseding 8 named passes; its §2 table is the only issue tracker updated in place through the most recent campaigns |
| **`docs/DOCUMENTATION_INDEX.md`** | 1 | **CANONICAL** — the map of which document covers what, in chronological order | Extended this phase (§3 below) to cover the 6 passes it was missing; already correctly pointed to the Master Plan as "read this first" before this phase touched it |
| **`docs/remediation/MASTER_ISSUES_MATRIX.md`** | 1 | **SUPERSEDED** (banner added this phase) | Frozen since 2026-07-04, diverged silently from production reality — the root cause of the P0/P1 contradiction the prior verification session investigated |
| **Architecture/reference docs** — `ARCHITECTURE.md`, `ARCHITECTURE_GLOBAL.md`, `API_REFERENCE.md`, `API_REFERENCE_ENTERPRISE.md`, `DATABASE_ARCHITECTURE.md`, `EDGE_FUNCTIONS_REFERENCE.md`, `WORKFLOWS.md`, `FEATURE_FLAGS.md`, `CATALOG_ARCHITECTURE.md`, `CATALOG_EXTENSION_GUIDE.md`, `LEGAL_CENTER_ARCHITECTURE.md`, `GOOGLE_MAPS_ARCHITECTURE.md`, `OFFLINE_STRATEGY.md`, `OBSERVABILITY_MONITORING.md`, `PERFORMANCE_TARGETS.md` | 15 | **CANONICAL**, each for its own topic — living reference docs, not point-in-time findings | Checked headers directly: `ARCHITECTURE_GLOBAL.md` explicitly declares itself "Companion to the existing `docs/ARCHITECTURE.md`," `API_REFERENCE_ENTERPRISE.md` covers *external* integrations distinct from `API_REFERENCE.md`'s *internal* RPC/Edge Function surface — genuinely complementary pairs, not competing duplicates, confirmed by `DOCUMENTATION_INDEX.md:105-106`'s own explicit note |
| **UI/Design guides** — `DESIGN_SYSTEM.md`, `TYPOGRAPHY_GUIDE.md`, `ANIMATIONS_GUIDE.md`, `ASSETS_GUIDE.md`, `I18N_GUIDE.md`, `LANGUAGE_WORKFLOW.md`, `LOADER_GUIDE.md`, `BOTTOM_NAVIGATION_GUIDE.md` | 8 | **CANONICAL** — standing Flutter/UI reference, outside the backend campaigns' scope entirely | Different domain from every backend security/infra finding; never referenced or contradicted by any campaign report |
| **Security reference** — `docs/SECURITY.md`, `docs/security/SECURITY_ENTERPRISE.md`, `docs/security/APP_CHECK_ARCHITECTURE.md`, `docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md` | 4 | **CANONICAL**, layered — `SECURITY_ENTERPRISE.md` explicitly "Extends `docs/SECURITY.md`" | Checked headers directly; companion relationship confirmed in `SECURITY_ENTERPRISE.md`'s own opening line |
| **`docs/security/SECURITY_AUDIT_V2.md`** | 1 | **HISTORICAL** — a campaign audit report (Enterprise Hardening Phase 5), not a standing reference | Its own header: "Phase 5 of the Enterprise Hardening & Production Readiness pass... a from-scratch re-verification... not a re-statement of `docs/SECURITY.md`" — a point-in-time audit, findings already folded into the Master Inventory |
| **Testing/Ops guides** — `TESTING_ENTERPRISE_STRATEGY.md`, `DISASTER_RECOVERY_RUNBOOK.md`, `docs/conventions/SOFT_DELETE.md`, `docs/android/RELEASE_SIGNING_PROCEDURE.md` | 4 | **CANONICAL** — standing procedures, referenced by name from the Master Inventory (e.g. P1-4 cites `RELEASE_SIGNING_PROCEDURE.md` directly) rather than superseded by it | Each describes a *procedure*, not an *audit finding* |
| **`docs/PRODUCTION_CHECKLIST.md`, `docs/PRODUCTION_READINESS.md`** | 2 | **HISTORICAL** — campaign checklists, findings consolidated into the Master Inventory | `PRODUCTION_READINESS.md`'s own header: "Phase 10 of the Enterprise Hardening pass"; `MASTER_ISSUES_MATRIX.md`'s own opening explicitly lists `PRODUCTION_CHECKLIST.md`'s dated update sections as source material it consolidated |
| **`ENTERPRISE_HARDENING_REPORT.md`, `ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md`, `TEST_PROXIPAY_E2E_REPORT.md`** | 3 | **HISTORICAL** — campaign closing reports | Named, dated campaign artifacts, already pointed to from `DOCUMENTATION_INDEX.md` as historical narrative |
| **Old Flutter build-phase summaries** — `PHASE2_2_SUMMARY.md`, `PHASE3A_SUMMARY.md`, `PHASES_3B_TO_6_SUMMARY.md`, `PHASE_1_1_SUMMARY.md` through `PHASE_1_4_SUMMARY.md`, `PHASE_2_SUMMARY.md` through `PHASE_5_SUMMARY.md`, `PHASE_A_SUMMARY.md`, `PHASE_I18N_SUMMARY.md`, `PHASE_LOADER_SUMMARY.md`, `PHASE_TYPOGRAPHY_SUMMARY.md` | 15 | **HISTORICAL** — point-in-time feature-build logs, pre-dating every backend campaign | These record *when a Flutter feature was built*, not an open-issue status; they do not compete with the Master Inventory and need no supersession marking, only correct historical labeling (already implicit in their names/dates) |
| **`docs/ai/KNOWLEDGE.md`, `docs/ai/skills/*.md`** | 11 | **CANONICAL** — standing AI-agent operating knowledge for this repo | Referenced by the assistant's own skill system, not an audit artifact |
| **`docs/prompts/*.md`** | 2 | **HISTORICAL** — the original execution-order prompts that kicked off the Backend Enterprise Completion campaign | Point-in-time instructions, superseded by their own campaign's output |
| **`docs/adr/*.md`** | 6 (5 ADRs + README) | **CANONICAL** — the ADR mechanism, standing by design | Verified no numbering gap or collision: `0001`-`0005` present, sequential, no duplicates (`ls docs/adr/`) |
| **Campaign folders** — `backend-completion/` (19), `certification/` (11), `certification-v2/` (14), `remediation/` excl. matrix (5) + `remediation/CERTIFICATES/` (12), `final-enterprise-validation/` (12), `enterprise-resilience/` (11), `master-plan-execution/` (5), `enterprise-final-100/` (12), `go-live/` (4), `backend-production-closure/` (6), `p2-5-rca/` (7), `p2-5-ecr/` (7), `docs/audit/` (6) | 131 | **HISTORICAL** — sequential campaign reports, each an evidentiary source for findings already consolidated into the canonical Master Inventory | Confirmed via `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s own "Source passes consolidated" table (lines 7-16) plus `DOCUMENTATION_INDEX.md`'s own pointer table (both extended this phase) — every one of these folders is already named as a consolidated-from source, not an independent tracker |
| **`docs/KYNZA_FINAL_ENGINEERING_CERTIFICATION.md`** | 1 | **HISTORICAL, with a stated exception** — its Q5/Q8 verdicts are superseded (by Go-Live Phase 1, 21 minutes later); its other content (test-count reconciliation Q1, domain scores Q4) is undisputed and still accurate | Verified directly: `flutter test`/`flutter analyze` figures it cites were not re-contradicted by anything later; only the P0-1-dependent verdicts changed |
| **`docs/final-doc-verification/*.md`** | 4 | **ACTIONED** — a verification snapshot whose two proposed corrections are applied by this very phase; its content remains the evidentiary record of how those corrections were discovered | Not itself an issue tracker — it fed the corrections in §1 above |

**Total accounted for: 1+1+1+15+8+4+1+4+2+3+15+11+2+6+131+1+4 = 210** — matches the link-checker's
file count exactly (`find docs -name "*.md" | wc -l` → 210). Verified by direct recount, not
assumed correct on the first pass: an initial draft of this table mis-stated the Flutter
phase-summary count as 16 (actual: 15, `ls docs/PHASE*SUMMARY.md | wc -l`) and the campaign-folder
total included `remediation/`'s 6 files without subtracting `MASTER_ISSUES_MATRIX.md` (already
counted in its own dedicated row above) — both caught by the arithmetic not reconciling to 210 on
the first attempt, and corrected before this document was finalized.

---

## 3. Documentation Index extended

`docs/DOCUMENTATION_INDEX.md` covered every pass through Enterprise Final 100 (2026-07-05) but had
never been extended for the 6 passes since (Final Engineering Certification, Go-Live,
Backend Production Closure, P2-5 RCA, P2-5 ECR, Final Documentary Verification). Added a new
"Everything since Enterprise Final 100" section, in the same consolidated-pointer format the
document already used for the prior 6-pass gap (its own §"Everything since Cert v2"), plus this
governance phase itself as the newest entry — so the index remains current going forward, not
just retroactively complete.

## 4. Link verification — real command, not assumed

```
$ node check_links.mjs   # walks docs/, extracts every markdown link (label + destination),
                          # resolves it relative to the source file, checks existence
Checked 210 files, 135 internal links.
Broken: 0
```

Every internal markdown link across the entire `docs/` tree resolves to a real file, run after
every edit in this phase (the banner, the renumbering, the Executive Summary notice, and the
Documentation Index extension all add prose but no new links that weren't verified).

## Next

Phase 2 — Backend Governance Guide: the standing rules (ticket lifecycle, migration lifecycle,
ADR process, Edge Function workflow, security classification, documentation ownership) that
prevent the exact failure this phase just corrected — a second, silently-diverging tracker and an
ID collision — from recurring.
