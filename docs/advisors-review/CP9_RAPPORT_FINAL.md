# Point de Contrôle 9 — Rapport d'entreprise final

**Session** : Traitement scientifique des alertes Supabase Advisors — KYNZA, backend en mode
maintenance (`backend-baseline-v1`). **Date** : 2026-07-07. **Projet** : `hhdkjfpgaklhrhfoxlhj`
(production, `eu-central-1`), validé au préalable sur `kynza-dr-scratch` (`hzjmyeptytvjmzbnsmwp`).
**Documents sources** (jamais réécrits silencieusement, seulement complétés par addenda datés) :
`CP1_COLLECTE_BRUTE.md`, `CP2_CAUSES_RACINES.md`, `CP3_CLASSIFICATION.md` (+ addendum),
`CP4_PRIORISATION.md`, `CP5_PLAN_CORRECTION.md` (+ Fiche 6 révisée), `CP6_EXECUTION_LOG.md`.

**Verdict de clôture** : **le Checkpoint 6 est clos pour tout ce qui relève de la portée
technique.** 5 des 6 corrections retenues sont vivantes en production, preuve à l'appui pour
chacune. Le 6ᵉ item (RC-11) n'est pas clos, mais **pas pour une raison technique** — voir §9.

---

## 1. Toutes les alertes initiales (Checkpoint 1)

**586 alertes brutes**, 13 règles distinctes, collectées via
`supabase db advisors --linked --type all --level info` contre la production, sans filtrage ni
jugement de valeur. Détail exhaustif (586 lignes, un ID `ADV-0001`…`ADV-0586` par alerte) :
`docs/advisors-review/evidence/CP1_advisors_hhdkjfpgaklhrhfoxlhj_2026-07-07.json` +
`CP1_COLLECTE_BRUTE.md`.

| Règle | Type | Gravité native | Nb. |
|---|---|---|---|
| `multiple_permissive_policies` | Performance | WARN | 227 |
| `auth_rls_initplan` | Performance | WARN | 108 |
| `unused_index` | Performance | INFO | 93 |
| `authenticated_security_definer_function_executable` | Sécurité | WARN | 50 |
| `anon_security_definer_function_executable` | Sécurité | WARN | 47 |
| `security_definer_view` | Sécurité | **ERROR** | 32 |
| `unindexed_foreign_keys` | Performance | INFO | 15 |
| `function_search_path_mutable` | Sécurité | WARN | 6 |
| `rls_enabled_no_policy` | Sécurité | INFO | 2 |
| `extension_in_public` | Sécurité | WARN | 2 |
| `materialized_view_in_api` | Sécurité | WARN | 2 |
| `public_bucket_allows_listing` | Sécurité | WARN | 1 |
| `auth_leaked_password_protection` | Sécurité (Auth) | WARN | 1 |

---

## 2. Causes racines identifiées (Checkpoint 2)

Les 586 alertes se ramènent à **11 causes racines**. Détail complet, avec plage d'ID Advisor par
cause : `CP2_CAUSES_RACINES.md`.

| # | Cause | Nb. objets | Nature |
|---|---|---|---|
| RC-1 | RLS `auth.<fn>()` non wrappé en `(select …)` | 108 | Performance, connu (P2-16) |
| RC-2 | Policies multiples par rôle/action | 227 | Performance, connu (P2-17) |
| RC-3 | Index jamais utilisés (trafic quasi nul) | 93 | Non-actionable (P3-19) |
| RC-4 | FK non indexées (nouvelles tables) | 15 | Performance, **traité** |
| RC-5 | Vues/MV `SECURITY DEFINER` exposées | 34 (32+2) | Sécurité, **partiellement traité** |
| RC-6 | Fonctions `SECURITY DEFINER` exécutables par `anon` | 97 brutes (~50 fn) | Sécurité, **partiellement traité** |
| RC-7 | Extensions dans `public` | 2 | Hygiène, non traité |
| RC-8 | `search_path` non fixé | 6 | Sécurité, **traité** |
| RC-9 | RLS activé sans policy | 2 | Volontaire, prouvé |
| RC-10 | Bucket public listable | 1 | Volontaire, prouvé |
| RC-11 | Leaked Password Protection désactivée | 1 | **Différé — dépendance plan** |

