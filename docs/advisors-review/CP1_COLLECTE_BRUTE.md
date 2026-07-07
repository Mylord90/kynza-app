# Point de Contrôle 1 — Collecte brute des alertes Supabase Advisors

**Date** : 2026-07-07. **Session** : traitement scientifique des alertes Supabase Advisors
(prompt entreprise, Catégorie B — session ciblée par `docs/governance/CHANGE_POLICY.md`).
**Projet** : `hhdkjfpgaklhrhfoxlhj` (production, `eu-central-1`).
**Méthode** : `supabase db advisors --linked --type all --level info --output-format json`,
exécuté directement contre le projet lié — lecture seule, aucune correction appliquée à ce stade.

**Preuve brute complète** : [`evidence/CP1_advisors_hhdkjfpgaklhrhfoxlhj_2026-07-07.json`](evidence/CP1_advisors_hhdkjfpgaklhrhfoxlhj_2026-07-07.json)
(586 objets, un par alerte, avec ID `ADV-0001`…`ADV-0586` assignés dans l'ordre de restitution
par l'outil). Vue interactive filtrable/triable : artifact `CP1 collecte brute`.

---

## Total : 586 alertes brutes, 13 règles distinctes

Aucun filtrage, aucun jugement de valeur à ce stade — tableau de rollup par règle (le détail
ligne-par-ligne des 586 alertes, avec objet exact et message complet, est dans le JSON d'évidence
et l'artifact ci-dessus ; le reproduire intégralement ici serait redondant et illisible).

| Règle (nom technique) | Titre | Type | Catégorie | Gravité (native Advisor) | Nb. objets | Doc Advisor |
|---|---|---|---|---|---|---|
| `multiple_permissive_policies` | Multiple Permissive Policies | Performance | PERFORMANCE | WARN | **227** | [lint 0006](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies) |
| `auth_rls_initplan` | Auth RLS Initialization Plan | Performance | PERFORMANCE | WARN | **108** | [lint 0003](https://supabase.com/docs/guides/database/database-linter?lint=0003_auth_rls_initplan) |
| `unused_index` | Unused Index | Performance | PERFORMANCE | INFO | **93** | [lint 0005](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index) |
| `authenticated_security_definer_function_executable` | Signed-In Users Can Execute SECURITY DEFINER Function | Sécurité | SECURITY | WARN | **50** | [lint 0029](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) |
| `anon_security_definer_function_executable` | Public Can Execute SECURITY DEFINER Function | Sécurité | SECURITY | WARN | **47** | [lint 0028](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable) |
| `security_definer_view` | Security Definer View | Sécurité | SECURITY | **ERROR** | **32** | [lint 0010](https://supabase.com/docs/guides/database/database-linter?lint=0010_security_definer_view) |
| `unindexed_foreign_keys` | Unindexed foreign keys | Performance | PERFORMANCE | INFO | **15** | [lint 0001](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys) |
| `function_search_path_mutable` | Function Search Path Mutable | Sécurité | SECURITY | WARN | **6** | [lint 0011](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable) |
| `rls_enabled_no_policy` | RLS Enabled No Policy | Sécurité | SECURITY | INFO | **2** | [lint 0008](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) |
| `extension_in_public` | Extension in Public | Sécurité | SECURITY | WARN | **2** | [lint 0014](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public) |
| `materialized_view_in_api` | Materialized View in API | Sécurité | SECURITY | WARN | **2** | [lint 0016](https://supabase.com/docs/guides/database/database-linter?lint=0016_materialized_view_in_api) |
| `public_bucket_allows_listing` | Public Bucket Allows Listing | Sécurité | SECURITY | WARN | **1** | [lint 0025](https://supabase.com/docs/guides/database/database-linter?lint=0025_public_bucket_allows_listing) |
| `auth_leaked_password_protection` | Leaked Password Protection Disabled | Sécurité | SECURITY (Auth) | WARN | **1** | [docs](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) |

**Répartition** : 434 alertes Performance / 152 alertes Sécurité · 32 ERROR / 512 WARN / 42 INFO.

---

## Constats bruts à instruire au Checkpoint 2 (aucune conclusion tirée ici)

Observation factuelle seule — la classification et le jugement de valeur sont hors périmètre de
ce checkpoint :

- Le Master Plan (`docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2, P2-4) documentait
  **2** vues `SECURITY DEFINER` jugées volontaires (`v_popular_searches`, `v_mv_daily_revenue`).
  L'Advisor en rapporte aujourd'hui **32**, dont `v_popular_searches` fait partie mais 31 autres
  objets (dashboards `v_bi_*`, `v_audit_*`, `v_supabase_dashboard`, etc.) n'y figurent pas.
- `authenticated_security_definer_function_executable` (50) et
  `anon_security_definer_function_executable` (47) : deux règles absentes du Master Plan et des
  ADR existants — aucune décision documentée ne les couvre encore.
- `auth_rls_initplan` était compté à 83 (P2-16, 49 tables) dans le Master Plan ; l'Advisor en
  rapporte 108 aujourd'hui. `multiple_permissive_policies` était à 205 (P2-17, 23 tables) ; il en
  rapporte 227. `unused_index` était à 50 (P3-19) ; il en rapporte 93.
- `unindexed_foreign_keys` (15) : P2-15 documentait 32 FK non indexées déjà corrigées — ces 15
  semblent porter sur des tables différentes (à vérifier au Checkpoint 2).
- `extension_in_public` (`pg_net`, `pg_trgm`) et `auth_leaked_password_protection` : aucune
  mention dans le Master Plan, les ADR ou les politiques de gouvernance existantes.
- `rls_enabled_no_policy` (2) : `rate_limit_buckets` correspond à P3-16 (déjà jugé intentionnel,
  preuve existante). `reminder_dispatch_claims` est un second objet, non couvert par P3-16.
- `public_bucket_allows_listing` (`kynza-media`) correspond à P3-17 (déjà jugé intentionnel,
  preuve existante).

Ces écarts (croissance du nombre d'objets sur des règles déjà connues, apparition de nouvelles
règles) sont probablement dus à la mise en production, entre la rédaction du Master Plan et
aujourd'hui, des sous-systèmes CMS/Remote-Config/Feature-Flags/Legal-Center/Catalog/A-B-Testing/
Observabilité — hypothèse à vérifier au Checkpoint 2, pas à assumer.

**Rien n'a été corrigé. Rien n'a été classifié. Ceci est la collecte brute uniquement.**
