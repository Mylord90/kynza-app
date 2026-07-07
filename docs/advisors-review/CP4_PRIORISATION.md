# Point de Contrôle 4 — Priorisation

**Date** : 2026-07-07. **Entrée** : les classifications du Checkpoint 3
(`docs/advisors-review/CP3_CLASSIFICATION.md`). **Grille** : Critique / Haut / Moyen / Faible /
Informationnel, par cause racine (ou sous-groupe). Seules les causes classées **Vrai problème**
reçoivent une priorité opérationnelle ; les autres (choix d'architecture, faux positif,
recommandation non actionable) sont listées en **Informationnel** pour mémoire, sans travail
attendu. **Aucune correction appliquée à ce stade.**

Colonnes de justification imposées par le prompt : impact multi-tenant, impact RLS, impact
disponibilité, impact conformité (non-custodial), impact performance réelle mesurée.

---

## Priorité Critique

| Cause | Impact multi-tenant | Impact RLS | Impact disponibilité | Impact conformité (non-custodial) | Impact performance | Justification synthétique |
|---|---|---|---|---|---|---|
| **RC-5c** — 30 vues/MV `SECURITY DEFINER` lisibles sans authentification | **Cross-tenant total** — les vues BI/audit agrègent délibérément toutes les données de tous les salons ; aucun filtrage par appelant possible sur un objet non authentifié | RLS **entièrement contourné** par construction (`SECURITY DEFINER` + vue sans `security_invoker`) — c'est exactement le mécanisme que RLS est censé empêcher | Aucun (lecture seule) | **Réel pour `v_audit_rgpd_trail`/`v_audit_user_behavior`** (données potentiellement à caractère personnel exposées sans contrôle) ; pas d'impact sur la garde de fonds elle-même | N/A (dimension sécurité, pas performance) | Correspond exactement au critère **P0** du projet (`BACKEND_GOVERNANCE_GUIDE.md` §5.2) : exploit non authentifié, sans précondition, atteignable aujourd'hui, preuve directe de lignes réelles retournées (2, 1, 6, 2 selon l'objet). |
| **RC-6d** — `claim_pending_action_runs` exécutable par `anon`, aucun garde interne | **Cross-tenant total** — la file d'automatisation n'est pas scopée à un salon, un appelant anonyme peut réclamer des lots couvrant tous les salons | RLS contourné par `SECURITY DEFINER`, mais surtout **aucune vérification de rôle du tout** dans le corps de fonction — pas même une tentative de gate | Réel — un appelant malveillant peut geler/détourner la file de rappels et de workflows automatisés pour l'ensemble de la plateforme | Faible direct (n'écrit pas de transaction financière), mais un rappel de paiement raté est un effet de bord métier réel | N/A | **Cross-tenant data-write sans précondition** — correspond au critère P0 le plus strict (écriture, pas seulement lecture). Non exploité en test (préservation des données réelles), mais grant + absence de garde = preuve suffisante. |

---

## Priorité Haut

| Cause | Impact multi-tenant | Impact RLS | Impact disponibilité | Impact conformité | Impact performance | Justification synthétique |
|---|---|---|---|---|---|---|
| **RC-6c** — `check_system_alerts` exécutable par `anon`, aucun garde interne | Cross-tenant (métriques plateforme entière, pas par salon) | Contourné par `SECURITY DEFINER`, aucun garde applicatif | Faible — écriture protégée par un anti-doublon (`NOT EXISTS`), pas de spam illimité possible | Aucun direct | N/A | Non authentifié et sans précondition (P0-shaped), mais blast radius réellement limité : métriques opérationnelles agrégées (taux d'erreur, taux d'échec paiement), pas de PII ni de données client individuelles — d'où **Haut** plutôt que Critique, en cohérence avec le critère P1/P2 du projet ("blast radius limité"). |

---

## Priorité Moyen

