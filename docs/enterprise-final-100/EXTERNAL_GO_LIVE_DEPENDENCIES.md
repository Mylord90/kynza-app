# External Go-Live Dependencies

**Date**: 2026-07-06. Everything intentionally left outside the Enterprise Final 100 campaign's
scope — either named in that campaign's own excluded list, or reclassified into it during CP1-CP11
once a Master Inventory item turned out to depend on one of these. Nothing on this list was
"chased further" once identified; each entry states exactly what's needed and who owns it.

## The original excluded list (untouched by design)

- **Leapa** (live payment integration)
- **Firebase production project** (the project itself exists and is configured for
  Crashlytics/FCM already — "external" here means *further* production activation steps, not
  that no Firebase project exists at all)
- **Google Maps** (live activation — needs a real API key)
- **Apple Developer account**
- **Google Play Console**
- **Final Privacy Policy / Terms of Service content**
- **Bank account details**
- **Real secrets/API keys** (as a general category — anything requiring a credential only Mylord
  can generate/hold)
- **Domain names**
- **Real certificates**

## Master Inventory items reclassified into this list during CP1-CP11

| ID | Item | Which excluded dependency | Owner / next action |
|---|---|---|---|
| P1-4 | Android upload keystore | Real secret (one-way, Mylord-only per Rule 8) | Mylord — procedure is final and ready (`docs/android/RELEASE_SIGNING_PROCEDURE.md`), just needs execution |
| P1-6 | Privacy Policy / Terms real content | Final Privacy Policy/ToS content | Business/legal — infrastructure (Legal Center) is fully built and ready to serve real content the moment it exists |
| P1-7 | iOS platform | Apple Developer account | Mylord/business — "a full second-platform launch effort, not a punch-list item," scoping decision, not an engineering task |
| P1-8 | Play Store Data Safety Form | Google Play Console | Mylord — the real, verified data inventory needed to fill it out already exists (`PRODUCTION_CHECKLIST.md` Part 14) |
| P2-19 | Real bank transfer details | Bank account details | Business — `KynzaConstants`/`create-manual-invoice` are ready to take the real values the moment they exist |
| P3-13 | Facebook/Apple sign-in | Real secrets/API keys (Facebook Developer App) + Apple Developer account | Business/Mylord — both halves need a real external app registration before any code change is worth making |
| P2-21 (pinning half only) | Certificate pinning activation | Real certificates | Needs a verified capture of Supabase's real production TLS cert from a trusted environment — the scaffold and kill-switch are already built and proven off |
| P3-14 (Maps/Geolocation half only) | Google Maps/Places/Geolocation | Google Maps (real API key) | Scaffold-when-ready pattern already proven on this exact feature (see the existing Google Maps architecture doc) — no code should be added until a real key exists |

**Not on this list, despite living in the same Master Inventory row as an external item — stated
explicitly so they aren't lost inside a row that reads "external" at a glance**:
- P2-21's **root/jailbreak detection** half — genuinely open internal engineering (a complete
  activation procedure exists, `docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md`; it wasn't
  shipped as code because verifying it needs a real rooted device, not because of any external
  service dependency).
- P3-14's **Firebase Analytics and local-notifications package** half — a real Firebase
  production project already exists (Crashlytics/FCM already run in it); adding Analytics needs
  no new external console setup. Local notifications need no external dependency at all. Both
  remain genuinely open internal work, not attempted this pass — see
  `ZERO_INTERNAL_DEBT_DECLARATION.md`.

## What this list is not

Not every "business decision" in the Master Inventory is on this list — only items that
specifically depend on one of the 10 named external dependencies above. Product-scope decisions
that don't need an external credential/account/console (e.g. P3-10's client-support role, P2-12's
feature-flag rollout decisions) are genuinely open *internal* engineering/product work, tracked as
such in `ZERO_INTERNAL_DEBT_DECLARATION.md`, not folded into this list for convenience.