---

## 3. Corrections effectivement appliquées, avec commits

**5 corrections vivantes en production**, chacune testée d'abord sur `kynza-dr-scratch`, appliquée
en production **une par une**, avec accord explicite avant chaque item (Rule 8), jamais
d'enchaînement automatique.

| # | Correction | Commit dr-scratch | Commit prod (identique, appliqué séparément) | SQL |
|---|---|---|---|---|
| RC-4 | 15 `CREATE INDEX` | `86f21b8` | même migration, poussée séparément en prod | `20260707100000_advisors_rc4_unindexed_fk.sql` |
| RC-8 | 6 `ALTER FUNCTION … SET search_path` | `53c9041` | idem | `20260707110000_advisors_rc8_search_path_mutable.sql` |
| RC-6c+RC-6d | `REVOKE EXECUTE` sur `check_system_alerts`/`claim_pending_action_runs` | `8d9350a` | idem | `20260707120000_advisors_rc6c_rc6d_revoke_execute.sql` |
| RC-5c | `REVOKE ALL` sur 31 vues/MV `SECURITY DEFINER` | `1ac5368` | idem | `20260707130000_advisors_rc5c_revoke_select_definer_views.sql` |

*(Une seule migration par fichier ; l'application en production a réutilisé le même fichier,
poussé isolément à chaque tour d'approbation — pas de commit distinct côté production, la preuve
d'application production est journalisée dans `CP6_EXECUTION_LOG.md`, section « Application en
production ».)*

Documents de gouvernance associés : `ebe7d10` (docs CP1-5), `10795f1` (CP6 log + addendum CP3),
`e3c7d30` (Fiche 6 révisée), `3f8e797` (CP6 log — application prod), `cd86268` (CP6 log — identité
temporaire), `c35e85b` (ticket P2-29).

---

## 4. Preuves de validation (Checkpoint 7)

Pour chacune des 5 corrections, sur `kynza-dr-scratch` **et** en production séparément : un test
négatif (l'exploit documenté au Checkpoint 3 ne fonctionne plus), un test positif (le chemin
légitime fonctionne toujours, testé de bout en bout avec un appelant réel, pas seulement l'absence
d'erreur SQL), et pour RC-5c spécifiquement un test d'écriture dédié.

### RC-4 — 15 index
- Présence confirmée (`pg_indexes`, 15/15) en staging et en production.
- Test fonctionnel = présence de l'index (convenu, pas d'écriture applicative dépendante).

### RC-8 — `search_path` ×6
- `pg_proc.proconfig` confirme `search_path=public, pg_temp` sur les 6 fonctions, staging et prod.
- **Test fonctionnel réel** : `UPDATE public.salons SET name = name` sur une ligne réelle →
  `updated_at` incrémenté, `trigger_fired: true` — staging et production, chaque fois sur une
  vraie ligne, résultat identique.

### RC-6c + RC-6d — `check_system_alerts` / `claim_pending_action_runs`
- `proacl` post-fix : `{postgres, service_role}` uniquement, staging et prod.
- **Test négatif** : `POST /rest/v1/rpc/<fn>` avec la clé publique seule → `401 42501 permission
  denied` sur les deux fonctions, staging et prod.
- **Test positif** : secret `cron_secret` lu directement depuis `vault.decrypted_secrets` du
  projet concerné (mécanisme propre au projet, aucune extraction d'identifiants tiers) ;
  `run-scheduled-actions` et `check-system-alerts` déclenchées via
  `Authorization: Bearer <service_role_key>` + `X-Cron-Secret: <cron_secret>` réels → `200` pour
  les deux, staging et production, aucune régression.

### RC-5c — 31 vues/MV `SECURITY DEFINER`
- `relacl` post-fix : seuls `postgres`/`service_role` restent sur les 31 objets, staging et prod.
- **Test négatif générique** : `GET` non authentifié sur 6 objets échantillonnés (dont les 4 qui
  exposaient de vraies lignes en production au Checkpoint 3) → `401 42501`, staging et prod.
- **Test d'écriture dédié** (le plus critique de cette correction — demandé explicitement avant
  clôture) : tentative d'`INSERT` non authentifié sur les 3 vues structurellement auto-updatable
  (`v_audit_financial_accounting`→`invoices`, `v_audit_security_trail`→`activity_logs`,
  `v_security_dashboard`→`rate_limit_buckets`) → `401 42501` pour les 3, **en production**.
  Vérification défensive par `count(*)` filtré sur les valeurs de test envoyées → **0 ligne
  écrite dans les 3 tables**, confirmé directement, pas déduit du seul code HTTP.
