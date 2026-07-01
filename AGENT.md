# KYNZA — AGENT.md

> Mémoire permanente pour tout agent IA intervenant sur ce projet. À lire intégralement avant toute modification de code.

## SECTION 1 — PROJECT MEMORY

| Attribut | Valeur |
|---|---|
| Nom officiel | **KYNZA** (anciennement *SalonYawe* — ce nom ne doit plus apparaître nulle part : code, UI, commentaires, assets, packages) |
| Type | SaaS Premium — Gestion & Réservation de Salons de Beauté |
| Marché V1 | Burundi uniquement — devise **BIF (FBu)** exclusivement, jamais €/$ |
| Expansion prévue | Afrique subsaharienne — architecture multi-currency *ready* dès V1 (colonnes `currency`/`country_code` présentes, UI figée BIF) |
| Rôles | `OWNER` > `MANAGER` > `STAFF` > `CLIENT` — multi-tenant strict via `salon_id` |
| Stack | Flutter (Dart) + Supabase (Postgres/RLS/Realtime/Edge Functions) + Leapa API + Firebase FCM + Riverpod |
| Design | Dark Luxury — Noir `#09090B` + Or `#EAB308`, règle 80/15/5 (noir/texte/accent) |
| Principe fondateur | KYNZA n'héberge jamais l'argent. C'est un miroir comptable, pas une néo-banque. |

---

## SECTION 2 — NON-NEGOTIABLE RULES

Ces règles s'appliquent à **tout** le code généré, sans exception ni dérogation implicite.

- **R01** — KYNZA ne stocke JAMAIS l'argent. Flux : Client → Leapa API → Mobile Money de l'Owner (direct). Supabase = miroir comptable *read-only*.
- **R02** — RLS activé sur **toutes** les tables Supabase sans exception. Violation RLS → HTTP 403. Jamais de données brutes exposées. `salon_id` toujours dérivé du JWT, jamais envoyé par le client.
- **R03** — Offline-First obligatoire. App fonctionnelle sans réseau. Synchro silencieuse à la reconnexion. Ordre de sync strict : 1. Nouveaux RDV → 2. Statuts modifiés → 3. Paiements Cash → 4. Notes clients.
- **R04** — Feedback < 1 seconde sur toute action utilisateur. Skeleton screens obligatoires (jamais de spinner seul sur écran vide). Aucun écran vide sans CTA.
- **R05** — Max 3 actions primaires par écran. Max 3 taps pour toute action majeure. Jamais de dead-end.
- **R06** — BIF/FBu partout en V1. Format d'affichage : `"45 000 FBu"` (locale fr, séparateur espace). Architecture multi-currency prête mais UI figée BIF.
- **R07** — Isolation financière Owner stricte. Double protection : garde Flutter (`if role == owner`) **et** policy RLS Supabase. Staff ne voit que ses propres revenus virtuels. Manager voit tout sauf wallet/CA global/retraits.
- **R08** — Idempotency key obligatoire sur tout appel Leapa. Format : `${bookingId}_${Math.floor(Date.now()/60000)}`. HMAC-SHA256 validé sur tout webhook entrant avant traitement.
- **R09** — Jamais de logique métier dans les widgets Flutter. Tout dans Cubits/Notifiers, Repositories, UseCases. Architecture Feature-First + Clean Architecture.
- **R10** — `[Confirmer arrivée]` (Staff) = action directe **sans** pop-up de confirmation. Seule exception à R15. Visible uniquement si RDV ≤ 30 min.
- **R11** — Staff ne voit jamais les revenus de ses collègues. Classement = position uniquement, jamais les montants.
- **R12** — Données jamais supprimées physiquement (soft delete via `deleted_at`). Réactivation d'abonnement = accès immédiat à l'historique complet.
- **R13** — Performance cible : 60fps sur device d'entrée de gamme (Snapdragon 460, 2 Go RAM — ex. Moto G06, Galaxy A05s). Interdit : Lottie si RAM < 3 Go, animations de layout/size, `BoxShadow` lourds. Requis : `const` constructors, `ListView.builder`, images WebP, lazy loading.
- **R14** — WhatsApp Business API en premier canal, Push FCM en second. Jamais d'email pour une alerte opérationnelle. Anti-spam : max 2 promos/semaine/salon, max 50 messages WhatsApp/heure.
- **R15** — Toute action destructive (annulation, remboursement, suppression) exige une confirmation modale explicite. Seule exception : R10.
- **R16** — Paiements **uniquement** via Supabase Edge Functions. Jamais d'appel Leapa direct depuis Flutter — la clé API ne doit jamais transiter côté client.
- **R17** — Remboursement initié par l'Owner → OTP SMS obligatoire avant exécution Leapa.
- **R18** — Score de fiabilité client invisible pour le Client. Visible uniquement côté Owner et Staff.
- **R19** — Couleurs uniquement depuis les tokens `AppColors`. Jamais de valeur hex hardcodée dans un widget.
- **R20** — Session Staff expire après 7 jours d'inactivité. Révocation Owner → coupure instantanée via Supabase Realtime.

---

## SECTION 3 — DO NOT BREAK RULES

Interdictions absolues, sans exception, pour tout agent IA :

