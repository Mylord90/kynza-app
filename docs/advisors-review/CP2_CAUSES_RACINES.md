# Point de Contrôle 2 — Déduplication et causes racines

**Date** : 2026-07-07. **Entrée** : les 586 alertes du Checkpoint 1
(`docs/advisors-review/CP1_COLLECTE_BRUTE.md`). **Méthode** : pour chaque groupe de règles,
lecture directe des migrations SQL sources (`supabase/migrations/`) + requêtes en lecture seule
contre le projet de production `hhdkjfpgaklhrhfoxlhj` (introspection `pg_catalog`/
`information_schema`, et pour deux causes, une requête HTTP REST non-authentifiée en lecture seule
avec `limit=0`/`count=exact` pour prouver l'accessibilité sans jamais exfiltrer de contenu réel).
**Aucune correction appliquée. Aucune classification finale (Checkpoint 3) rendue ici** — ce
document établit la cause, pas le verdict.

---

## ⚠️ Deux causes racines nécessitent une attention prioritaire (RC-5, RC-6)

Preuve directe et reproduite (détaillée en RC-5/RC-6 ci-dessous) que des objets `SECURITY
DEFINER` conçus pour être protégés par une vérification applicative (`has_system_admin()`, ou
aucune vérification du tout) sont en réalité **atteignables aujourd'hui par un appelant non
authentifié**, en production, avec la seule clé publique `anon`/`publishable`. Ceci correspond
au critère **P0** de `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` §5.2 ("exploit non authentifié,
sans précondition, atteignable aujourd'hui"). Rien n'a été corrigé ni exploité au-delà de la
preuve minimale nécessaire (comptage de lignes, jamais leur contenu ; aucune mutation exécutée
sur les fonctions qui écrivent des données). Classification formelle et gravité au Checkpoint 3/4,
mais je signale la sévérité dès maintenant plutôt que d'attendre la fin du pipeline.

---

## Matrice des causes racines

| # | Cause racine | Alertes associées (IDs) | Nb. objets | Hypothèse de cause (preuve) |
|---|---|---|---|---|
| RC-1 | Policies RLS appelant `auth.<fn>()` directement au lieu de `(select auth.<fn>())` dans leur corps — force PostgreSQL à ré-évaluer la fonction à chaque ligne. | `auth_rls_initplan` — ADV-0001..ADV-0108 | 108 (≈60 tables) | Confirmé par lecture directe des `detail` de l'Advisor (cite la policy exacte et la table). Cause déjà connue et délibérément non corrigée en masse (Master Plan P2-16, 83→108 : la hausse vient des tables des sous-systèmes déployés depuis). |
| RC-2 | Design RLS en policies séparées par rôle pour une même table+action (`owner_manage_X`, `staff_own_X`, `client_own_X` coexistant comme policies permissives distinctes) au lieu d'une policy combinée. | `multiple_permissive_policies` — ADV-0109..ADV-0335 | 227 (23+ tables) | Confirmé par lecture directe des `detail`. Cause déjà connue (Master Plan P2-17, 205→227, même hausse structurelle que RC-1). |
| RC-3 | Trafic de production quasi nul avant lancement réel — tout index, même utile à terme, apparaît "jamais utilisé" dans `pg_stat_user_indexes`. | `unused_index` — ADV-0351..ADV-0443 | 93 | Cause déjà actée et documentée comme non-actionnable pré-lancement (Master Plan P3-19, 50→93 : hausse purement due aux nouveaux index créés par les sous-systèmes récents, pas à une régression). |
| RC-4 | Tables des 6 sous-systèmes récemment mis en production (CMS, Remote Config, Feature Flags, Legal Center, Catalog, A/B Testing, Business Observability, Audit) créées avec des colonnes FK sans index de couverture — même lacune que celle déjà corrigée pour les 32 FK originales (P2-15), jamais étendue à ces nouvelles tables. | `unindexed_foreign_keys` — ADV-0336..ADV-0350 | 15 (ex. `cms_content_versions`, `experiment_assignments`, `experiment_events`) | Confirmé par `detail` Advisor citant chaque FK exacte ; ces noms de table n'existaient pas au moment de la correction P2-15 (2026-07-06). |
| **RC-5** | **Vues agrégées cross-tenant (BI, audit, dashboards ops) construites pour n'être consultées qu'via une RPC `SECURITY DEFINER` gated par `has_system_admin()` — mais la vue brute sous-jacente n'a jamais reçu de `REVOKE SELECT ... FROM anon, authenticated`, et PostgREST expose par défaut tout objet du schéma `public`. Une vue sans `security_invoker=true` s'exécute avec les droits du propriétaire, contournant entièrement RLS.** | `security_definer_view` — ADV-0555..ADV-0586 ; `materialized_view_in_api` — ADV-0550..ADV-0551 | 32 + 2 | **Preuve live (lecture seule)** : requête `pg_catalog`/`information_schema.role_table_grants` confirme `anon:SELECT` accordé sur `v_bi_revenue`, `v_supabase_dashboard`, `v_audit_security_trail`, `v_audit_financial_accounting`, `v_popular_searches`, `v_staff_directory_public`. Requête REST non-authentifiée (`apikey` publishable seul, sans JWT) confirmée : `GET /rest/v1/v_supabase_dashboard?limit=1` → **HTTP 200**, retourne de vraies métadonnées internes (table_count, policy_count…). `GET /rest/v1/v_audit_security_trail?limit=0&Prefer=count=exact` → **HTTP 206, Content-Range `*/2`** (2 lignes réelles accessibles). `GET /rest/v1/v_audit_fraud_proxipay` → **HTTP 206, `*/1`** (1 ligne réelle). `v_bi_revenue`/`v_bi_commissions`/`v_audit_financial_accounting` → HTTP 200, `*/0` (accessibles mais vides, cohérent avec le trafic quasi nul actuel — l'exposition existe même si son contenu est aujourd'hui pauvre). Le commentaire de code lui-même (`20260704120000_observability_system_admin.sql:176`) documente l'intention exacte que ceci contredit : *"Plain Postgres views cannot carry RLS themselves. Rather than GRANT SELECT [directement]…"* — l'auteur savait que la vue ne devait pas être exposée directement, mais n'a jamais posé le `REVOKE`. |
| **RC-6** | **Fonctions `SECURITY DEFINER` censées être réservées à `service_role`/`system_admin`, mais exécutables par `anon`/`authenticated` via un mécanisme en deux variantes distinctes : (a) `REVOKE EXECUTE ... FROM anon` appliqué mais pas `FROM PUBLIC` — `anon` hérite implicitement du grant PUBLIC (`=X/postgres` dans l'ACL), donc le REVOKE ciblé est un no-op ; (b) aucun REVOKE écrit du tout — la fonction garde son grant `anon=X/postgres` explicite d'origine.** | `anon_security_definer_function_executable` — ADV-0444..ADV-0490 ; `authenticated_security_definer_function_executable` — ADV-0492..ADV-0541 | 47 + 50 (fort recouvrement, ~50 fonctions distinctes) | **Preuve live (lecture seule)**, variante (a) : `get_bi_revenue`, `get_audit_security_trail`, `get_supabase_dashboard` ont `proacl` contenant `=X/postgres` (grant PUBLIC implicite jamais révoqué) → `has_function_privilege('anon', …, 'EXECUTE')` = **true**, malgré un `REVOKE EXECUTE … FROM anon` explicite écrit dans `20260704150000_business_observability_schema.sql`/`20260704170000_audit_business.sql`/`20260704120000_observability_system_admin.sql` — révoquer d'un rôle qui n'a jamais eu de grant direct ne retire pas l'accès hérité de PUBLIC. Variante (b) : `claim_pending_action_runs` et `grant_system_admin` ont `anon=X/postgres` **explicite** dans leur ACL malgré une migration qui ne fait que `GRANT … TO service_role` sans jamais écrire `REVOKE … FROM anon` — origine du grant `anon` d'origine non retrouvée dans les migrations trackées (probablement un privilège par défaut posé au bootstrap de la plateforme Supabase, hors du contrôle de version). **Aggravant confirmé pour `claim_pending_action_runs`** : le corps de fonction (`pg_get_functiondef`) ne contient **aucune vérification de rôle/appelant** — un `UPDATE … SET status='processing'` sans garde. Non exécuté (muterait des données réelles) ; le grant ACL + l'absence de contrôle dans le code source constituent une preuve suffisante et non-intrusive. |
| RC-7 | Extensions installées via `CREATE EXTENSION IF NOT EXISTS x;` sans clause `SCHEMA`, atterrissant par défaut dans `public` au lieu d'un schéma dédié. | `extension_in_public` — ADV-0542..ADV-0543 | 2 (`pg_net`, `pg_trgm`) | Confirmé : les 4 occurrences de `CREATE EXTENSION` pour ces deux extensions dans les migrations n'ont aucune clause `SCHEMA`. |
| RC-8 | Fonctions utilitaires/triggers écrites avant l'adoption de la discipline `SET search_path` (établie plus tard, même esprit que l'ADR-0005 pour `readBodyGuarded()`) et jamais mises à niveau. | `function_search_path_mutable` — ADV-0544..ADV-0549 | 6 (`update_updated_at`, `check_journey_complete`, `init_owner_journey`, …) | Cohérent avec la chronologie des migrations (fonctions parmi les plus anciennes du dépôt, avant `20260627150000_adv6_security_hardening.sql` qui introduit la discipline pour les fonctions plus récentes). À confirmer précisément par date de création au Checkpoint 3. |
| RC-9 | RLS activé sans aucune policy — **volontaire**, deny-by-default documenté en commentaire pour des tables où seul `service_role` opère. | `rls_enabled_no_policy` — ADV-0553..ADV-0554 | 2 (`rate_limit_buckets`, `reminder_dispatch_claims`) | `rate_limit_buckets` déjà jugé et fermé (Master Plan P3-16). `reminder_dispatch_claims` : commentaire trouvé dans `20260705100000_cp0_concurrency_atomic_claims.sql:86-88` — *"No policies — only service_role (schedule-reminders) ever touches this table, same deny-all-by-omission pattern as data_deletion_requests"* — même pattern, jamais formellement verdicté (P3-16 ne couvrait que `rate_limit_buckets`). |
| RC-10 | Bucket public avec policy SELECT large permettant le listing — **volontaire**, images de salon publiques. | `public_bucket_allows_listing` — ADV-0552 | 1 (`kynza-media`) | Déjà jugé et fermé (Master Plan P3-17). |
| RC-11 | Réglage projet Auth "Leaked Password Protection" jamais activé dans la configuration Supabase Auth — **n'est pas un artefact de migration/schéma**, c'est un paramètre de projet distinct qu'aucune migration SQL ne peut adresser. | `auth_leaked_password_protection` — ADV-0491 | 1 | De nature différente de toutes les autres causes : nécessite une action dans la configuration Auth du projet (dashboard/Management API), pas une migration. |

---

## Sous-constats notables issus de la vérification (pour le Checkpoint 3)

- **`get_staff_week_rank` (P3-15, déjà "Fermé preuve")** : vérifié à nouveau — `proacl` ne contient
  ni grant PUBLIC ni grant `anon` explicite. Son apparition dans
  `authenticated_security_definer_function_executable` est **attendue et correcte** (les
  utilisateurs authentifiés — le staff — ont légitimement besoin d'y accéder) ; ce n'est pas une
  régression du fix P3-15, qui tenait uniquement sur le retrait de l'accès `anon`.
- **`create_default_document_templates` (P2-1, déjà "Fermé preuve" pour l'exploit)** : le fix
  réel (`20260704210000_cp11_hardening_batch.sql`) a ajouté un contrôle interne
  (`has_role(auth.uid(), 'owner'/'manager', p_salon_id)` sinon `RAISE EXCEPTION 'forbidden'`),
  ce qui ferme bien l'exploit fonctionnellement — confirmé par le Master Plan ("anon RPC call now
  returns 403"). Mais le grant `anon=X/postgres` brut n'a jamais été nettoyé (contrairement à
  `get_staff_week_rank` traité dans le même fichier) : un appel anonyme atteint la fonction et se
  fait rejeter par le contrôle interne, au lieu d'être rejeté par PostgreSQL lui-même. Résidu réel
  mais de gravité bien moindre qu'une exploitation active — à documenter comme tel, pas comme
  vulnérabilité vivante.

**Rien n'a été corrigé. Ceci établit les causes, pas leur verdict.** Classification prouvée
(vrai problème / faux positif / choix d'architecture / limitation) au Checkpoint 3.
