# Point de Contrôle 6 — Journal d'exécution

**Date** : 2026-07-07. Toutes les corrections sont d'abord appliquées et validées sur
`kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`), puis en production (`hhdkjfpgaklhrhfoxlhj`)
**une par une, avec accord explicite séparé pour chaque item avant son application**, per Rule 8 —
jamais d'enchaînement automatique même après un succès. Méthode utilisée pour garantir qu'un seul
item est éligible par exécution de `supabase db push` : déplacement temporaire hors de
`supabase/migrations/` des migrations non encore approuvées, restauration une à une au fur et à
mesure des accords.

**État final (2026-07-07)** : RC-4, RC-8, RC-6c, RC-6d, RC-5c appliqués et validés en production.
RC-11 en attente (bascule prévue côté Dashboard par Mylord, Option A de la Fiche 6 révisée). Détail
de chaque application production en fin de document, section « Application en production ».

---

## RC-4 — 15 index sur clés étrangères non couvertes

**Statut** : appliqué et validé sur `kynza-dr-scratch`. Commit : `86f21b8`
(`20260707100000_advisors_rc4_unindexed_fk.sql`).

**Correction de discipline (2026-07-07)** : initialement mêlé par erreur au commit de documentation
`7e7f44a`. Historique local réorganisé — aucun commit n'ayant encore été poussé vers `origin`
(`git status` confirmait `ahead 5`), un `git reset --soft` non-interactif suivi d'un recommit
séquentiel a permis de séparer proprement docs CP1-5 / RC-4 / RC-8 / RC-6c+6d / RC-5c sans recourir
à `git rebase -i` (interdit dans cet environnement). Les hash de commit ont changé en conséquence
(`7e7f44a`→`ebe7d10`, `287c436`→`53c9041`, `ac12d77`→`8d9350a`, `f9cfb24`→`1ac5368`), le contenu
final est identique.

- Migration appliquée via `supabase db push --linked` (lié à dr-scratch).
- Les 15 index confirmés présents (`pg_indexes`).
- Rejeu Advisors (performance) : `unindexed_foreign_keys` 16 → 1 sur dr-scratch (le 1 restant,
  `search_logs`, est hors périmètre RC-4, non touché — comportement attendu).

## RC-8 — `search_path` sur 6 fonctions

**Statut** : appliqué et validé sur `kynza-dr-scratch`. Commit : `287c436`
(`20260707110000_advisors_rc8_search_path_mutable.sql`).

- Les 6 corps de fonction vérifiés fully-qualified avant modification (aucune référence non
  qualifiée à un objet hors `public`/`pg_catalog`).
- `ALTER FUNCTION` appliqué, `pg_proc.proconfig` confirme `search_path=public, pg_temp` sur les 6.
- Test fonctionnel réel : `UPDATE public.salons SET name = name` sur une ligne réelle —
  `updated_at` confirmé incrémenté (`trigger_fired: true`), le trigger `update_updated_at()`
  fonctionne identiquement après le changement.
- Rejeu Advisors (security) : `function_search_path_mutable` 6 → 0 sur dr-scratch, aucune nouvelle
  alerte.

## RC-11 — Leaked Password Protection : **INCIDENT**, correction non re-tentée

**Statut** : **échec de la première tentative, dr-scratch restauré, en attente d'une Fiche 6
révisée avant nouvel essai.**

### Séquence de l'incident

1. Ajout de `password_hibp_enabled = true` sous `[auth]` dans `supabase/config.toml` (proposition
   Fiche 6 initiale).