- ❌ Utiliser "SalonYawe" dans le code, l'UI, les noms de packages, les commentaires
- ❌ Afficher €, $, KES ou toute devise non-BIF en V1
- ❌ Appeler Leapa API directement depuis Flutter (toujours via Edge Function)
- ❌ Créer un écran sans état `loading` (skeleton), `error`, `empty` ET `offline`
- ❌ Supprimer physiquement des données (toujours `deleted_at`, jamais `DELETE`)
- ❌ Exposer des données financières à un rôle non-Owner
- ❌ Hardcoder une couleur hex dans un widget (toujours `AppColors.xxx`)
- ❌ Mettre de la logique métier dans un widget (toujours Cubit/Notifier/UseCase)
- ❌ Contourner, désactiver ou affaiblir une policy RLS pour "simplifier" un test
- ❌ Utiliser `BackdropFilter` ou des effets de blur (coût performance sur device bas de gamme)
- ❌ Ajouter un pop-up de confirmation sur `[Confirmer arrivée]` (viole R10)
- ❌ Afficher les montants des collègues à un Staff (viole R11)
- ❌ Utiliser `ListView`/`Column` sans `.builder` pour une liste potentiellement longue
- ❌ Stocker une clé API (Leapa, FCM, WhatsApp) ailleurs que dans Supabase Vault / variables d'environnement Edge Functions

---

## SECTION 4 — AI AGENT EXECUTION RULES

### TIER 1 — Avant toute modification
1. Relire les Sections 2 et 3 de ce document.
2. Identifier le(s) rôle(s) concerné(s) par le changement (Owner/Manager/Staff/Client).
3. Vérifier la policy RLS de chaque table touchée — si absente, l'écrire **avant** le code Flutter.
4. Confirmer que `salon_id` est dérivé du JWT (`auth.jwt()->>'salon_id'`), jamais reçu en paramètre client.

### TIER 2 — Pendant l'implémentation
- Toujours produire les 5 états UI : `loading` (skeleton), `error`, `empty`, `offline`, `data`.
- Toute nouvelle table Supabase → RLS écrite et testée avant tout code Flutter consommateur.
- Tout nouveau flux de paiement → Edge Function + idempotency key + vérification HMAC.
- Tout nouvel écran → squelette d'abord (skeleton statique), branchement données ensuite.
- Toute nouvelle feature → évaluer l'impact sur les 4 rôles avant de coder (qui y a accès, qui en est exclu).

### TIER 3 — Après chaque modification
- `dart analyze` sans erreur ni warning bloquant.
- Vérifier qu'aucune règle R01–R20 n'est violée par le diff.
- Confirmer que chaque couleur utilisée existe dans `AppColors`.
- Si la feature touche des données : tester explicitement le comportement offline (mode avion).

---

## SECTION 5 — ARCHITECTURE OFFICIELLE

### Stack complète
- **Mobile** : Flutter 3.22+ / Dart 3.4+
- **State management** : Riverpod 2.5+ (StateNotifier/AsyncNotifier — `flutter_bloc` toléré uniquement si déjà présent dans un module legacy)
- **Navigation** : GoRouter — deep links (`/booking/:id`, `/payment/:id`)
- **Backend** : Supabase (PostgreSQL 15+, RLS, Realtime, Edge Functions Deno)
- **Auth** : Supabase Auth — Téléphone+OTP (canal principal Afrique), Email+Password en secours, Google/Apple en option
- **Paiements** : Leapa API (Lumicash + EcoCash en V1, eNoti V1.5, Carte bancaire V2)
- **Push** : Firebase Cloud Messaging (Edge Function → FCM)
- **Communication** : WhatsApp Business Cloud API
- **Cache offline** : Hive + Isar (chiffrement AES-256 en option)
- **Médias** : Supabase Storage + CDN (compression WebP obligatoire côté serveur)

### Structure dossiers (feature-first)
```
lib/
├── core/
│   ├── constants/       # AppColors, AppTypography, AppSpacing,
│   │                    # AppDurations, AppCurves
│   ├── animations/      # KynzaAnimations (fadeSlideIn/scaleIn/shimmerPulse)
│   ├── theme/           # ThemeData dark-first
│   ├── router/          # GoRouter, routes, guards par rôle
│   ├── providers/       # Providers globaux Riverpod
│   ├── models/          # Modèles partagés (freezed)
│   ├── services/        # Supabase client, Session, Connectivity
│   ├── permissions/     # PermissionService/PermissionGuard (RBAC additive,
│   │                    # Phase 1.1 — cache Hive 15min miroir SQL)
│   ├── audit/           # AuditLogger (Phase 1.2 — ne crash jamais,
│   │                    # écrit dans activity_logs existant)
│   ├── utils/           # formatBif(), validators, haptics (KynzaHaptics)
│   └── enums/           # UserRole, BookingStatus, PaymentStatus
├── shared/
│   └── widgets/         # KynzaButton, KynzaCard, KynzaSkeleton,
│                        # KynzaCardSkeletons (named variants), KynzaToast,
│                        # KynzaEmptyState, KynzaOfflineBanner,
│                        # KynzaAmountWidget, KynzaBottomSheet
└── features/
    ├── auth/            # Login, Register, OTP, CompleteProfile
    ├── home_owner/      # Dashboard, Calendar, Clients, Marketing
    ├── home_staff/      # Today, Calendar, MyClients, Performance
    ├── home_client/     # Discover, Salon, Booking, Appointments
    ├── payments/        # Checkout, Leapa flow, Receipts
    ├── notifications/   # FCM, WhatsApp templates
    ├── subscription/    # Plans, Upgrade, Billing
    ├── permissions/     # Permission groups (Phase 1.1 RBAC — owner-only,
    │                    # additive to the base role system below)
    ├── settings/        # SettingsHomeScreen + generic SettingsCategoryScreen
    │                    # (Phase 1.4 — salon_settings)
    ├── automation/      # Workflow builder/list/execution-log (Phase 2 —
    │                    # Trigger → Conditions → Actions)
    └── data_platform/   # backup/ (BackupScreen) + templates/
                          # (TemplateListScreen, TemplateEditorScreen)
                          # Phase 3 — Enterprise Data Platform
```