- **Test positif — chemin RPC légitime** : sur `kynza-dr-scratch`, session réelle générée pour la
  fixture QA existante (`kynza.qa.sysadmin.cp1@example.com`). **En production**, aucun
  `system_admin` réel n'existait — une identité de test temporaire a été créée, exercée puis
  intégralement supprimée (détail complet et distinct au §8). Dans les deux environnements :
  `get_supabase_dashboard()`/`get_bi_revenue()`/`get_audit_security_trail()` → `200`, données
  réelles retournées sans erreur, chemin gated intégralement fonctionnel après révocation.

---

## 5. Résultats du rejeu Advisors (Checkpoint 8)

Comparateur avant/après, **production**, par catégorie corrigée :

| Item | Alertes avant | Alertes après | Alertes supprimées | Nouvelles alertes apparues |
|---|---|---|---|---|
| RC-4 | `unindexed_foreign_keys` = 15 | 0 | 15 | 0 |
| RC-8 | `function_search_path_mutable` = 6 | 0 | 6 | 0 |
| RC-6c+RC-6d | `anon_security_definer_function_executable` = 47, `authenticated_…` = 50 | 45, 48 | 2 + 2 = 4 | 0 |
| RC-5c | `security_definer_view` = 32, `materialized_view_in_api` = 2 | 3 (exclusions), 0 | 29 + 2 = 31 | 0 |

**Total : 56 alertes brutes fermées en production, 0 nouvelle alerte introduite par une
correction.**

---

## 6. Alertes restantes et pourquoi

| Cause | Statut | Raison |
|---|---|---|
| RC-1 (`auth_rls_initplan`, 108) | Ouvert, délibérément | Impact réel mais négligeable au trafic actuel ; revue policy-par-policy nécessaire, jamais un rewrite en masse (Rule 5). Déclencheur de réévaluation : trafic de production réel mesurable. |
| RC-2 (`multiple_permissive_policies`, 227) | Ouvert, délibérément | Même raisonnement que RC-1. |
| RC-3 (`unused_index`, 93) | Ouvert, non-actionable | Trafic quasi nul pré-lancement (P3-19). Déclencheur : trafic réel. |
| RC-6b résiduel (~21 RPC dashboard/BI/audit, grant mort mais gate interne fonctionnel) | Ouvert, faible priorité | Hygiène de défense-en-profondeur, pas un exploit — le grant est un résidu, le contrôle `has_system_admin()` protège déjà. |
| RC-6e (`get_all_public_tables`) | Ouvert, faible priorité | Reconnaissance de schéma uniquement, pas de données. |
| RC-6f (`create_default_document_templates`) | Ouvert, faible priorité | Fonctionnellement fermé par P2-1 (contrôle interne), grant résiduel non nettoyé. |
| RC-7 (`extension_in_public`, 2) | Ouvert | Extensions déjà actives en production (`pg_net` pour le cron, `pg_trgm` pour la recherche) — déplacement de schéma comporte un risque réel si mal exécuté, non urgent. |
| RC-11 (`auth_leaked_password_protection`) | **Différé** | Voir §9 — dépendance business (plan Pro), pas un blocage technique. |

---

## 7. Faux positifs identifiés

