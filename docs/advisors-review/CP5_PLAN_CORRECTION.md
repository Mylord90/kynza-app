# Point de Contrôle 5 — Plan de correction

**Date** : 2026-07-07. **Entrée** : les 6 causes retenues au Checkpoint 4 (Critique/Haut/Moyen).
**Statut** : **PROPOSITION UNIQUEMENT — AUCUNE EXÉCUTION.** Conformément à la Rule 8, chaque fiche
ci-dessous attend un accord explicite, **item par item**, avant toute application — y compris sur
`kynza-dr-scratch` (préconisé comme étape de validation avant tout accord de mise en production,
per `BACKEND_GOVERNANCE_GUIDE.md` §2). Aucun accord global anticipé n'est demandé ni supposé.

Toutes les requêtes de vérification supplémentaires ci-dessous (signatures de fonctions, usage
côté client) ont été exécutées en lecture seule contre la production, sans aucune mutation.

---

## Fiche 1 — RC-5c : révoquer l'accès direct `anon`/`authenticated` sur 29 vues + 2 vues matérialisées `SECURITY DEFINER`

**Priorité** : Critique.

**Objets concernés** (31) :
- Vues (29) : `v_audit_automation_execution`, `v_audit_commission_accuracy`,
  `v_audit_financial_accounting`, `v_audit_fraud_proxipay`, `v_audit_rgpd_trail`,
  `v_audit_salon_performance`, `v_audit_security_trail`, `v_audit_user_behavior`,
  `v_bi_activation`, `v_bi_bookings`, `v_bi_clients`, `v_bi_commissions`, `v_bi_conversion`,
  `v_bi_loyalty`, `v_bi_ltv`, `v_bi_payments`, `v_bi_referrals`, `v_bi_revenue`, `v_bi_salons`,
  `v_bi_staff`, `v_bi_subscriptions`, `v_crash_dashboard`, `v_edge_function_dashboard`,
  `v_notification_dashboard`, `v_payment_dashboard`, `v_queue_dashboard`, `v_security_dashboard`,
  `v_storage_dashboard`, `v_supabase_dashboard`
- Vues matérialisées (2) : `mv_audit_stats`, `mv_daily_revenue`