Toute nouvelle feature respecte ce découpage : pas de logique transverse hors `core/`, pas de widget partagé dupliqué hors `shared/widgets/`.

---

## SECTION 6 — DATABASE SCHEMA (tables core)

```sql
salons (
  id UUID PK, name, owner_id, plan, plan_status, country_code,
  currency DEFAULT 'BIF', is_online BOOL, employees_count INT,
  deleted_at TIMESTAMPTZ
)

users (
  id UUID PK = auth.uid(), salon_id, role, phone, full_name,
  email, email_verified BOOL, auth_provider, profile_completed BOOL,
  reliability_score INT DEFAULT 100, preferred_currency DEFAULT 'BIF',
  locale DEFAULT 'fr_BI', deleted_at TIMESTAMPTZ
)

bookings (
  id UUID PK, salon_id, client_id, practitioner_id, service_id,
  status CHECK (status IN ('pending_payment','confirmed','in_progress',
                            'completed','cancelled','no_show')),
  start_time TIMESTAMPTZ, end_time TIMESTAMPTZ, buffer_end_time TIMESTAMPTZ,
  amount_bif INT, payment_status, deposit_required BOOL,
  idempotency_key UNIQUE,
  UNIQUE(practitioner_id, start_time)   -- verrou anti race-condition
)

transactions (
  id UUID PK, salon_id, booking_id, leapa_reference UNIQUE,
  amount_bif INT, method, status, idempotency_key UNIQUE,
  confirmed_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
)

services (
  id UUID PK, salon_id, name, price_bif INT, duration_min INT,
  buffer_min INT DEFAULT 0, category, is_active BOOL, deleted_at TIMESTAMPTZ
)
-- Versionné (Phase 1.3) : trigger version_services → entity_versions
-- sur chaque INSERT/UPDATE.

-- NOTE : il n'existe PAS de table `subscriptions` séparée (vérifié
-- Phase 1.3 — aucune migration, aucun call site Flutter/Edge Function ne
-- la référence). L'état d'abonnement vit sur salons.plan/plan_status
-- (basculé par mark_invoice_paid()) + invoices (l'historique réel de
-- facturation/changement de plan). `invoices` est versionné (trigger
-- version_invoices) comme substitut fidèle à l'intention du brief.

loyalty_cards (
  id UUID PK, salon_id, client_id, stamps INT, required INT,
  reward TEXT, expires_at TIMESTAMPTZ
)

activity_logs (   -- APPEND-ONLY, jamais d'UPDATE/DELETE
  id UUID PK, salon_id, user_id, type_action, old_values JSONB,
  new_values JSONB, ip_address, created_at TIMESTAMPTZ,
  -- Phase 1.2 : table_name, record_id, severity (debug/info/warning/
  -- error/critical), is_sensitive BOOL, device_info JSONB, platform,
  -- app_version, screen_name, session_id, request_id, duration_ms
  -- (les 5 derniers existent en colonnes mais non encore alimentés —
  -- aucune dépendance package_info_plus/device_info_plus dans l'app)
)
-- mv_audit_stats : vue matérialisée (salon_id, day, type_action, severity)
-- rafraîchie par pg_cron toutes les heures (refresh_audit_stats(),
-- CONCURRENTLY). Interne uniquement — pas de RLS possible sur une vue
-- matérialisée, donc pas de GRANT à `authenticated` tant qu'aucun écran
-- ne la consomme via une vue wrapper security_invoker scopée au salon.
```

### RLS — résumé des policies critiques
- `transactions` / `subscriptions` / wallet : **Owner only**.
- `bookings` côté Staff : `practitioner_id = auth.uid()`.
- `bookings` côté Client : `client_id = auth.uid()`.
- `users` : `SELECT`/`UPDATE` sur sa propre ligne uniquement — `salon_id` et `role` protégés par trigger, jamais modifiables via l'API client.
- `activity_logs` : `SELECT` réservé à l'Owner. Aucun `UPDATE`/`DELETE` possible (append-only).

### JWT claims
```json
{ "user_id": "...", "salon_id": "...", "role": "owner|manager|staff|client",
  "plan_status": "...", "preferred_currency": "BIF", "country_code": "BI", "email": "..." }
```

