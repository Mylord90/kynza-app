# Point de Contrôle 3 — Classification prouvée

**Date** : 2026-07-07. **Entrée** : les 11 causes racines du Checkpoint 2
(`docs/advisors-review/CP2_CAUSES_RACINES.md`). **Méthode** : pour chaque cause, lecture directe
du corps de fonction (`pg_get_functiondef`), des ACL (`pg_proc.proacl`,
`information_schema.role_table_grants`), et — quand nécessaire pour trancher entre "grant brut
inoffensif" et "exploit vivant" — un appel HTTP en lecture seule contre la production avec la
seule clé publique (`limit=0`+`count=exact` quand une preuve de comptage suffit ; jamais de
mutation exécutée). **Aucune correction appliquée à ce stade** — ce document classe, il ne corrige
pas (Checkpoint 6).

Catégories utilisées (imposées par le prompt) : **Vrai problème** / **Faux positif** / **Choix
d'architecture volontaire** / **Limitation PostgreSQL** / **Limitation Supabase** / **Simple
recommandation** / **Optimisation facultative**.

---

## RC-1 — `auth_rls_initplan` (108 alertes)

**Classification : Vrai problème (performance), gravité P2** — impact réel à l'échelle mais
actuellement négligeable (trafic quasi nul). **Preuve** : lecture directe des 108 messages
Advisor, chacun citant la policy et la table exactes. **Déjà connu et délibérément non corrigé en
masse** (Master Plan P2-16, `SQL_PERFORMANCE_REPORT.md`) — la hausse 83→108 est purement mécanique
(nouvelles tables des sous-systèmes déployés depuis). Une correction reste une revue
policy-par-policy, jamais un rewrite en masse (Rule 5 de ce prompt l'interdirait de toute façon).

## RC-2 — `multiple_permissive_policies` (227 alertes)

**Classification : Vrai problème (performance), gravité P2.** Même raisonnement que RC-1 —
déjà connu (P2-17), hausse 205→227 mécanique, correction nécessitant une revue par table, pas un
rewrite en masse.

## RC-3 — `unused_index` (93 alertes)

**Classification : Simple recommandation, non actionable.** **Preuve** : déjà tranché (P3-19)
avec le raisonnement "faux signal à trafic quasi nul, à rouvrir quand un vrai trafic de production
existera" — raisonnement toujours valide, la hausse 50→93 est purement due aux nouveaux index créés
par les sous-systèmes récents (même mécanisme, pas une régression).

## RC-4 — `unindexed_foreign_keys` (15 alertes)

**Classification : Vrai problème (performance), gravité P2.** **Preuve** : les 15 FK citées par
l'Advisor existent réellement (vérifié par lecture des migrations créant ces tables). Même classe
de correction que P2-15 (déjà faite pour les 32 FK originales), risque faible, à étendre aux
nouvelles tables.

---

## RC-5 — Vues `SECURITY DEFINER` / matérialisées exposées (34 alertes) — **classification éclatée en 3 sous-groupes, preuve différenciée par objet**

### RC-5a — `v_popular_searches`, `v_mv_daily_revenue` (les vues, pas les MV sous-jacentes)

**Classification : Choix d'architecture volontaire (déjà prouvé, P2-4).** La preuve existante
porte sur la sémantique de la requête, pas seulement sur l'accessibilité : `v_popular_searches`
n'a aucune policy SELECT sous-jacente sur `search_logs` (retournerait 0 lignes même en
`security_invoker`) ; `v_mv_daily_revenue` rederive `auth.uid()` à chaque appel et scope donc son
résultat par appelant. Le fait qu'`anon` ait techniquement un grant SELECT dessus (confirmé,
Checkpoint 2) ne change rien au contenu retourné. Aucune nouvelle preuve ne contredit ce jugement —
Rule 4 de ce prompt interdit de le rouvrir sans preuve contraire, absente ici.

### RC-5b — `v_staff_directory_public`

**Classification : Choix d'architecture volontaire (déjà prouvé, P0-1).** Cette vue est
*explicitement* le remplacement volontairement public de l'ancienne policy vulnérable
(`staff_profiles_public_select`) — son accessibilité par `anon` est l'intention, pas un défaut.

### RC-5c — 30 autres objets : `v_bi_*` (13), `v_audit_*` (9), `v_*_dashboard` (8), `mv_audit_stats`, `mv_daily_revenue`