**Exclus délibérément** (déjà classés choix d'architecture volontaire, Checkpoint 3) :
`v_popular_searches`, `v_mv_daily_revenue`, `v_staff_directory_public`.

**SQL proposé** (à tester d'abord sur `kynza-dr-scratch`) :
```sql
REVOKE SELECT ON TABLE
  public.v_audit_automation_execution, public.v_audit_commission_accuracy,
  public.v_audit_financial_accounting, public.v_audit_fraud_proxipay, public.v_audit_rgpd_trail,
  public.v_audit_salon_performance, public.v_audit_security_trail, public.v_audit_user_behavior,
  public.v_bi_activation, public.v_bi_bookings, public.v_bi_clients, public.v_bi_commissions,
  public.v_bi_conversion, public.v_bi_loyalty, public.v_bi_ltv, public.v_bi_payments,
  public.v_bi_referrals, public.v_bi_revenue, public.v_bi_salons, public.v_bi_staff,
  public.v_bi_subscriptions, public.v_crash_dashboard, public.v_edge_function_dashboard,
  public.v_notification_dashboard, public.v_payment_dashboard, public.v_queue_dashboard,
  public.v_security_dashboard, public.v_storage_dashboard, public.v_supabase_dashboard,
  public.mv_audit_stats, public.mv_daily_revenue
FROM anon, authenticated, PUBLIC;
```
(Les grants `postgres`/`service_role` ne sont pas touchés — intacts.)

**Bénéfices attendus** : ferme l'exposition cross-tenant non authentifiée confirmée en direct
(Checkpoint 3) sans toucher au chemin d'accès légitime (les RPC `get_bi_*`/`get_audit_*`/
`get_*_dashboard` s'exécutent en `SECURITY DEFINER`, donc avec les droits du propriétaire de la
fonction, pas de l'appelant — elles continueront de fonctionner après ce `REVOKE`).

**Risques** : recherche exhaustive sur l'intégralité du dépôt (19 059 fichiers hors `.git`, tous
types confondus — `lib/`, `supabase/functions/`, `supabase/migrations/`, `test/`, scripts, config)
pour chacun des 31 noms d'objet : **chaque occurrence hors `supabase/migrations/` a été
individuellement inspectée** — un seul faux-positif trouvé (`lib/core/services/
crash_reporting_service.dart:30`, un commentaire de documentation mentionnant `v_crash_dashboard`,
pas un appel), plus deux faux-positifs non-code (`backups/prod_data_.../automation_action_types.json`,
et le propre fichier de preuve de ce Checkpoint 1). **Zéro appel réel `.from()`/`.select()`/REST
vers l'un de ces 31 objets en dehors des migrations qui les créent.** Le seul chemin d'accès
documenté et utilisé est la RPC gated. Risque résiduel : un script d'administration/BI externe non
tracké dans ce dépôt qui lirait ces vues directement cesserait de fonctionner — à confirmer
verbalement avant exécution, aucune preuve dans le dépôt ne peut couvrir ce cas.

**Rôles ayant actuellement `SELECT` sur chacun des 31 objets** (vérifié `pg_class`/
`information_schema.role_table_grants` pour les 29 vues, `pg_class.relacl` pour les 2 MV — aucune
n'est couverte par `information_schema`) : **identique pour les 31** —
`anon:SELECT, authenticated:SELECT, postgres:SELECT, service_role:SELECT` (les 2 MV portent en
réalité `arwdDxtm` — tous privilèges — pour `anon`/`authenticated`/`postgres`/`service_role`, pas
seulement SELECT). Propriétaire (`relowner`) des 31 objets : `postgres` — c'est ce rôle qui exécute
réellement le `SELECT` sous-jacent quand un appel légitime passe par la RPC `SECURITY DEFINER`
(`get_bi_revenue()` etc.), puisque `SECURITY DEFINER` fait courir la requête avec les droits du
*propriétaire de la fonction*, jamais avec ceux de l'appelant. Aucun objet ne fait exception à ce
schéma — le `REVOKE` proposé est donc uniforme et sans cas particulier.

**Plan de rollback** : `GRANT SELECT ON TABLE <mêmes objets> TO anon, authenticated;` restaure
l'état actuel immédiatement (opération réversible en une commande, aucune perte de données).

**Dépendances** : aucune — indépendant des 5 autres fiches.

**Impact sécurité** : positif direct — ferme un accès cross-tenant non authentifié confirmé.
**Impact performance** : aucun (un `REVOKE` n'affecte pas les plans de requête).
**Impact disponibilité** : aucun.
**Impact RLS** : aucun changement de policy — corrige un contournement de RLS, ne touche à aucune
policy existante.
**Impact Auth** : aucun.
**Impact Realtime** : aucun (ces objets ne sont pas dans une publication Realtime).

**Validation post-correction proposée** : répéter les mêmes appels REST non-authentifiés du
Checkpoint 3 (`GET /rest/v1/v_audit_security_trail?limit=0`, etc.) et confirmer un retour `401`/
`403`/`404` au lieu de `200`/`206` ; confirmer en parallèle que `get_audit_security_trail()` via
RPC avec un compte `system_admin` réel continue de fonctionner normalement.

---

## Fiche 2 — RC-6d : révoquer l'exécution `anon`/`authenticated` sur `claim_pending_action_runs`

**Priorité** : Critique.

**SQL proposé** :
```sql
REVOKE EXECUTE ON FUNCTION public.claim_pending_action_runs(integer, integer, integer)
  FROM anon, authenticated, PUBLIC;
-- Le grant service_role existant (migration 20260705100000) n'est pas touché.
```

**Bénéfices attendus** : ferme la possibilité, pour un appelant anonyme, de réclamer/muter des
lots de la file `automation_action_runs` — confirmé exploitable (aucun garde interne).

**Risques** : `claim_pending_action_runs` n'est appelée que par la fonction Edge
`run-scheduled-actions`, elle-même via `service_role` (vérifié — même pattern que
`check-system-alerts`) — aucune régression attendue. Risque quasi nul.

**Rôles ayant actuellement `EXECUTE`** (`pg_proc.proacl`) : `postgres`, `anon`, `authenticated`,
`service_role` — les quatre rôles, à l'identique. Seul `service_role` correspond à un appelant
réel et documenté (l'Edge Function `run-scheduled-actions`).

**Plan de rollback** : `GRANT EXECUTE ON FUNCTION public.claim_pending_action_runs(integer, integer, integer) TO anon, authenticated;` (non recommandé, fourni pour complétude du rollback).

**Dépendances** : aucune.

**Impact sécurité** : positif direct — ferme une écriture cross-tenant non authentifiée confirmée.
**Impact performance** : aucun.
**Impact disponibilité** : positif — retire un vecteur de déni de service sur la file
d'automatisation (rappels, workflows programmés).
**Impact RLS** : aucun (la table n'a pas de RLS pertinente pour ce chemin, `SECURITY DEFINER`
inchangé).
**Impact Auth** : aucun.
**Impact Realtime** : aucun.

**Validation post-correction proposée** : `POST /rest/v1/rpc/claim_pending_action_runs` avec la clé
publique seule → attendu `401`/`403` ; puis un déclenchement réel de `run-scheduled-actions` (avec
son `X-Cron-Secret`) pour confirmer que le worker légitime continue de réclamer des lots
normalement.

---

## Fiche 3 — RC-6c : révoquer l'exécution `anon`/`authenticated` sur `check_system_alerts`

**Priorité** : Haut.

**SQL proposé** :
```sql
REVOKE EXECUTE ON FUNCTION public.check_system_alerts() FROM anon, authenticated, PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_system_alerts() TO service_role;
```

**Bénéfices attendus** : ferme la fuite de métriques opérationnelles (taux d'erreur, taux d'échec
paiement) à un appelant non authentifié, et l'écriture non voulue dans `system_alerts`.

**Risques** : confirmé, via lecture directe de `supabase/functions/check-system-alerts/index.ts`,
que cette fonction n'est invoquée que par cette Edge Function, elle-même via
`createServiceRoleClient()` et gated par son propre `X-Cron-Secret` — aucune régression attendue.

**Rôles ayant actuellement `EXECUTE`** (`pg_proc.proacl`) : `postgres`, `anon`, `authenticated`,
`service_role` — identique à `claim_pending_action_runs`, les quatre rôles indifférenciés. Seul
`service_role` correspond à un appelant réel et documenté.

**Plan de rollback** : `GRANT EXECUTE ON FUNCTION public.check_system_alerts() TO anon, authenticated;` (non recommandé, fourni pour complétude).

**Dépendances** : aucune.

**Impact sécurité** : positif direct.
**Impact performance** : aucun.
**Impact disponibilité** : positif marginal (retire un vecteur d'écriture non maîtrisée, même
si déjà anti-doublon).
**Impact RLS** : aucun.
**Impact Auth** : aucun.
**Impact Realtime** : aucun.

**Validation post-correction proposée** : `POST /rest/v1/rpc/check_system_alerts` avec la clé
publique seule → attendu `401`/`403` ; confirmer que la fonction Edge `check-system-alerts`
(une fois réellement déployée, cf. P1-12/rappel : le cron `kynza-check-system-alerts` existe déjà
en production) continue de fonctionner avec son `X-Cron-Secret`.

---

## Fiche 4 — RC-4 : indexer les 15 clés étrangères non couvertes

**Priorité** : Moyen.

**SQL proposé** (même pattern que P2-15, index simples, tables actuellement quasi vides — risque
de verrouillage négligeable) :
```sql
CREATE INDEX IF NOT EXISTS idx_cms_content_versions_changed_by ON public.cms_content_versions (changed_by);
CREATE INDEX IF NOT EXISTS idx_experiment_assignments_user_id ON public.experiment_assignments (user_id);
CREATE INDEX IF NOT EXISTS idx_experiment_events_user_id ON public.experiment_events (user_id);
CREATE INDEX IF NOT EXISTS idx_legal_documents_current_version ON public.legal_documents (current_version_id);
CREATE INDEX IF NOT EXISTS idx_remote_config_audit_actor_id ON public.remote_config_audit (actor_id);
CREATE INDEX IF NOT EXISTS idx_remote_config_entries_updated_by ON public.remote_config_entries (updated_by);
CREATE INDEX IF NOT EXISTS idx_remote_config_versions_changed_by ON public.remote_config_versions (changed_by);
CREATE INDEX IF NOT EXISTS idx_role_feature_overrides_flag_key ON public.role_feature_overrides (flag_key);
CREATE INDEX IF NOT EXISTS idx_services_source_template_id ON public.services (source_template_id);
CREATE INDEX IF NOT EXISTS idx_system_admin_audit_actor_id ON public.system_admin_audit (actor_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_overrides_flag_key ON public.user_feature_overrides (flag_key);
CREATE INDEX IF NOT EXISTS idx_user_feature_overrides_user_id ON public.user_feature_overrides (user_id);
CREATE INDEX IF NOT EXISTS idx_user_legal_acceptances_doc_version_id ON public.user_legal_acceptances (document_version_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_groups_user_id ON public.user_permission_groups (user_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_user_id ON public.user_permission_overrides (user_id);
```
*(Noms de colonnes confirmés directement contre `information_schema.key_column_usage` en
production — les 14 dérivés du nom de contrainte étaient exacts ; `legal_documents` portait en
réalité `current_version_id`, corrigé ci-dessus.)*

**Bénéfices attendus** : évite le même plafond de performance déjà mesuré et corrigé pour les 32
FK originales (P2-15) — pertinent pour ces tables une fois qu'elles porteront un vrai volume
(CMS, Remote Config, Feature Flags, Legal Center, Audit).

**Risques** : quasi nul — tables actuellement proches de zéro ligne, `CREATE INDEX` non-concurrent
acceptable (verrouillage bref, pas de trafic à bloquer). Risque de nommage dupliqué si un index
équivalent existe déjà sous un autre nom — à vérifier avant application.

**Plan de rollback** : `DROP INDEX IF EXISTS <nom>;` pour chaque index, individuellement.

**Dépendances** : aucune.

**Impact sécurité** : aucun. **Impact performance** : positif (à l'échelle). **Impact
disponibilité** : aucun. **Impact RLS** : aucun. **Impact Auth** : aucun. **Impact Realtime** :
aucun.

**Validation post-correction proposée** : `\d <table>` (ou requête `pg_indexes`) confirmant la
présence de chaque index ; re-jeu de l'Advisor confirmant la disparition des 15 alertes.

---

## Fiche 5 — RC-8 : fixer `search_path` sur 6 fonctions

**Priorité** : Moyen.

**Signatures exactes vérifiées** (`pg_get_function_identity_arguments`) :

**SQL proposé** (`ALTER FUNCTION` seul — ne redéfinit pas le corps, risque minimal) :
```sql
ALTER FUNCTION public.check_app_version(p_platform text, p_version_code integer) SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.check_journey_complete() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.evaluate_feature_flag(p_key text) SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.init_owner_journey() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.is_maintenance_active() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.update_updated_at() SET search_path TO 'public', 'pg_temp';
```

**Bénéfices attendus** : ferme la classe d'attaque standard "search_path hijacking" (un rôle avec
droit de création de schéma pourrait autrement faire résoudre un identifiant non qualifié vers un
objet malveillant). Aucun exploit démontré ici, mais correction reconnue comme bonne pratique
systématique (déjà la norme pour tout code plus récent que `20260627150000_adv6_security_hardening.sql`).

**Risques** : quasi nul — `ALTER FUNCTION ... SET search_path` ne change pas le corps de la
fonction, seulement son environnement de résolution de noms ; toutes les références internes à ces
6 fonctions sont déjà qualifiées `public.*` ou portent sur des tables du schéma `public` (à
reconfirmer à la lecture du corps de chacune juste avant application).

**Plan de rollback** : `ALTER FUNCTION <même signature> RESET search_path;`

**Dépendances** : aucune.

**Impact sécurité** : positif (hygiène). **Impact performance** : aucun. **Impact disponibilité** :
aucun. **Impact RLS** : aucun. **Impact Auth** : aucun. **Impact Realtime** : aucun.

**Validation post-correction proposée** : `SELECT proconfig FROM pg_proc WHERE proname = '<nom>'`
confirmant `search_path=public,pg_temp` ; test fonctionnel de chaque fonction dans son contexte
d'appel réel (ex. `update_updated_at` déclenché par une vraie `UPDATE` sur une table qui le
référence).

---

## Fiche 6 (RÉVISÉE, 2026-07-07, post-incident) — RC-11 : activer la protection contre les mots de passe divulgués (Leaked Password Protection)

**Priorité** : Moyen.

> **Pourquoi cette fiche est révisée** : la première tentative (`supabase/config.toml` +
> `supabase config push`) a causé un incident réel — `config push` ne pousse pas un champ isolé,
> il pousse un diff de section entière, et `password_hibp_enabled` s'est révélé être une clé
> **invalide** dans le schéma `config.toml` de la CLI installée (2.107.0), cassant l'outillage
> local sans jamais confirmer avoir atteint la plateforme. Détail complet, restauration effectuée
> et preuve : `docs/advisors-review/CP6_EXECUTION_LOG.md` (section RC-11). **`config.toml` /
> `config push` est exclu comme mécanisme pour cette fiche — plus jamais utilisé pour un
> changement Auth ponctuel.**

**Mécanisme révisé** : appel direct à l'API Management REST, jamais via `config.toml`. Confirmé
par la documentation Supabase (recherche effectuée le 2026-07-07) : l'endpoint
`GET/PATCH https://api.supabase.com/v1/projects/{ref}/config/auth` existe, et `password_hibp_enabled`
(booléen) est bien le nom de champ correct côté API — le problème initial n'était pas un nom de
champ erroné, seulement son absence du schéma local `config.toml` de cette version de CLI.
Sources : [Management API Reference](https://supabase.com/docs/reference/api/introduction),
[Get auth config](https://supabase.com/docs/reference/api/v1-get-auth-config).

**Séquence obligatoire, dans cet ordre, jamais inversée** :
1. **GET en lecture seule d'abord** — `GET /v1/projects/hhdkjfpgaklhrhfoxlhj/config/auth`, lire
   `password_hibp_enabled` dans la réponse, consigner sa valeur actuelle exacte (déduction du
   Checkpoint 6 : très probablement `false`/absent, jamais transmis — mais ceci doit être remplacé
   par une preuve directe, pas une déduction, avant toute écriture).
2. **PATCH ensuite, uniquement ce champ** — corps de requête limité à
   `{"password_hibp_enabled": true}`, jamais un objet de configuration plus large (c'est
   exactement la discipline qui a manqué à la première tentative).
3. **GET de vérification** — relire `password_hibp_enabled`, confirmer `true`.

**Blocage opérationnel à lever avant exécution** : je n'ai pas d'accès direct et sanctionné à un
jeton d'accès Management API (PAT) pour exécuter ces appels moi-même — la CLI `supabase` gère son
propre jeton en interne sans l'exposer (`--debug` ne le journalise pas, confirmé), et je ne
tenterai pas de l'extraire d'un magasin d'identifiants d'un autre outil sur cette machine (extension
VSCode, config MCP d'un autre IDE) : ce serait hors périmètre de cette session. **Deux options
pour débloquer, au choix de Mylord** :
- **Option A (recommandée)** : effectuer les 3 étapes ci-dessus directement dans le Dashboard
  Supabase (Authentication → Sign In / Providers → Password Security, ou équivalent) — un simple
  toggle, zéro risque de diff en lot, évite complètement la classe de risque qui a causé l'incident
  RC-11 initial. Je n'ai pas besoin d'y participer pour cette option.
- **Option B** : Mylord fournit un jeton d'accès Management API (PAT) scopé, temporaire, pour cette
  session uniquement — j'exécute alors moi-même les 3 appels ci-dessus avec preuve à chaque étape,
  puis recommande sa révocation immédiate après usage.

**Bénéfices attendus** : empêche un utilisateur de définir un mot de passe déjà présent dans une
fuite de données connue (vérification via k-anonymity contre l'API Have I Been Pwned, standard
Supabase) — contrôle de sécurité de base actuellement absent.

**Risques** : quasi nul pour le changement lui-même (n'affecte que les futurs choix/changements de
mot de passe, aucun impact sur les sessions ou comptes existants, l'échec de l'API HIBP est
documenté fail-open côté Supabase, cohérent avec ADR-0001) — le risque réel identifié était dans le
**mécanisme d'application** (`config push`), pas dans le changement, d'où la révision ci-dessus.

**Plan de rollback** : `PATCH /v1/projects/{ref}/config/auth` avec
`{"password_hibp_enabled": false}` (Option B) ou le même toggle dans le Dashboard (Option A).

**Dépendances** : aucune.

**Impact sécurité** : positif. **Impact performance** : négligeable (latence additionnelle au
moment du choix de mot de passe uniquement). **Impact disponibilité** : aucun. **Impact RLS** :
aucun. **Impact Auth** : oui, par construction — c'est le point même de ce changement ; aucune
session existante affectée, aucun autre champ Auth touché (contrairement à l'incident initial).
**Impact Realtime** : aucun.

**Validation post-correction proposée** : GET de vérification (étape 3 ci-dessus) ; puis tenter une
inscription/un changement de mot de passe avec un mot de passe connu comme divulgué
(ex. `password123`) et confirmer le rejet.

---

## Récapitulatif — accord requis item par item (Rule 8)

| # | Fiche | Priorité | Type de changement | Accord requis avant |
|---|---|---|---|---|
| 1 | RC-5c — REVOKE ALL sur 31 vues/MV (portée élargie depuis SELECT, cf. CP6 log) | Critique | SQL (grants) | **Fait sur dr-scratch, commit `1ac5368`** — attend accord prod |
| 2 | RC-6d — REVOKE EXECUTE `claim_pending_action_runs` | Critique | SQL (grants) | **Fait sur dr-scratch, commit `8d9350a`** — attend accord prod |
| 3 | RC-6c — REVOKE EXECUTE `check_system_alerts` | Haut | SQL (grants) | **Fait sur dr-scratch, commit `8d9350a`** — attend accord prod |
| 4 | RC-4 — 15 `CREATE INDEX` | Moyen | Migration SQL | **Fait sur dr-scratch, commit `86f21b8`** — attend accord prod |
| 5 | RC-8 — 6 `ALTER FUNCTION ... SET search_path` | Moyen | Migration SQL | **Fait sur dr-scratch, commit `53c9041`** — attend accord prod |
| 6 | RC-11 — `password_hibp_enabled = true` | Moyen | API Management directe (jamais `config.toml`/`config push`, cf. révision ci-dessus) | Bloqué sur Option A ou B ci-dessus |

**5 des 6 corrections sont appliquées et validées sur `kynza-dr-scratch`, aucune sur production.**
RC-11 reste bloquée sur un choix de mécanisme (Dashboard direct ou PAT temporaire) avant même une
tentative staging. Merci de valider chaque fiche individuellement avant passage en production —
toujours item par item, jamais en lot.