---

## SECTION 7 — SECURITY HARDENING

Correctifs de sécurité à maintenir actifs en production (toute migration future doit les préserver) :

1. **`protect_user_columns`** (trigger) — `salon_id`, `email_verified`, `reliability_score`, `role` sont immuables via l'API client (`UPDATE` direct refusé).
2. **`sync_email_verified`** (trigger) — synchronisé uniquement depuis `auth.users`, jamais inscriptible côté client.
3. **`has_role(uid, role, salon_id?)`** — fonction `SECURITY INVOKER` scoping par salon, utilisée dans toutes les policies RLS sensibles.
4. **`logs_self_insert_safe`** — policy `WITH CHECK` sur `activity_logs` : `salon_id` cohérent + whitelist stricte de `type_action`.
5. **`REVOKE EXECUTE`** sur les fonctions sensibles côté rôle `anon`/`authenticated` direct : `handle_new_user`, `protect_user_columns`, `sync_email_verified`, `custom_access_token_hook`.
6. **`users_self_update_safe`** — policy `WITH CHECK` empêchant la modification des colonnes sensibles même via un `UPDATE` partiel.
7. **HMAC-SHA256** vérifié sur chaque webhook Leapa entrant avant tout traitement métier (rejet silencieux si signature invalide).

---

## SECTION 8 — PAYMENT ARCHITECTURE

- **Non-custodial** : KYNZA = miroir comptable uniquement, jamais dépositaire de fonds.
- **Flux complet** : Flutter → Supabase Edge Function → Leapa API → USSD push client → validation PIN → webhook Leapa (HMAC) → Edge Function → `transactions.status = completed` → Realtime → Flutter (< 300ms) → écran succès + Push + WhatsApp.
- **Idempotency key** : `${bookingId}_${Math.floor(Date.now()/60000)}` — garantit l'unicité par fenêtre de 60s.
- **Webhook** : signature HMAC-SHA256 validée côté Edge Function avant tout traitement ; rejet sans effet de bord si invalide.
- **Remboursement** : OTP SMS Owner obligatoire → déclenchement Leapa Payout API.
- **États transaction** : `pending` → `processing` → `completed` | `failed` | `reversed` | `expired`.
- **Méthodes V1** : Lumicash, EcoCash.
- **Méthodes V1.5** : eNoti (Bancobu).
- **Méthodes V2** : Carte bancaire (Visa/Mastercard).

---

## SECTION 9 — OFFLINE STRATEGY

| Donnée | Mode | Stockage |
|---|---|---|
| Agenda J+7 | Lecture + écriture | Hive (chiffré) |
| Notes clients | Lecture + écriture | Queue de synchro |
| Nouveaux RDV (création) | Écriture locale puis sync | Queue de synchro |
| Historique 30j, fiches clients, KPIs | Lecture seule | Hive |
| Paiement Cash | Enregistrement local | Queue de synchro |
| Paiement Mobile Money | Réseau requis | — |
| Push notifications | Réseau requis | — |

**Ordre de synchronisation strict à la reconnexion** : 1. Nouveaux RDV → 2. Statuts modifiés → 3. Paiements Cash → 4. Notes clients.

**Résolution de conflits** : Server-Wins systématique — Supabase est toujours la source de vérité. En cas de conflit détecté (ex. créneau réservé entre-temps côté serveur), bandeau orange explicite côté UI, jamais d'écrasement silencieux.

---

## SECTION 10 — RBAC MATRIX

| Fonctionnalité | Owner | Manager | Staff | Client |
|---|---|---|---|---|
| Wallet / Cash-out / CA global | ✅ | ❌ Interdit | ❌ Interdit | — |
| Agenda équipe complet | ✅ | ✅ | ⚠️ (ses RDV uniquement) | — |
| Créer/Modifier/Annuler RDV | ✅ | ✅ | ⚠️ (ses RDV) | ⚠️ (selon politique salon) |
| Fiche client globale | ✅ | ✅ | ⚠️ (ses clients) | — |
| Encaisser (Leapa/Cash) | ✅ | ✅ | ⚠️ si permission | — |
| Module Marketing & campagnes | ✅ | ✅ | ❌ Interdit | — |
| Gérer l'équipe & invitations | ✅ | ❌ Interdit | ❌ Interdit | — |
| Appliquer une remise | ✅ 0–100% | ⚠️ max 15% (loggé) | ❌ Interdit | — |
| Initier un remboursement | ✅ (OTP) | ⚠️ Soumis à Owner | ❌ Interdit | — |
| Analytics & rapports | ✅ Complet | ⚠️ Restreint | ⚠️ Ses stats seules | — |
| Abonnement SaaS | ✅ | ❌ Interdit | ❌ Interdit | — |
| Réserver en ligne | — | — | — | ✅ |
| Payer (Leapa) | — | — | — | ✅ |
| Cartes de fidélité | — | — | — | ✅ |
| Voir ses propres métriques | ✅ | ✅ | ✅ | — |

Toute nouvelle permission doit être ajoutée à cette table **et** répliquée en policy RLS — jamais l'un sans l'autre.