| Cause | Objets | Preuve |
|---|---|---|
| RC-6a | 8 fonctions de type `trigger` (`auto_document_templates`, `create_default_salon_settings`, `increment_monthly_bookings_count`, `increment_monthly_bookings_count_stmt`, `invalidate_permission_cache_for_group`, `invalidate_permission_cache_for_row`, `prevent_staff_removal_with_future_bookings`, `protect_review_columns`, `trigger_create_default_automation_workflows`, `trigger_create_version`, `version_cms_content`) | Grant `anon`/`authenticated` techniquement présent côté SQL, mais **inexploitable par construction** : PostgREST exclut structurellement les fonctions de retour `trigger` de son cache RPC. Preuve live : `POST /rest/v1/rpc/protect_review_columns` → `HTTP 404, PGRST202`. |

---

## 8. Limitations Supabase connues, rencontrées pendant cette session

| Limitation | Impact | Détail |
|---|---|---|
| `supabase config push` n'a **aucune granularité de champ** — il pousse un diff de section `[auth]` entière, jamais un champ isolé | A causé un incident réel (voir ci-dessous) | Détail complet, séquence et correctif : `CP6_EXECUTION_LOG.md`, section RC-11. |
| `password_hibp_enabled` absent du schéma `config.toml` de la CLI 2.107.0 alors que le champ existe côté API Management | A contribué à l'incident ci-dessus (confusion sur la cause de l'échec initial) | Confirmé par recherche documentaire : le nom de champ était correct, seul le schéma local de la CLI ne le reconnaît pas. |
| Aucune commande CLI de lecture seule pour la configuration Auth distante | M'a empêché de vérifier `password_hibp_enabled` sans risquer un effet de bord | `supabase inspect` ne couvre que la base de données. Aucune sous-commande `auth` en lecture. |
| PostgREST exclut les fonctions de retour `trigger` de son cache RPC | Rend RC-6a structurellement non-exploitable (faux positif, voir §7) | Comportement plateforme, pas KYNZA. |
| Leaked Password Protection (HaveIBeenPwned) est **réservé aux plans Pro et supérieurs** | Bloque RC-11 techniquement, quelle que soit la méthode d'application | Message d'erreur Supabase explicite, confirmé par Mylord en tentant l'activation Dashboard. |

### Incident RC-11 — résumé (détail complet dans `CP6_EXECUTION_LOG.md`)
Une tentative d'application de RC-11 via `config.toml`/`config push` a poussé, avant d'échouer sur
une étape sans rapport, un diff Auth complet sur `kynza-dr-scratch` — 9 champs sans rapport avec
RC-11 modifiés (MFA, confirmations email, OTP, `site_url`, templates). Restauré champ par champ
avec vérification individuelle, confirmé par un diff nul sur l'ensemble de `[auth]`. Mécanisme
exclu pour toute correction Auth future — remplacé par une séquence API Management directe
(GET → PATCH scopé → GET, Fiche 6 révisée) dans le plan, elle-même désormais sans objet puisque
RC-11 est bloqué en amont par le plan tarifaire.

---

## 9. RC-11 — statut différé, dépendance business (pas un blocage technique)

**Distinction explicite demandée et actée** : RC-11 n'est **pas** dans la même catégorie que les 5
corrections closes ci-dessus. Ce n'est pas une action en attente de ma part, ni un travail
d'ingénierie restant — le mécanisme applicatif est prêt (Fiche 6 révisée, séquence GET/PATCH/GET
documentée), mais la fonctionnalité elle-même (Leaked Password Protection / HaveIBeenPwned) est
**indisponible sur le plan Supabase actuel** (Free), confirmée directement par le message d'erreur
du Dashboard lors de la tentative d'activation par Mylord : *"leaked password protection via
HaveIBeenPwned.org is available on Pro Plans and up."*

**Décision (Mylord)** : passage au plan Pro prévu ultérieurement, hors du périmètre de cette
session. **Statut : Différé — dépendance business (upgrade plan Pro), date d'activation non
fixée.** La Fiche 6 révisée (`CP5_PLAN_CORRECTION.md`) reste valide et prête à exécuter dès que le
plan sera actif — aucune reprise d'analyse nécessaire à ce moment-là.

---

## 10. P2-29 — constat hors périmètre (journal d'audit natif GoTrue vide)