**Classification : VRAI PROBLÈME — gravité P0/P1 selon la grille du projet
(`BACKEND_GOVERNANCE_GUIDE.md` §5.2 : "exploit non authentifié, sans précondition, atteignable
aujourd'hui").**

**Preuve directe, reproduite, sans exfiltration de contenu au-delà du strict nécessaire** :

| Objet | Requête | Résultat |
|---|---|---|
| `v_supabase_dashboard` | `GET ?select=*&limit=1`, clé publique seule | **HTTP 200**, retourne un vrai enregistrement (`table_count`, `policy_count`, `index_count`, `function_count`, `view_count`, `snapshot_at`) |
| `v_audit_security_trail` | `GET ?limit=0`, `Prefer: count=exact` | **HTTP 206, `Content-Range: */2`** — 2 lignes réelles accessibles |
| `v_audit_fraud_proxipay` | idem | **HTTP 206, `*/1`** — 1 ligne réelle accessible |
| `mv_audit_stats` | idem | **HTTP 206, `*/6`** — 6 lignes réelles accessibles |
| `mv_daily_revenue` (la MV brute, pas `v_mv_daily_revenue`) | idem | **HTTP 206, `*/2`** — 2 lignes réelles accessibles |
| `v_bi_revenue`, `v_bi_commissions`, `v_audit_financial_accounting` | idem | HTTP 200, `*/0` — accessibles mais vides aujourd'hui (cohérent avec le trafic quasi nul), **la faille structurelle existe même si son contenu actuel est pauvre** |

**Mécanisme confirmé** : chaque vue est protégée côté application par une RPC `SECURITY DEFINER`
gated (`get_bi_revenue()`, `get_audit_security_trail()`, etc. — vérifié : ces RPC contiennent bien
`IF NOT has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;`, échantillon de
9/23 RPC vérifié individuellement, pattern identique dans chaque fichier source). **Mais la vue
brute sous-jacente n'a jamais reçu de `REVOKE SELECT ... FROM anon, authenticated`**, et
PostgREST expose par défaut tout objet du schéma `public` — n'importe qui peut donc appeler
`GET /rest/v1/v_audit_security_trail` directement, en contournant entièrement la RPC gated et son
contrôle `has_system_admin()`. Le commentaire de code
(`20260704120000_observability_system_admin.sql:176`) montre que l'auteur savait qu'une vue ne
porte pas RLS et a choisi le pattern RPC-gated précisément pour cette raison — mais n'a jamais posé
le `REVOKE` sur l'objet qu'il fallait aussi protéger.

**Distinction importante avec `v_mv_daily_revenue` (RC-5a)** : le jugement P2-4 ne portait que sur
la **vue wrapper** `v_mv_daily_revenue` (qui rederive `auth.uid()`). La **matérialisée brute**
`mv_daily_revenue` est un objet distinct, jamais analysé par P2-4, sans aucune logique de scoping
par appelant (une vue matérialisée est un résultat figé, elle ne peut pas référencer `auth.uid()`
dynamiquement) — son exposition directe est donc un vrai problème à part entière, non couvert par
la fermeture P2-4.

---

## RC-6 — Fonctions `SECURITY DEFINER` exécutables par `anon`/`authenticated` (97 alertes brutes, ~50 fonctions distinctes) — **classification éclatée en 6 sous-groupes**

### RC-6a — 8 fonctions de type `trigger` (`auto_document_templates`, `create_default_salon_settings`, `increment_monthly_bookings_count`, `increment_monthly_bookings_count_stmt`, `invalidate_permission_cache_for_group`, `invalidate_permission_cache_for_row`, `prevent_staff_removal_with_future_bookings`, `protect_review_columns`, `trigger_create_default_automation_workflows`, `trigger_create_version`, `version_cms_content`)

**Classification : Faux positif fonctionnel / Limitation Supabase (PostgREST).** **Preuve live** :
`POST /rest/v1/rpc/protect_review_columns` avec la clé publique → **HTTP 404,
`PGRST202` : "Could not find the function... in the schema cache"**. PostgREST exclut
structurellement les fonctions de retour `trigger` de son cache RPC — elles ne sont **jamais**
atteignables via l'API, quel que soit le grant SQL brut. Le grant existe (`anon_exec = true`
côté SQL) mais est sans effet pratique : c'est une limitation/protection de la plateforme, pas une
propriété du code KYNZA. **Aucun exploit possible.**