**Couche granulaire additive (Phase 1.1, Enterprise Foundation V2)** — les
rôles ci-dessus restent la source de vérité (`users.role`, immuable côté
client). Un Owner peut en plus créer des `permission_groups` par salon et y
assigner des `manager`/`staff` pour leur donner des droits précis
(`check_permission(user_id, salon_id, feature, action, resource)`, cache
15 min SQL + Hive). Owner = accès total inconditionnel, jamais restreint
par cette couche. Accessible depuis `/owner/settings` (Phase 1.4). Voir
`docs/PHASE_1_1_SUMMARY.md`.

**Centre de configuration (Phase 1.4)** — `salon_settings` (1 ligne par
salon, créée automatiquement à l'INSERT du salon + backfill pour les
salons déjà existants). Politique booking/notifications/marketing/staff/
fidélité/avis/paiements/avancé — distinct de `notification_preferences`
(par utilisateur). Voir `docs/PHASE_1_4_SUMMARY.md`.

**Automation Platform (Phase 2)** — moteur générique Trigger → Conditions
→ Actions (`automation_workflows`/`automation_conditions`/
`automation_actions`), exécuté par l'Edge Function `execute-workflow`
(appelée via `supabase.functions.invoke()` depuis `create-booking`,
`leapa-webhook`, `mark-no-show`). Les actions à délai ou en échec passent
par la queue `automation_action_runs`, traitée toutes les 5 min par
`run-scheduled-actions` (pg_cron) — backoff 2/4/8 min, 3 tentatives max.
4 templates KYNZA (`is_system = TRUE`, non modifiables au niveau RLS) sont
auto-créés par salon. Tous les types de trigger/action ne sont pas câblés
— voir la colonne `wired`/`implemented` des catalogues et
`docs/PHASE_2_SUMMARY.md` pour le détail de ce qui fonctionne réellement.

**Enterprise Data Platform (Phase 3)** — 4 sous-systèmes :
1. **FTS** — `pg_trgm` GIN (accélère les ILIKE existants sans changer le
   code Flutter) + colonnes `search_vector TSVECTOR STORED` + GIN sur
   `salons`/`services` + RPC `search_salon_data()` (résultats unifiés,
   classés par pertinence, config `'simple'` pour noms propres/marques).
   `SearchRepositoryImpl` essaie le RPC en premier, bascule sur ILIKE si
   le RPC échoue ou si des filtres service-only sont actifs.
2. **mv_daily_revenue** — snapshot pré-agrégé `{salon_id, day, revenue_bif,
   bookings_*}`, rafraîchi toutes les nuits (pg_cron CONCURRENTLY).
   Pas de RLS (MV Postgres) → pas de GRANT authenticated. Vue fine
   `v_mv_daily_revenue` exposée aux utilisateurs avec filtre `salon_id`.
   Usage prévu : action `update_stats` du moteur d'automatisation.
3. **Backup** — table `backup_jobs` + bucket `kynza-backups` (privé) +
   Edge Function `create-backup` : 90j de données transactionnelles
   + référentiels complets → JSON dans le storage, 1 backup / 6h max.
4. **Templates de documents** — `document_templates` (invoice/receipt/
   monthly_report, syntaxe `{{variable}}`), `render_template()` RPC,
   3 modèles par défaut auto-créés par salon (trigger + backfill).
   Voir `docs/PHASE_3_SUMMARY.md`.