| Cause | Impact multi-tenant | Impact RLS | Impact disponibilité | Impact conformité | Impact performance | Justification synthétique |
|---|---|---|---|---|---|---|
| **RC-4** — 15 FK non indexées (nouvelles tables) | Aucun (perf pure) | Aucun | Aucun aujourd'hui, dégradation progressive à l'échelle | Aucun | Réelle à terme (même mécanisme que P2-15, déjà mesuré) | Correction triviale, faible risque, aucune raison de différer contrairement à RC-1/RC-2 qui exigent une revue policy-par-policy. |
| **RC-8** — 6 fonctions `search_path` mutable | Aucun direct | Aucun | Aucun | Hygiène de sécurité standard (classe d'attaque `search_path` connue, non démontrée ici mais réelle en général) | Aucun | Correction triviale (`SET search_path`), risque de régression quasi nul, coût de report faible mais gain de sécurité réel — pas de raison de le classer plus bas. |
| **RC-11** — Leaked Password Protection désactivée | Aucun (compte par compte) | N/A (réglage Auth, pas RLS) | Aucun | Contrôle de sécurité standard manquant, aucune donnée compromise connue à ce jour | N/A | Activation en un clic (dashboard/Management API), zéro risque de régression fonctionnelle identifié — pas de raison de différer. |

---

## Priorité Faible

| Cause | Impact multi-tenant | Impact RLS | Impact disponibilité | Impact conformité | Impact performance | Justification synthétique |
|---|---|---|---|---|---|---|
| **RC-1** — 108 `auth_rls_initplan` | Aucun (perf pure) | Aucun sur la sémantique, seulement le coût d'évaluation | Aucun | Aucun | **Mesurée dans le passé (P2-16/`SQL_PERFORMANCE_REPORT.md`), actuellement négligeable au trafic quasi nul** | Vrai problème mais déjà délibérément différé — revue policy-par-policy nécessaire, jamais un rewrite en masse (Rule 5). Déclencheur de réévaluation : trafic de production réel mesurable. |
| **RC-2** — 227 `multiple_permissive_policies` | Aucun | Idem RC-1 | Aucun | Aucun | Idem RC-1 | Même raisonnement que RC-1, même déclencheur de réévaluation. |
| **RC-6b (résiduel)** — ~21 RPC dashboard/BI/audit avec grant `anon` mort mais gate interne fonctionnel | Aucun (le gate interne bloque déjà tout accès cross-tenant) | Contourné au niveau grant mais **compensé** par le contrôle applicatif `has_system_admin()` vérifié | Aucun | Aucun | N/A | Hygiène de défense-en-profondeur, pas un exploit — corriger reste utile (fait taire légitimement l'Advisor et retire une couche de risque en cas de régression future du contrôle interne) mais sans urgence. |
| **RC-6e** — `get_all_public_tables` sans garde | Aucun accès aux données, seulement aux noms de tables | Contourné mais objet non sensible | Aucun | Aucun | N/A | Reconnaissance de schéma uniquement, pas de données. Utile à corriger par cohérence (pattern RC-6b) mais faible enjeu réel. |
| **RC-6f** — `create_default_document_templates`, grant mort résiduel | Aucun (le contrôle interne `has_role()` bloque déjà tout accès cross-tenant, confirmé P2-1) | Contourné au niveau grant, compensé par le contrôle applicatif | Aucun | Aucun | N/A | Même raisonnement que RC-6b : hygiène, pas exploit. |
| **RC-7** — `pg_net`/`pg_trgm` dans `public` | Aucun | Aucun | **Risque de régression si le déplacement de schéma est mal exécuté** sur des extensions actives (cron, recherche full-text) | Aucun | Aucun | Recommandation standard Supabase, mais le risque d'une manipulation malvenue dépasse le bénéfice à ce stade — à traiter avec précaution, pas en urgence. |

---

## Priorité Informationnelle (aucune action attendue)

| Cause | Statut | Raison |
|---|---|---|
| RC-3 — 93 `unused_index` | Simple recommandation, non actionable | Trafic quasi nul pré-lancement (P3-19) — déclencheur de réévaluation : trafic réel. |
| RC-5a — `v_popular_searches`, `v_mv_daily_revenue` | Choix d'architecture volontaire, prouvé | P2-4, aucune nouvelle preuve contraire. |
| RC-5b — `v_staff_directory_public` | Choix d'architecture volontaire, prouvé | P0-1, remplacement délibérément public. |
| RC-6a — 8 fonctions `trigger` | Faux positif / limitation Supabase (PostgREST) | HTTP 404 confirmé en live, non exploitable par construction. |
| RC-9 — `rls_enabled_no_policy` ×2 | Choix d'architecture volontaire, prouvé | `rate_limit_buckets` (P3-16) + `reminder_dispatch_claims` (preuve directe CP3). |
| RC-10 — `public_bucket_allows_listing` | Choix d'architecture volontaire, prouvé | P3-17. |

---

## Synthèse pour le Checkpoint 5

Seules les causes classées **Critique**, **Haut** et **Moyen** justifient une fiche de correction
complète au Checkpoint 5 (bénéfices/risques/rollback/dépendances/impacts) :
**RC-5c, RC-6d (Critique) · RC-6c (Haut) · RC-4, RC-8, RC-11 (Moyen)**.

Les causes **Faible** restent éligibles à correction si le porteur du projet le souhaite (fiches
disponibles sur demande), mais ne sont pas proposées par défaut dans le plan de correction
principal, conformément à la règle "ne jamais chercher artificiellement un zéro avertissement."