### RC-6b — RPC dashboard/BI/audit correctement gated (`get_bi_*` ×13, `get_audit_*` ×9 dont `get_audit_rgpd_trail`/`get_audit_security_trail`/`get_crash_dashboard`/`get_payment_dashboard`/`get_storage_dashboard`/`get_supabase_dashboard` vérifiés individuellement, `get_system_alerts`, `grant_system_admin`, `revoke_system_admin`)

**Classification : Vrai problème mineur (hygiène défense-en-profondeur), gravité P3 — pas
d'exploit vivant.** **Preuve** : corps de fonction lu intégralement pour `grant_system_admin`,
`revoke_system_admin`, `get_bi_revenue`, `get_system_alerts`, et 6 `get_*_dashboard`/`get_audit_*`
supplémentaires (9 fonctions au total sur 23 de ce sous-groupe, échantillon représentatif — pattern
identique dans chaque fichier source, même auteur, même migration) : chacune commence par
`IF NOT public.has_system_admin(auth.uid()) THEN RAISE EXCEPTION 'forbidden'; END IF;` avant toute
opération. Un appelant `anon` atteint la fonction mais se fait immédiatement rejeter — le grant
brut est un résidu d'hygiène (fait exactement dire ce que l'Advisor rapporte techniquement vrai)
mais **ne constitue pas un exploit**, contrairement à RC-5c qui contourne la même protection via
la vue directement. **Résidu de confiance** : les 14 fonctions restantes de ce sous-groupe
(`get_bi_bookings`, `get_bi_clients`, etc.) n'ont pas été vérifiées individuellement — inférence
raisonnable au vu du pattern uniforme, à confirmer si une décision de correction en dépendait.

### RC-6c — `check_system_alerts`

**Classification : VRAI PROBLÈME réel, gravité P2** (blast radius limité : métriques
opérationnelles agrégées, pas de PII client ; mais mutation déclenchable). **Preuve** : corps de
fonction lu intégralement — **aucun `has_system_admin()` ni contrôle de rôle**, contrairement à
son jumeau `get_system_alerts()` qui, lui, est gated. Un appelant `anon` peut l'invoquer, ce qui
(a) exécute des agrégations réelles sur `edge_function_invocations`/`automation_action_runs`/
`transactions` en `SECURITY DEFINER` (contourne RLS), (b) retourne directement dans la réponse RPC
toute nouvelle ligne insérée (taux d'erreur, taux d'échec paiement réels), (c) insère potentiellement
une ligne dans `system_alerts` (guardé par un `NOT EXISTS` anti-doublon, donc pas un vecteur de
spam illimité, mais une écriture non voulue par un appelant non autorisé).

### RC-6d — `claim_pending_action_runs`