**Evolution Platform (Phase 4)** — 3 sous-systèmes indépendants, zéro
modification de l'existant :
1. **Feature Flags V2** — table `feature_flags` (catalogue global, service_role
   only en écriture) + `salon_feature_overrides` (overrides par salon, Owner ALL /
   Manager SELECT). `evaluate_feature_flag(key)` RPC : résolution ordonnée
   (override → flag désactivé → rollout 100% → bucket déterministe
   `md5(salon_id||key) mod 100`). `FeatureFlagScreen` liste les flags avec
   Switch par tile (crée/met à jour l'override), badge GLOBAL: ACTIVÉ/DÉSACTIVÉ/xx%.
2. **Maintenance Mode** — table `maintenance_windows` + `is_maintenance_active()` RPC
   (retourne toujours 1 ligne). `maintenanceStatusProvider` (non-autoDispose).
   `MaintenanceScreen` : `PopScope(canPop:false)`, `Timer.periodic(30s)` invalide
   le provider → le router re-évalue le redirect → sortie automatique en fin de
   maintenance.
3. **Version Manager** — table `app_versions` + `check_app_version(platform,
   version_code)` RPC. `appVersionCheckProvider` (non-autoDispose).
   `ForceUpdateScreen` : `PopScope(canPop:false)`, lance `url_launcher` vers
   Play Store / App Store. `kAppVersionCode` + `kAppPlatform` dans
   `lib/core/constants/app_version.dart`.
   Router : `_AuthRefreshNotifier` écoute maintenant 3 providers
   (`auth`, `maintenance`, `version`) ; chaîne de redirect : force-update > maintenance
   > null. Voir `docs/PHASE_4_SUMMARY.md`.

**Documentation & Architecture (Phase 5)** — phase purement documentaire :
- `docs/ARCHITECTURE.md` : vue système complète (stack, couches Flutter,
  multi-tenancy, RLS, Edge Functions, data flow réservation, stratégie offline).
- `docs/API_REFERENCE.md` : catalogue des 8 RPCs PostgreSQL + 8 Edge Functions
  avec params/returns/erreurs et snippets Dart/TypeScript.
- `docs/SECURITY.md` : modèle de sécurité complet (`has_role()`, RLS patterns,
  Edge Function auth, Leapa webhook HMAC, gestion secrets, règles non-négociables).
- `docs/PHASE_4_SUMMARY.md` + `docs/PHASE_5_SUMMARY.md` : résumés de phases.

---

## SECTION 11 — TESTING & CI

> ⚠️ Statut actuel : projet greenfield, aucun fichier n'existe encore. Cette section décrit la **structure cible obligatoire** à créer dès les premières fondations (setup initial), pas un état déjà en place.

Scripts cibles (`package.json` / tooling Flutter équivalent) :
- `npm run test:security` → tests RLS dédiés (Vitest ou équivalent Dart, suites par table sensible)
- `npm run test` → suite complète
- `npm run typecheck` → vérification stricte (TS si tooling web ; `dart analyze` côté Flutter)
- `npm run lint` → ESLint / `dart analyze` + `flutter_lints`

Arborescence cible :
- `src/__tests__/security/rls.test.ts` (ou équivalent) → suites RLS par table sensible (`transactions`, `bookings`, `users`, `activity_logs`, `subscriptions`, `loyalty_cards`)
- `tests/fixtures/test-accounts.ts` → comptes de test pour les 4 rôles (Owner/Manager/Staff/Client)
- `docs/security/RBAC_AUDIT.md` → audit RBAC complet, tenu à jour à chaque évolution de la Section 10
- `docs/security/SECURITY_AUDIT_LOG.md` → journal des correctifs de sécurité (Section 7)
- `docs/security/TEST_REPORT.md` → rapport de couverture des tests

CI (GitHub Actions, à créer) : déclenchée sur PR + push `main`. Bloque le merge si : un test échoue, erreur de typecheck, erreur de lint, ou échec de build.

---

## SECTION 12 — GIT WORKFLOW

> Le projet n'est pas encore initialisé en dépôt git (`git init` à faire avant le premier commit).

Conventions de commits :
```
feat(scope): description
fix(scope): description
security(scope): description
refactor(scope): description
test(scope): description
```

Branches : `main` (prod) · `staging` · `feature/xxx` · `fix/xxx`.

---

## SECTION 13 — FREEMIUM LOGIC

| Plan | Prix | Limite |
|---|---|---|
| Gratuit | 0 FBu | 20 RDV/mois |
| Pro | 45 000 FBu/mois | Illimité, multi-praticiens ≤ 10 |
| Premium | 125 000 FBu/an | Illimité + features exclusives, collaborateurs illimités |

Paliers de friction intelligente sur le plan Gratuit :
- 0–14 RDV (< 75%) : barre verte, aucun message intrusif
- 15 RDV (75%) : barre ambre — *"Plus que 5 RDV gratuits ce mois."* + CTA Découvrir Pro
- 18 RDV (90%) : barre rouge — *"Plus que 2 RDV. Ne perdez aucun client !"* + CTA Passer au Pro
- 20 RDV (100%) : blocage complet — modal *"Limite atteinte. Vos clients attendent."* + CTA upgrade

Grâce : 3 jours après expiration d'abonnement, accès complet maintenu. Au-delà → retour forcé au plan Gratuit. **Données jamais supprimées** (R12) — réactivation = accès immédiat à tout l'historique.

---

## SECTION 14 — BOOKING & MARKETPLACE LOGIC

### Machine à états
```
pending_payment → confirmed → in_progress → completed
confirmed → cancelled   (remboursement auto si priorité P1)
confirmed → no_show     (H+15min, déclenché par le Staff)
```

### Priorités de réservation
| Niveau | Statut | Garantie | Annulation |
|---|---|---|---|
| P1 | `CONFIRMED_PAID` | Non déplaçable sans confirmation/OTP | Remboursement Leapa auto |
| P2 | `CONFIRMED` | Déplaçable si urgence | Selon politique salon |
| P3 | `PENDING` | Provisoire, timeout 30 min, verrou paiement 5 min | Libération automatique |
| P4 | `WALK_IN` | Non garantie, file d'attente | Sans pénalité |

### Race conditions
`UNIQUE(practitioner_id, start_time)` + transaction SQL atomique (`SELECT FOR UPDATE` + `INSERT`). Premier arrivé confirmé normalement ; second arrivé → alternatives proposées immédiatement, jamais d'erreur brute.

### No-show
- `reliability_score -= 1` à chaque no-show détecté (Staff tape `[Absent]` après H+15min).
- ≥ 3 no-shows du même client → alerte Owner + `deposit_required = true` activé automatiquement sur ses prochains RDV.

### Buffer time
`buffer_end_time = end_time + service.buffer_min`. Bloque uniquement le planning du praticien (nettoyage/préparation). **Invisible côté client** lors de la réservation en ligne (R18 — cohérence avec l'esprit "jamais d'info interne exposée au client").

---

## SECTION 15 — ENVIRONMENTS & DEPLOYMENTS

| Environnement | Backend | Frontend |
|---|---|---|
| dev | Projet Supabase dev | local (`localhost`) |
| staging | Projet Supabase staging | Vercel preview / build Flutter staging |
| prod | Projet Supabase prod | Vercel prod (back-office web le cas échéant) + stores Flutter (Play Store / App Store) |

- Secrets : **uniquement** Supabase Vault / variables d'environnement Edge Functions. Jamais commités, jamais dans le code client.
- Clés sensibles à ne jamais exposer : `LEAPA_API_KEY`, `LEAPA_SECRET`, `FCM_KEY`, `WA_TOKEN`.

---

## SECTION 16 — SYSTEM BEHAVIOR RULES

- **Mode confidentiel** 👁 — toggle Owner qui masque tous les montants (`••••• FBu`). Persiste entre les écrans jusqu'à désactivation explicite.
- **Interface Caméléon** — `employees_count = 0` → mode Solo (calendrier 1 colonne) ; `employees_count ≥ 1` → mode Team (multi-colonnes, module Staff). Transition via `AnimatedSwitcher` 400ms, déclenchée par Supabase Realtime.
- **Kill-switch salon** — `is_online = false` désactive instantanément toutes les réservations en ligne ; salon affiché "Hors ligne" dans la recherche.
- **Révocation de session Owner** — coupe immédiatement les connexions Supabase Realtime en cours (trigger temps réel), pas d'attente du TTL JWT.
- **Anti-spam WhatsApp** — max 2 promos/semaine/salon, max 50 messages/heure. Opt-out automatique et immédiat sur réponse `STOP`/`ARRET`.
- **Score de fiabilité** — visible Owner + Staff uniquement, jamais exposé au Client (R18).
- **Analytics Staff** — classement = position uniquement ; les montants des collègues ne sont jamais exposés, même indirectement (R11).

---

## SECTION 17 — INTERNATIONALISATION

Système i18n FR/EN actif depuis 2026-07-01. Architecture : `core/localization/`.

Règles absolues :
- JAMAIS de `Text("texte")` en dur — toujours `context.l10n.xxx`
- JAMAIS de `AppLocalizations.of(context)!` — le nullable-getter est false ; utiliser `context.l10n`
- Ajouter une clé : dans `lib/l10n/app_fr.arb` ET `lib/l10n/app_en.arb`, puis `flutter gen-l10n`
- Les deux ARBs doivent toujours avoir exactement les mêmes clés (vérifié par `test/core/localization/l10n_arb_parity_test.dart`)

Références : `docs/I18N_GUIDE.md`, `docs/LANGUAGE_WORKFLOW.md`, `docs/PHASE_I18N_SUMMARY.md`

---

## SECTION 18 — DETTE TECHNIQUE

À tenir à jour à chaque phase. Ne pas corriger hors-scope sans instruction explicite.

- Pas de `ShellRoute` GoRouter — bottom nav toujours en state local (`_tabIndex`) par `Home*Screen`. Le rendu visuel a été remplacé par `KynzaBottomNav` (`lib/shared/navigation/`, voir `docs/BOTTOM_NAVIGATION_GUIDE.md`) mais chaque onglet reste un widget swappé par `switch`, pas une route GoRouter — les tabs ne sont donc ni deep-linkables ni dans un `StatefulShellRoute`. Migration complète (extraction de chaque onglet en route + `StatefulShellRoute`) à faire avant Play Store (voir mémoire `shellrouter_refactor_backlog`).
- 0 screens non migrés — i18n 100% complet depuis 2026-07-01 (tous les écrans utilisent `context.l10n`, parité ARB FR/EN vérifiée par test automatique).
- Coordonnées bancaires (`KynzaConstants.bankTransferInstructions`) = placeholders, à remplacer avant toute vraie demande d'upgrade client.
- Keystore Android debug (pas de signing release configuré).
- Leapa API non live (compte en attente) — paiements mobile money non fonctionnels en prod.
- `KynzaLoyaltyCardSkeleton` (Phase A) non branché sur `loyalty_card_widget.dart`/`client_loyalty_screen.dart` — le skeleton générique en place (`height: 220`) correspond à la hauteur réelle de la carte ; le variant nommé est plus court et introduirait un saut de layout. Vérifier la hauteur réelle avant de basculer.
- Recherche avancée (`advanced_search_screen.dart`) : résultats toujours sur skeleton générique — aucun des 7 variants nommés (Phase A) ne correspond à la disposition avatar+titre+sous-titre+trailing.
- RBAC (Phase 1.1) : pas d'écran dédié pour les overrides par utilisateur (`user_permission_overrides`) — la table et `check_permission()` les gèrent, seule l'assignation à un groupe a une UI. Pas d'écran "audit des permissions" (qui a accès à quoi, vue transverse). L'entrée "Permissions & Équipe" vit désormais dans `/owner/settings` (Phase 1.4) — déplacée de l'onglet Profil de l'Owner où elle vivait temporairement en 1.1/1.2.
- Audit (Phase 1.2) : `mv_audit_stats` n'a aucun consommateur (pas d'écran de stats dessus). Pas de collecte device_info/app_version/screen_name (colonnes présentes, non alimentées — nécessiterait `package_info_plus`/`device_info_plus`, pas encore une dépendance du projet). Pas d'export PDF du journal (CSV seulement). Le logging des changements de `salon_settings` est différé à la Phase 1.4 (la table n'existe pas encore).
- Versioning (Phase 1.3) : `entity_versions` n'a aucun consommateur Flutter (pas d'écran d'historique, pas de `compare()`/`restore()`) — mécanisme backend vérifié fonctionnel uniquement. `restore()` nécessiterait du SQL dynamique par `entity_type` ou de la logique Dart par entité ; pas construit avant qu'un écran en ait réellement besoin.
- Settings (Phase 1.4) : pas de `PermissionGuard` sur les écrans de catégorie au-delà du `_RoleGuard` owner-only de la route — suffisant tant que seul l'Owner atteint `/owner/settings`. Pas de validation des champs entier/texte au-delà de `int.tryParse` (aucune borne min/max appliquée côté UI).
- Automation (Phase 2) : 4 des 8 types de trigger ne sont câblés nulle part (`booking.completed`/`booking.cancelled` passent par des `.update()` Flutter directs, pas d'Edge Function à brancher ; `review.submitted` idem ; `loyalty.card_full` n'est délibérément pas branché dans `validate-qr`, qui gère déjà ce cas pour éviter une double notification). 3 des 8 types d'action ne sont pas implémentés (`send_email` — interdit par R14 et aucune infra —, `create_invoice` — schéma `invoices.plan_key` incompatible —, `update_stats` — cible `mv_daily_revenue` disponible depuis Phase 3, reste à câbler). L'éditeur de conditions/actions Flutter est fonctionnel mais basique (champs texte libres, pas d'autocomplétion sur `available_context`, pas de réordonnancement par glisser-déposer).
- Data Platform (Phase 3) : `mv_daily_revenue` n'a aucun consommateur Flutter direct (les dashboards utilisent toujours `v_salon_kpis`) — `v_mv_daily_revenue` est wired mais pas encore appelée par un écran. `render_template()` RPC branché dans le repository mais pas de "preview du rendu" dans l'UI. Pas de test end-to-end live de `create-backup` (Edge Function déployée, structure vérifiée, test en conditions réelles à faire via l'app). FTS ne retrouve pas les noms de salon sans espace (ex. `'SalonBeauteQA'` n'est pas trouvé par `p_query='salon'` — comportement FTS correct, le fallback ILIKE gère ce cas).
- Evolution Platform (Phase 4) : `kAppVersionCode = 1` est une constante hardcodée dans `app_version.dart` — doit être mise à jour manuellement en sync avec `pubspec.yaml` à chaque release (une intégration `package_info_plus` l'automatiserait). `kPlayStoreUrl` et `kAppStoreUrl` sont des placeholders jusqu'à la première soumission aux stores. `evaluate_feature_flag()` retourne `false` appelée avec `service_role` (pas de `salon_id` en contexte) — comportement attendu et sûr. `ForceUpdateScreen` et `MaintenanceScreen` ont `PopScope(canPop:false)` sans possibilité de bypass manuel pour l'Owner — prévu, mais à documenter dans les release notes internes.
- Loader Officiel (KynzaLoader) : `KynzaLoaderVariant.linear` (progression déterministe) documenté dans `docs/LOADER_GUIDE.md` mais non codé — aucun cas d'usage réel dans le projet (pas d'upload avec % connu). Les goldens de `test/golden/kynza_loader_golden_test.dart` ont été générés puis inspectés visuellement une fois lors de cette phase ; toute régénération future (`--update-goldens`) doit repasser par une inspection visuelle avant merge.

---

## SECTION 19 — LOADER OFFICIEL

`KynzaLoader` (`lib/shared/widgets/loader/`) est l'**unique** composant de
chargement autorisé dans l'application — "Orbite Dorée", dessiné à la main
via `CustomPainter`/`AnimationController`, sans dépendance externe.

- **Interdiction absolue** de réintroduire un `CircularProgressIndicator`
  brut ailleurs que dans l'exception documentée (`RefreshIndicator` stylé
  gold, pull-to-refresh natif — geste non réimplémentable sans régression).
- Variantes d'usage : `KynzaLoaderInline` (sections/listes/gardes de route),
  `KynzaLoaderFullscreen` (écran de chargement dédié), `KynzaLoaderOverlay`
  + `loaderOverlayProvider` (opération critique bloquante, câblé dans
  `main.dart` au-dessus de `MaterialApp.router`), `KynzaLoaderButton` (état
  `isLoading` d'un bouton, avec variante `onGoldBackground`).
- Distinct de `KynzaSkeleton`/`KynzaCardSkeletons` (shimmer) — systèmes
  complémentaires, jamais fusionnés.
- Référence complète : `docs/LOADER_GUIDE.md`. Audit préalable au
  remplacement : `docs/audit/LOADER_AUDIT.md`.

---

*KYNZA — AGENT.md · Document fondateur · Production-Ready target · Flutter + Supabase + Leapa · Burundi 2026*