**Découverte incidente**, pas liée aux 6 alertes traitées : en documentant le mécanisme de
l'identité `system_admin` temporaire utilisée pour le test positif de RC-5c en production (aucune
fixture admin réelle n'existait en production, contrairement à `kynza-dr-scratch`), il a été
constaté que `auth.audit_log_entries` (journal d'audit natif de GoTrue) contient **0 ligne au
total sur l'ensemble du projet de production** — pas seulement pour cette identité.

**Mécanisme exact de l'identité de test** (documenté comme action à part, per demande explicite) :
1. Création via `POST /auth/v1/admin/users` (Auth Admin API, `service_role`) — écrit dans
   `auth.users`, synchronisation automatique vers `public.users` (mécanisme préexistant).
2. Élévation `is_system_admin = true` via `UPDATE` SQL direct (`postgres`/`service_role`), **pas**
   via la RPC `grant_system_admin()` — cette RPC exige elle-même un appelant déjà `system_admin`,
   inutilisable pour créer le tout premier admin. Conséquence : `system_admin_audit` (table
   applicative alimentée normalement par cette RPC) est restée à 0 ligne pour cette action.
3. Session réelle via `POST /auth/v1/admin/generate_link` (magiclink) + `POST /auth/v1/verify`.
4. Suppression via `DELETE /auth/v1/admin/users/{id}` — cascade confirmée, `auth.users` et
   `public.users` à 0 pour cet ID après coup.
5. **Confirmation de non-pollution** : `activity_logs`/`v_audit_security_trail` relues après
   suppression — exactement les 2 mêmes lignes légitimes déjà connues, aucune trace de l'identité
   de test (aucune des 4 étapes ci-dessus ne passe par le chemin applicatif `logActivity()`).

**Classification** : Vrai problème, gravité P2 — pas d'exploit live, mais un vrai manque de
capacité de réponse à incident (aucune trace native des actions admin console si certaines ont eu
lieu hors des chemins de journalisation applicatifs). Deux hypothèses non départagées :
mécanisme désactivé/non configuré au niveau plateforme, ou jamais sollicité par une action console
(les actions Admin-API/SQL de cette session ne l'alimentent pas non plus, à eux seuls insuffisant
pour trancher). **Constat uniquement — aucune investigation ni correction tentée**, hors du
périmètre de cette session.

**Ticket créé** : `P2-29` dans `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2, suivant
la règle du projet (compteur unique par préfixe, `BACKEND_GOVERNANCE_GUIDE.md` §1.2), ajouté dans
la même session que sa découverte. Statut : **Ouvert**, en attente d'une décision dédiée.

---

## 11. Reclassification de gravité — RC-5c (leçon de gouvernance)

**À distinguer explicitement, per demande de Mylord** : la gravité perçue au moment de la
priorisation (Checkpoint 4) n'était pas la gravité réelle découverte pendant l'exécution
(Checkpoint 6) — ce n'est pas un simple changement de portée technique (`REVOKE SELECT` →
`REVOKE ALL`), c'est une **révision de gravité**, et elle mérite d'être conservée comme leçon.

**Gravité perçue au Checkpoint 4** : RC-5c classée **Critique**, sur la base d'une **exposition en
lecture** — le Checkpoint 3 avait testé et prouvé que des appelants non authentifiés pouvaient
`SELECT` des lignes réelles (2 pour `v_audit_security_trail`, 1 pour `v_audit_fraud_proxipay`, 6
pour `mv_audit_stats`, 2 pour `mv_daily_revenue`). La priorisation Critique reposait sur ce
périmètre : lecture cross-tenant non authentifiée de données financières/d'audit.

**Gravité réelle découverte au Checkpoint 6** : en vérifiant la portée du changement `REVOKE
SELECT` → `REVOKE ALL` (demandé par Mylord avant d'approuver la correction), il a été établi que
`anon`/`authenticated` détenaient en réalité `INSERT`/`UPDATE`/`DELETE`/`REFERENCES`/`TRUNCATE`/
`TRIGGER` sur les 31 objets — pas seulement `SELECT`. Vérification structurelle
(`information_schema.views.is_insertable_into`/`is_updatable`) a montré que **3 des 29 vues**
(`v_audit_financial_accounting`→`invoices`, `v_audit_security_trail`→`activity_logs`,
`v_security_dashboard`→`rate_limit_buckets`) sont des `SELECT` simples sans agrégation, donc
**structurellement auto-updatable par Postgres** — pas de simple grant mort. Combiné à
`SECURITY DEFINER` (contourne RLS sur la table réelle), c'était une **voie d'écriture non
authentifiée réelle** vers des tables financières (`invoices`) et d'audit sécurité
(`activity_logs`) — confirmée exploitable par un test d'écriture dédié post-fix (rejet `401`,
zéro ligne écrite lors de la tentative), pas seulement une exposition en lecture.

**Ce que ceci signifie pour la méthode, pas seulement pour RC-5c** : le Checkpoint 3 (classification
prouvée) et le Checkpoint 4 (priorisation) reposaient tous deux sur un test de lecture uniquement
(`GET`/`SELECT`). Aucune vérification d'écriture n'avait été systématiquement conduite sur les
objets `SECURITY DEFINER` avant l'exécution. La gravité réelle (écriture non authentifiée sur des
tables sensibles) n'a été découverte qu'en vérifiant la portée exacte des grants juste avant
application — une étape que Mylord a explicitement demandée par prudence, pas une étape prévue par
défaut dans la méthode initiale des Checkpoints 3-4.

**Recommandation pour les futures sessions de ce type** : quand un objet `SECURITY DEFINER`
(vue ou fonction) est identifié comme lisible sans autorisation, vérifier systématiquement
**tous** les privilèges détenus (`INSERT`/`UPDATE`/`DELETE`/`REFERENCES`/`TRUNCATE`, pas seulement
`SELECT`) **et** l'updatabilité structurelle de l'objet (`information_schema.views.is_updatable`
pour les vues) **avant** la classification/priorisation, pas seulement avant l'application de la
correction — cela aurait dû faire remonter RC-5c en gravité dès le Checkpoint 3, pas seulement au
Checkpoint 6.

---

## 12. Récapitulatif final

| Catégorie | Décompte |
|---|---|
| Alertes brutes collectées (Checkpoint 1) | 586 |
| Causes racines (Checkpoint 2) | 11 |
| Vrai problème, corrigé et vivant en production | RC-4, RC-8, RC-6c, RC-6d, RC-5c (56 alertes brutes fermées) |
| Vrai problème, différé (dépendance business, pas technique) | RC-11 (1 alerte) |
| Vrai problème, ouvert délibérément (déjà connu, hors urgence) | RC-1, RC-2, RC-3, RC-6b résiduel, RC-6e, RC-6f, RC-7 (~450 alertes brutes, dont 93 non-actionables RC-3) |
| Choix d'architecture volontaire, prouvé | RC-5a, RC-5b, RC-9, RC-10 (6 alertes) |
| Faux positif / limitation Supabase | RC-6a (16 alertes brutes) |
| Nouveau finding hors périmètre, non traité | P2-29 |

**Zéro régression introduite** (preuve : tests fonctionnels réels positifs pour chaque correction,
staging et production). **Zéro contrainte architecturale violée** (`salon_id` JWT-dérivé, RLS
partout, soft-delete, unicité `AtomicClaimService`/`readBodyGuarded()` — aucune n'a été touchée par
ces 5 corrections, toutes de nature grants/config). **Chaque décision est traçable à une preuve**
(586 alertes classées avec justification, 5 corrections avec test négatif + positif + comparateur
Advisors avant/après, staging et production). **Un tiers auditeur peut comprendre, sans recontacter
personne**, pourquoi chaque alerte a été traitée ou laissée de côté — via ce document et les 6
documents `CP1`-`CP6` qu'il consolide.

**Checkpoint 6 clos pour la portée technique. Session close, sous réserve de la reprise ultérieure
de RC-11 (plan Pro) et d'une éventuelle session dédiée pour P2-29.**