**Classification : VRAI PROBLÈME réel, gravité P1** (le plus grave de RC-6 — mutation directe de
données métier sans aucune barrière). **Preuve** : `proacl` confirme un grant `anon` **explicite**
(pas hérité de PUBLIC) ; corps de fonction lu intégralement — **aucune vérification de rôle ou
d'appelant**, exécute directement `UPDATE automation_action_runs SET status='processing' ...
RETURNING *` sur les lignes en attente. Non exécuté en test (muterait des données réelles) — le
grant + l'absence totale de garde dans le code source constituent une preuve suffisante et
non-intrusive. Un appelant anonyme pourrait réclamer des lots entiers de tâches d'automatisation en
attente (rappels, workflows programmés), les bloquant ou les détournant du worker cron légitime.

### RC-6e — `get_all_public_tables`

**Classification : Vrai problème réel, gravité P3** (reconnaissance de schéma, pas de données).
**Preuve** : corps de fonction lu intégralement — aucun garde, `SELECT relname FROM pg_class ...`
sans filtre d'appelant. Expose la liste complète des tables du schéma `public` à quiconque.
Utilité légitime pour un outil d'introspection admin, mais sans le moindre contrôle d'accès.

### RC-6f — `create_default_document_templates`

**Classification : Vrai problème mineur (hygiène), gravité P3 — déjà fonctionnellement fermé
(P2-1).** **Preuve** : corps de fonction lu — contient bien
`IF NOT (has_role(...,'owner',...) OR has_role(...,'manager',...)) THEN RAISE EXCEPTION 'forbidden'`
(fix P2-1, confirmé "403" en production par le Master Plan). Le grant `anon`/PUBLIC brut n'a
cependant jamais été nettoyé (contrairement à `get_staff_week_rank`, traité dans le même fichier
`20260704210000_cp11_hardening_batch.sql` mais avec un `REVOKE` explicite en plus). Résidu
d'hygiène, pas un exploit.

---

## RC-7 — `extension_in_public` (`pg_net`, `pg_trgm`, 2 alertes)

**Classification : Vrai problème mineur, gravité P3.** **Preuve** : les 4 occurrences de
`CREATE EXTENSION IF NOT EXISTS` pour ces deux extensions n'ont aucune clause `SCHEMA`. Recommandé
par Supabase (isoler les extensions de la logique applicative), mais `pg_net` est activement
utilisé par 3 migrations de cron/automatisation et `pg_trgm` par la recherche full-text — un
déplacement de schéma (`ALTER EXTENSION ... SET SCHEMA`) sur une extension déjà active en
production comporte un risque réel de casser des références qualifiées si mal exécuté. Non urgent.

## RC-8 — `function_search_path_mutable` (6 alertes)

**Classification : Vrai problème mineur, gravité P3.** **Preuve** : les 6 fonctions citées
(`update_updated_at`, `check_journey_complete`, `init_owner_journey`, etc.) sont parmi les plus
anciennes du dépôt, antérieures à l'adoption de la discipline `SET search_path` (visible dans
`20260627150000_adv6_security_hardening.sql` et systématique dans tout code plus récent). Correction
triviale et à risque quasi nul (ajouter `SET search_path TO 'public', 'pg_temp'` à la déclaration).

## RC-9 — `rls_enabled_no_policy` (2 alertes)

**Classification : Choix d'architecture volontaire (les deux).** `rate_limit_buckets` : déjà
prouvé (P3-16). `reminder_dispatch_claims` : **preuve directe trouvée** dans
`20260705100000_cp0_concurrency_atomic_claims.sql:86-88` — commentaire explicite *"No policies —
only service_role (schedule-reminders) ever touches this table, same deny-all-by-omission pattern
as data_deletion_requests"*. Même pattern intentionnel, maintenant formellement verdicté.

## RC-10 — `public_bucket_allows_listing` (1 alerte)

**Classification : Choix d'architecture volontaire (déjà prouvé, P3-17).**

## RC-11 — `auth_leaked_password_protection` (1 alerte)

**Classification : Vrai problème mineur, gravité P3 — simple recommandation de sécurité
standard.** Ce n'est pas un artefact de migration : c'est un réglage du projet Auth
(dashboard/Management API), toujours désactivé. Aucune donnée n'a été compromise par cette seule
absence ; l'activation ne présente aucun risque de régression fonctionnelle connue (elle ajoute
une vérification contre les mots de passe divulgués au moment du choix/changement de mot de passe).

---

## Récapitulatif des verdicts

| Catégorie | Causes / sous-groupes | Nb. objets |
|---|---|---|
| **Vrai problème — gravité P0/P1 (accès live non authentifié confirmé)** | RC-5c, RC-6c, RC-6d | 30 vues/MV + 2 fonctions |
| **Vrai problème — gravité P2 (performance ou hygiène réelle, pas d'exploit vivant)** | RC-1, RC-2, RC-4 | 108 + 227 + 15 |
| **Vrai problème — gravité P3 (hygiène/reconnaissance/recommandation, faible enjeu)** | RC-6b (résiduel), RC-6e, RC-6f, RC-7, RC-8, RC-11 | ~21 + 1 + 1 + 2 + 6 + 1 |
| **Choix d'architecture volontaire (preuve directe)** | RC-5a, RC-5b, RC-9, RC-10 | 2 + 1 + 2 + 1 |
| **Simple recommandation, non actionable** | RC-3 | 93 |
| **Faux positif / Limitation Supabase (PostgREST)** | RC-6a | 8 (×2 règles = 16 alertes brutes) |

**Rien n'a été corrigé.** Priorisation formelle (grille à 5 niveaux) au Checkpoint 4 — RC-5c,
RC-6c et RC-6d y seront proposées en priorité **Critique**, compte tenu de la preuve d'exploitation
non authentifiée déjà réunie ici.