2. `supabase config push --project-ref hzjmyeptytvjmzbnsmwp` exécuté. Ce sous-commande ne pousse
   pas un champ isolé : elle calcule un diff entre **toute la section `[auth]` locale** et **toute
   la section `[auth]` distante**, puis applique ce diff intégral avant de continuer vers les
   sections suivantes (API, DB, Storage). Le diff affiché contenait, en plus de la ligne visée,
   9 champs sans rapport avec RC-11 (`site_url`, `additional_redirect_urls`,
   `mfa.totp.enroll_enabled`, `mfa.totp.verify_enabled`, `email.enable_confirmations`,
   `email.otp_length`, `email.max_frequency`, `mfa.phone.template`, `sms.template`) — dérive
   accumulée entre le `config.toml` local (gabarit de développement local, jamais réconcilié avec
   l'état réel de `kynza-dr-scratch`) et l'état réellement configuré sur ce projet.
3. La commande a échoué sur une étape **sans rapport** (`LegacyConfigPushStorageReadNetworkError:
   failed to read Storage config: SchemaError(Missing key "databasePoolMode")`) — mais l'étape Auth
   avait déjà été appliquée avant cet échec (confirmé par un second appel : `Remote Auth config is
   up to date`). **Les 9 champs dérivés ont donc bien été appliqués à `kynza-dr-scratch`.**
4. Un second problème, indépendant : `password_hibp_enabled` s'est révélé être une **clé invalide**
   pour le schéma `config.toml` de cette version de CLI (2.107.0) — `supabase db query` (qui valide
   strictement le fichier local avant toute commande) a commencé à échouer avec
   `'auth' has invalid keys: password_hibp_enabled`, cassant l'outillage local. Le champ existe
   côté API Management/GoTrue mais n'est pas reconnu par le schéma TOML local de cette CLI —
   `config.toml` n'est donc **pas le bon mécanisme** pour ce réglage.

### Cause racine de l'incident

`supabase config push` n'offre aucune granularité de champ — c'est un outil "tout ou rien" par
section, inadapté à une discipline de correction "un item à la fois". L'utiliser pour un
changement Auth ponctuel expose mécaniquement tout écart préexistant entre le `config.toml` local
et l'état réel du projet ciblé, écart qui n'avait jamais été audité avant cette session.

### Restauration effectuée

Les 9 champs dérivés restaurés **un par un**, par édition ciblée de `config.toml` suivie d'un
`config push` (qui, une fois local et distant identiques sur les 8 autres champs, ne calcule et
n'applique plus qu'un diff d'un seul champ) puis vérification (`Remote Auth config is up to date`
sur le champ concerné) avant de passer au suivant :

| # | Champ | Valeur dérivée | Valeur restaurée | Vérifié |
|---|---|---|---|---|
| 1 | `site_url` | `http://127.0.0.1:3000` | `http://localhost:3000` | ✅ |
| 2 | `additional_redirect_urls` | `["https://127.0.0.1:3000"]` | `[]` | ✅ |
| 3 | `mfa.totp.enroll_enabled` | `false` | `true` | ✅ |
| 4 | `mfa.totp.verify_enabled` | `false` | `true` | ✅ |
| 5 | `email.enable_confirmations` | `false` | `true` | ✅ |
| 6 | `email.otp_length` | `6` | `8` | ✅ |
| 7 | `email.max_frequency` | `1s` | `1m0s` | ✅ |
| 8 | `mfa.phone.template` | `` "Your code is {{ `{{ .Code }}` }}" `` | `"Your code is {{ .Code }}"` | ✅ |
| 9 | `sms.template` | `` "Your code is {{ `{{ .Code }}` }}" `` | `"Your code is {{ .Code }}"` | ✅ |

Champs 8 et 9 découverts en relisant le diff original — non listés explicitement par Mylord dans sa
demande de restauration, signalés et inclus par cohérence avec "chaque champ Auth dérivé".

**Vérification finale** : `supabase config push --project-ref hzjmyeptytvjmzbnsmwp` → `Remote Auth
config is up to date`, **zéro diff sur l'ensemble de la section `[auth]`**, pas seulement les 9
champs suivis individuellement.

`supabase/config.toml` local ramené à l'état committé en Git (`git checkout --
supabase/config.toml`) — les 9 éditions n'étaient qu'un mécanisme temporaire de diff ciblé contre
dr-scratch, pas une nouvelle version canonique du fichier. Working tree confirmé propre
(`git status --short` → aucune sortie).

### État de `password_hibp_enabled` — limitation honnête

**Non vérifiable en lecture seule avec les outils disponibles dans cette session.** La CLI Supabase
n'expose aucune commande de lecture directe de la configuration Auth distante (confirmé :
`supabase inspect` ne couvre que la base de données ; aucune sous-commande `auth` en lecture).
Le seul mécanisme observé (`config push`) a un effet de bord (il applique ce qu'il montre) — je ne
peux donc pas "juste vérifier" sans risquer de réappliquer la valeur avant l'accord explicite sur
la Fiche 6 révisée, ce que Mylord a explicitement demandé de séquencer séparément. Deux autres
répertoires liés à Supabase existent sur cette machine (extension VSCode, configuration MCP d'un
autre IDE) qui pourraient détenir des identifiants exploitables — **je n'y ai pas touché**, ce
serait extraire des secrets d'un outil tiers hors du périmètre de cette session.

**Conclusion pour ce champ précis** : très probablement jamais transmis (la clé étant rejetée par
le validateur strict de la CLI), donc l'état sur `kynza-dr-scratch` est très probablement resté
`false`/désactivé comme avant toute cette session — mais ceci reste une déduction, pas une preuve
directe. La Fiche 6 révisée (via un appel Management API ciblé, hors `config.toml`) devra commencer
par un GET explicite pour lever ce doute avant toute écriture.

---

## RC-6c + RC-6d — `check_system_alerts` / `claim_pending_action_runs`

**Statut** : appliqué et validé sur `kynza-dr-scratch`. Commit `8d9350a`
(`20260707120000_advisors_rc6c_rc6d_revoke_execute.sql`).

- `check-system-alerts` n'était pas encore déployée sur dr-scratch (marquée "DRAFT ONLY" dans son
  propre code) — déployée pour ce test (`supabase functions deploy check-system-alerts
  --project-ref hzjmyeptytvjmzbnsmwp`), un job `pg_cron` (`kynza-check-system-alerts`, `*/5 * * * *`)
  existait déjà pointant dessus, désormais fonctionnel.
- `proacl` post-fix confirmé : `{postgres=X/postgres,service_role=X/postgres}` pour les deux
  fonctions — `anon`/`authenticated` entièrement retirés.
- **Test négatif** : appel RPC direct avec la vraie clé `anon` de dr-scratch sur les deux fonctions
  → `42501 permission denied`, HTTP 401 (était 200 avant).
- **Test positif — chemin `service_role` réel** : secret `cron_secret` lu directement depuis
  `vault.decrypted_secrets` du projet (mécanisme propre au projet, aucune extraction d'identifiants
  tiers) ; `run-scheduled-actions` et `check-system-alerts` invoquées avec
  `Authorization: Bearer <service_role_key>` + `X-Cron-Secret: <cron_secret>` réels → `200` pour les
  deux, aucune régression.
- Rejeu Advisors (security) : les deux fonctions disparues de
  `anon_security_definer_function_executable` (48→46) et
  `authenticated_security_definer_function_executable` (50→48), aucune nouvelle alerte.

## RC-5c — 31 vues/MV `SECURITY DEFINER`

**Statut** : appliqué et validé sur `kynza-dr-scratch`. Commit `1ac5368`
(`20260707130000_advisors_rc5c_revoke_select_definer_views.sql`).

- **Correction de portée avant application** : la Fiche 5 initiale du CP5 proposait
  `REVOKE SELECT`. Vérification `pg_class.relacl` sur dr-scratch juste avant application a montré
  que `anon`/`authenticated` détenaient en réalité `ALL PRIVILEGES` (`arwdDxtm`) sur les 31 objets,
  pas seulement `SELECT` — migration corrigée en `REVOKE ALL PRIVILEGES` avant toute exécution.

### Confirmation écrite demandée par Mylord — portée du changement `REVOKE SELECT` → `REVOKE ALL`

**Question** : un rôle autre que `postgres`/`service_role` avait-il `INSERT`/`UPDATE`/`DELETE`/
`REFERENCES` (au-delà de `SELECT`) sur les 31 objets, avant correction ?

**Réponse, vérifiée directement contre la production (lecture seule, avant toute correction sur
cet environnement) via `aclcontains()` sur `pg_class.relacl` pour les 31 objets** :

**Oui, sur les 31 objets, sans exception** — `anon` et/ou `authenticated` détenaient `INSERT`,
`UPDATE`, `DELETE`, `REFERENCES`, `TRUNCATE` **et** `TRIGGER`, pas seulement `SELECT`. La réponse
attendue par l'hypothèse ("non partout") ne se vérifie pas — c'est l'inverse : oui, partout, sur
tous les types de privilège vérifiés.

**Nuance structurelle, vérifiée avant de conclure à un risque réel** : sur les 29 vues (hors les 2
MV, jamais updatables par nature), seules **3** sont structurellement auto-updatable par Postgres
(`information_schema.views.is_insertable_into = 'YES'` **et** `is_updatable = 'YES'`, aucun
`INSTEAD OF` trigger sur les 29) : `v_audit_financial_accounting` (→ `invoices`),
`v_audit_security_trail` (→ `activity_logs`), `v_security_dashboard` (→ `rate_limit_buckets`).
Les 26 autres vues sont des agrégats (`GROUP BY`, jointures) — non auto-updatables par construction
Postgres, donc le grant `INSERT`/`UPDATE`/`DELETE` y était réel mais **inerte** (toute tentative
échoue avec une erreur Postgres avant d'atteindre les données). **Pour les 3 vues simples, le grant
était réel et exploitable** — combiné à `SECURITY DEFINER` (contourne RLS sur la table réelle),
c'était une voie d'écriture non authentifiée vivante, pas seulement un grant mort. Vérification
de non-falsification sur `activity_logs`/`invoices` en production : aucune anomalie trouvée (détail
dans le message du commit `1ac5368`).

**Conclusion** : le changement de portée `REVOKE SELECT` → `REVOKE ALL` n'était pas une précaution
excessive, il fermait une exposition en écriture réelle sur 3 objets, en plus de l'exposition en
lecture déjà documentée au Checkpoint 3 sur l'ensemble des 31.

- `relacl` post-fix confirmé sur 5 objets échantillonnés (`mv_audit_stats`, `mv_daily_revenue`,
  `v_audit_security_trail`, `v_bi_revenue`, `v_supabase_dashboard`) : seuls `postgres`/`service_role`
  restent.
- **Test négatif** : `GET` non authentifié (clé `anon` réelle) sur 6 objets échantillonnés
  (dont les 4 qui avaient retourné de vraies lignes en production au Checkpoint 3) → `401
  42501 permission denied` pour les 6, était `200`/`206` avec données réelles avant.
- **Test positif — chemin RPC légitime** : session réelle générée pour la fixture QA existante
  `kynza.qa.sysadmin.cp1@example.com` (`is_system_admin=true`) via `POST /auth/v1/admin/generate_link`
  (service_role) puis `POST /auth/v1/verify` (échange magiclink → `access_token` réel) — **pas
  seulement un appel service_role**, un vrai utilisateur authentifié système. `get_supabase_dashboard()`
  → `200`, données réelles retournées. `get_bi_revenue()`/`get_audit_security_trail()` → `200`,
  `[]` (vide, cohérent avec le trafic quasi nul, pas une erreur). Le chemin RPC gated fonctionne
  intégralement après la révocation.
- Rejeu Advisors (security) : `security_definer_view` 32 → 3 (exactement les 3 objets exclus
  délibérément : `v_popular_searches`, `v_mv_daily_revenue`, `v_staff_directory_public` —
  aucun autre) ; `materialized_view_in_api` 2 → 0. Aucune nouvelle alerte.

---

## RC-11 (reprise)

**Statut** : Fiche 6 révisée soumise (`docs/advisors-review/CP5_PLAN_CORRECTION.md`), `config.toml`/
`config push` exclu comme mécanisme suite à l'incident ci-dessus. Mylord a choisi l'Option A
(bascule directe dans le Dashboard Supabase, Authentication → Password Security) — action de son
côté, pas la mienne. En attente de sa confirmation d'application avant vérification indépendante.

---

## Application en production — 5 items, un par un, accord explicite avant chacun

Toutes les migrations testées ci-dessus sur `kynza-dr-scratch` ont ensuite été appliquées en
production dans l'ordre demandé par Mylord (RC-4 → RC-8 → RC-6c/RC-6d → RC-5c), chacune avec son
propre tour d'approbation — jamais d'enchaînement automatique.

### RC-4 (production)
- Migration seule éligible (les 3 autres temporairement hors de `supabase/migrations/`).
- 15 index confirmés présents (`pg_indexes`, 15/15).
- Advisors : `unindexed_foreign_keys` **15 → 0** (production n'avait que les 15 ciblés, contrairement
  à dr-scratch qui en portait 16 avec un objet hors périmètre — différentiel plus propre qu'en
  staging).
- Test fonctionnel = présence des index (convenu pour cette catégorie).

### RC-8 (production)
- `pg_proc.proconfig` confirme `search_path=public, pg_temp` sur les 6 fonctions.
- Test fonctionnel réel : `UPDATE public.salons SET name = name` sur une vraie ligne de production
  → `updated_at` incrémenté (`2026-07-01` → `2026-07-07 12:20:56`), `trigger_fired: true`.
- Advisors : `function_search_path_mutable` **6 → 0**.

### RC-6c + RC-6d (production)
- Les deux fonctions Edge (`run-scheduled-actions`, `check-system-alerts`) confirmées déjà
  déployées en production (contrairement à dr-scratch, où `check-system-alerts` avait dû être
  déployée pour le test).
- `proacl` post-fix : `{postgres, service_role}` uniquement sur les deux fonctions SQL.
- Test négatif : `POST /rest/v1/rpc/<fn>` avec la clé publique de production seule → `401 42501
  permission denied` pour les deux.
- Test positif : secret `cron_secret` de production lu depuis `vault.decrypted_secrets` (même
  mécanisme qu'en staging, aucune extraction d'identifiants tiers) ; `run-scheduled-actions` →
  `{"status":"processed","count":0}`, `200` ; `check-system-alerts` →
  `{"status":"checked","newAlerts":0,"dispatched":0}`, `200`. Aucune régression.
- Advisors : `anon_security_definer_function_executable` 47 → 45,
  `authenticated_security_definer_function_executable` 50 → 48. Aucune nouvelle alerte.

### RC-5c (production)

**Preuves soumises et validées avant application** (à la demande explicite de Mylord, compte tenu
de la gravité réelle découverte pendant l'exécution staging) : ACL live re-confirmée juste avant
push (exposition toujours vivante, inchangée depuis l'analyse), migration relue, plan de rollback
rappelé.

- `relacl` post-fix confirmé sur 6 objets échantillonnés : seuls `postgres`/`service_role`
  restent (`arwdDxtm` complet pour eux, rien pour `anon`/`authenticated`).
- **Test négatif générique** : `GET` non authentifié sur 6 objets → `401 42501` pour les 6 (était
  `200`/`206` avec données réelles avant, notamment `v_supabase_dashboard`).
- **Test dédié à l'écriture, demandé explicitement par Mylord** (la partie la plus critique de
  cette correction) : tentative d'`INSERT` non authentifié sur les 3 vues structurellement
  auto-updatable —
  - `v_audit_financial_accounting` (→ `invoices`) : `POST` avec un faux enregistrement de facture
    → `401 42501 permission denied`.
  - `v_audit_security_trail` (→ `activity_logs`) : `POST` avec un faux événement `role_changed`
    sévérité `critical` → `401 42501 permission denied`.
  - `v_security_dashboard` (→ `rate_limit_buckets`) : `POST` avec une fausse ligne de compteur
    → `401 42501 permission denied`.
  - **Vérification défensive** : `count(*)` sur les 3 tables sous-jacentes filtré sur les valeurs
    de test envoyées → **0 partout**. Aucune ligne écrite malgré les tentatives, confirmé
    directement, pas supposé du seul code HTTP.
- **Test positif — chemin RPC légitime, production** : voir action dédiée ci-dessous
  (« Identité `system_admin` temporaire ») pour le mécanisme complet.
  - `get_supabase_dashboard()` → `200`, données réelles (`table_count`, `index_count`, etc.).
  - `get_bi_revenue()` → `200`, `[]` (vide, cohérent avec le trafic quasi nul).
  - `get_audit_security_trail()` → `200`, les 2 lignes légitimes réelles déjà connues
    (`user_login`/`user_logout`) — confirme que le chemin gated retourne bien les vraies données,
    pas seulement qu'il ne plante pas.
- Advisors : `security_definer_view` **32 → 3** (exactement `v_popular_searches`,
  `v_mv_daily_revenue`, `v_staff_directory_public` — les 3 exclusions délibérées, aucun autre) ;
  `materialized_view_in_api` **2 → 0**. Aucune nouvelle alerte.

### Action dédiée — identité `system_admin` temporaire pour le test positif RC-5c

Mylord a demandé que cette action soit documentée à part, avec le mécanisme exact, distincte du
test RC-5c lui-même — voici le détail complet.

**Pourquoi une identité temporaire était nécessaire** : `SELECT id, email FROM public.users WHERE
is_system_admin = true` en production retourne **0 ligne** — contrairement à `kynza-dr-scratch` qui
porte des fixtures QA (`kynza.qa.sysadmin.cp1@example.com`), production n'a jamais eu de compte
`system_admin` réel. Sans identité de ce type, impossible de prouver que le chemin RPC gated
fonctionne réellement pour un appelant autorisé (par opposition à simplement constater l'absence
d'erreur SQL).

**Mécanisme exact, étape par étape** :
1. **Création** — `POST /auth/v1/admin/users` (Auth Admin API, clé `service_role`), email
   `kynza.advisors.rc5c.writetest@example.com`, `user_metadata.purpose` explicitement renseigné à
   `"advisors-rc5c-verification-temporary"` pour qu'aucune ambiguïté ne subsiste sur l'intention.
   Écrit dans `auth.users` (table GoTrue, hors du schéma `public`) ; une ligne correspondante est
   apparue automatiquement dans `public.users` (mécanisme de synchronisation déjà en place dans le
   projet, un trigger sur `auth.users`, non créé pour l'occasion).
2. **Élévation de privilège** — `UPDATE public.users SET is_system_admin = true WHERE id = '...'`
   exécuté directement en SQL (rôle `postgres`/`service_role` via `supabase db query --linked`),
   **pas** via la RPC `grant_system_admin()` : cette RPC exige elle-même un appelant déjà
   `system_admin` (`IF NOT has_system_admin(auth.uid()) THEN RAISE EXCEPTION`), donc inutilisable
   pour créer le tout premier admin. Conséquence directe : **`system_admin_audit` (la table que
   `grant_system_admin()` alimente normalement) est restée à 0 ligne** — vérifié après coup
   (`SELECT count(*) FROM public.system_admin_audit` → `0`). Aucun log applicatif n'a donc capturé
   cette élévation ; seule trace : la commande SQL elle-même dans cette session, consignée ici.
3. **Génération de session réelle** — `POST /auth/v1/admin/generate_link` (`type: magiclink`,
   `service_role`) → `hashed_token` ; puis `POST /auth/v1/verify` (`type: magiclink`,
   `token_hash: ...`, clé publique) → session réelle (`access_token` JWT signé, pas un jeton
   fabriqué à la main). C'est ce token qui a servi aux 3 appels RPC ci-dessus.
4. **Suppression** — `DELETE /auth/v1/admin/users/{id}` (Auth Admin API, `service_role`) → `200
   {}`. Cascade confirmée : `SELECT count(*) FROM auth.users WHERE id='...'` → `0` ;
   `SELECT count(*) FROM public.users WHERE id='...'` → `0`.

**Quel log a capturé la création/suppression, vérifié explicitement** : `auth.audit_log_entries`
(le journal d'audit natif de GoTrue) a été interrogé après coup — **`SELECT count(*) FROM
auth.audit_log_entries` retourne `0` ligne au total sur ce projet**, pas seulement pour cette
identité : ce journal n'est pas alimenté sur ce projet (mécanisme de plateforme, hors du contrôle
du code applicatif KYNZA). **Il n'existe donc aucun log SQL-interrogeable de cette création ni de
cette suppression** — la seule trace vérifiable est la présente session (les appels HTTP et leurs
réponses, reproduits ci-dessus) et ce document. À noter pour toute reproduction future de ce test.

**Confirmation qu'aucune trace n'a pollué `activity_logs`/`v_audit_security_trail`** (la table que
cette correction vient précisément de sécuriser — vérification demandée explicitement pour éviter
l'ironie d'une contamination) :
```sql
SELECT count(*) FROM public.activity_logs
WHERE user_id = '15efb772-40ad-4814-988d-f6e2a008088f'
   OR type_action ILIKE '%rc5c%' OR type_action ILIKE '%writetest%';
-- résultat : 0
```
Contenu complet de `v_audit_security_trail` relu après suppression de l'identité de test :
exactement les 2 mêmes lignes légitimes déjà connues depuis le Checkpoint 3
(`user_login`/`user_logout`, même `salon_id`/`user_id`, mêmes horodatages) — **aucune ligne
supplémentaire, aucune trace de l'identité de test.** Cohérent avec le fait qu'aucune des actions
effectuées (création/élévation/session/suppression, toutes via l'API Admin ou SQL direct) ne passe
par le chemin applicatif `logActivity()` qui alimente `activity_logs`.

**Les 5 items sont clos en production, chacun avec preuve négative, preuve positive et comparateur
Advisors avant/après.**
