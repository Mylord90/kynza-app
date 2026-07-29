# KYNZA Messaging — Traceability Matrix

Relie chaque décision d'architecture verrouillée (ADR) à son implémentation de bout en bout :
Migration → Trigger → Policy → Edge Function → Realtime → Tests. Source normative :
`docs/ADR_MESSAGING_FOUNDATION.md`. Toute ligne dont une colonne est vide et n'est pas légitimement
`—` (non applicable) est une trace incomplète — à corriger avant que la ligne concernée ne puisse
être marquée "Prêt pour la production" dans la checklist.

**Dernière mise à jour** : 2026-07-28 (correction de 2 incohérences internes trouvées lors de la
préparation Lot 1.2 : invariant 7bis affiché `OPEN` alors que "décision 3" le ferme déjà en Migration
2 ; publication Realtime affichée `Non` pour `conversations`/`messages` alors que la ligne DEC-014 du
même document la disait déjà vérifiée). Voir aussi
`docs/MESSAGING_ROADMAP.md`/`docs/MESSAGING_EXECUTION_PLAN.md` pour le découpage des phases/lots
restants et `docs/MESSAGING_API_CONTRACT.md` pour le contrat Backend↔Flutter — ce document reste
strictement la trace décision→preuve, il ne redéfinit pas l'ordre de livraison.

---

## Legend

- **Statut** : `LOCKED` (prouvé, appliqué) · `LOCKED (design)` (spec verrouillée, SQL non écrit) ·
  `OPEN` (gap tracé) · `PLANNED` (non commencé)
- `—` = non applicable à cette décision (ex. une CHECK n'a pas d'Edge Function)

| DEC | Décision | ADR §/Statut | Migration | Trigger | Policy RLS | Edge Function | Realtime | Tests |
|---|---|---|---|---|---|---|---|---|
| DEC-001 | FK simple `related_booking_id` | §1, `LOCKED` | Migration 1 (`28a269c`) | — | — | — | — | T5 (`23503`) |
| DEC-002 | FK composite (identité booking) | §1, `LOCKED` | Migration 1 | — | — | — | — | T4, T9 |
| DEC-003 | MATCH SIMPLE | §1, `LOCKED` | Migration 1 | — | — | — | — | sondage `pg_constraint` |
| DEC-004 | `chk_staff_type` biconditionnelle | §1, `LOCKED` | Migration 1 | — | — | — | — | T1, T2 (`23514`) |
| DEC-005 | `chk_staff_requires_booking` (inv. 1) | §1, `LOCKED` | Migration 1 | — | — | — | — | T3 (`23514`) |
| DEC-006 | Trigger invariant 7 (salon actif) | §1, `LOCKED` | Migration 1 | `trg_check_conversation_salon_active` | — | — | — | T6a, T6b (`P0001`) |
| DEC-007 | Invariant 9 (aucun bypass) | §1, `LOCKED` | Migration 1 | (propriété transversale) | — | — | — | T6b, sondage `pg_roles` |
| DEC-008 | UNIQUE additif `bookings` | §1, `LOCKED` | Migration 1 | — | — | — | — | preuve logique (sur-ensemble PK) |
| DEC-009 | Index uniques TOTAUX | §1, `LOCKED` | Migration 1 | — | — | — | — | T7, T8 (`23505`) |
| DEC-010 | `NO ACTION` sur toutes FK | §1, `LOCKED` (ticket RGPD ouvert) | Migration 1 | — | — | — | — | lecture DDL |
| DEC-011 | Commentaires protecteurs | §1, `LOCKED` | Migration 1 | — | — | — | — | recherche exhaustive (7 `COMMENT ON`) |
| DEC-012 | Convention de nommage FK | §1, `LOCKED` | Migration 1 | — | — | — | — | recherche repo-wide |
| DEC-013 | `protect_conversation_columns` (7 catégories, refus par défaut) | §A, **`LOCKED`** | **Migration 1.5** (`20260723120000_conversations_hardening_1_5.sql`) | `trg_protect_conversation_columns` (appliqué, `is_system` version 3 finale après 2 versions rejetées en cours de revue — voir ADR « Découverte critique pendant l'audit adversarial ») | `conversations_client_update_own_state`/`_staff_update_own_state`/`_owner_manager_update_own_state` (DEC-023) | — | — | `T-cols`, `T-upd-forge-01`, `T-drift-09`, `T-cat-A/B/C/D/E/F`, `T-cat-null-context` (tous réels, voir ADR "Migration 1.5" + "Découverte critique") |
| DEC-014 | Trigger de compteurs (`SECURITY DEFINER` + `pg_trigger_depth()`) | §A.4, **`LOCKED`** | **Migration 2** (`20260723180000_messages_schema_migration_2.sql`, commit `d3c1d0f`) | `bump_conversation_on_message`/`reset_unread_on_read` (**appliqués**, `prosecdef=true` vérifié en base) | — (contourne RLS via `SECURITY DEFINER`, bloqué uniquement par DEC-013) | — | `messages`/`conversations` en publication (vérifié `pg_publication_tables`) | `T-depth-01` **fermé** — "DEC-014: bump_conversation_on_message correctly incremented client_unread_count + preview", "reset_unread_on_read decremented client_unread_count on read transition" (noms exacts, tests réels contre production, `BEGIN...ROLLBACK`) |
| DEC-015 | Règle de blocage (autorité actuelle) | §B/§C, `LOCKED` | Migration 1.5 (colonnes déjà en Migration 1) | protégé par `trg_protect_conversation_columns` (Catégorie E, **appliqué et testé** — `T-cat-E-neg`/`T-cat-E-pos`) | `messages_participant_insert` (`blocked_by IS NULL`, **appliquée**, vérifiée `pg_policies` live) — test "blocked_by IS NOT NULL blocks new sends regardless of DEC-016/decision-3 status" | **`toggle-conversation-block`** (**PLANNED** — Phase 2/Lot 2.5, `docs/MESSAGING_EXECUTION_PLAN.md`) | — | cas rotation manager, cas cross-salon (D.6) — **toujours planifiés**, non fermés tant que l'Edge Function n'est pas écrite ; colonnes/RLS d'insertion désormais réelles et testées |
| DEC-016 | Éligibilité catégorie 2 (booking actif) | §B.3, **`LOCKED`** | **Migration 2** (`20260723180000_messages_schema_migration_2.sql`, commit `d3c1d0f`) | — | `messages_participant_insert` (clause `bookings.status`, **appliquée**) | — (distinct de `create-conversation`, voir §B.3) | — | "DEC-016: client cannot send once the cited booking is cancelled", "DEC-016: assigned staff cannot send once the cited booking is cancelled (symmetric)" (tests réels contre production) |
| — | Décision 1 (hors ledger) — soft-delete `messages` : `deleted_at` unique, auteur seul | ADR §"Migration 2" | Migration 2 | `trg_protect_message_columns` (Catégorie D) | `messages_sender_soft_delete` | — | — | "author can soft-delete their own message...", "non-author (staff) cannot soft-delete..." |
| — | Décision 3 (hors ledger) — garde salon-actif `client_salon`, symétrique DEC-016 | ADR §"Migration 2", résidu #3 fermé | Migration 2 | — | `messages_participant_insert` (clause `salons.deleted_at`) | — | — | "decision 3 baseline: salon B's own owner can send...", "decision 3: send blocked once the client_salon salon becomes soft-deleted after opening" |
| — | `protect_message_columns` (mécanisme, mirroring DEC-013) | ADR §"Migration 2" | Migration 2 | `trg_protect_message_columns` | (garde de colonnes, pas une policy) | — | — | "...blocks rewriting conversation_id...", "...blocks editing body...", "...blocks a sender from forging is_flagged", "read_at cannot be forged...", "anti-drift net rejects..." |
| DEC-017 | Catégorie 3 (diffusion) | `OUT-OF-SCOPE` | — | — | — | — | — | — |
| DEC-018 | `gift_cards` | `OUT-OF-SCOPE` | — | — | — | — | — | — |
| DEC-019 | Attachement `coupon` | `OUT-OF-SCOPE` | — | — | — | — | — | — |
| DEC-020 | `conversation_requests` | `OUT-OF-SCOPE` | — | — | — | — | — | — |
| DEC-021 | Gap RLS Migration 1 (UPDATE sans restriction colonnes) | §1, **`LOCKED` (fermé)** | Migration 1.5 | fermé par `trg_protect_conversation_columns` | `conversations_client_update_own_state`/`_staff_update_own_state` (inchangées, désormais bornées par le trigger) | — | — | tests DEC-013 (ci-dessus), en particulier `T-cat-E-neg` (rang CRITIQUE matrice de criticité) |
| DEC-022 | `staff_id IN (...)` sans `is_active`/`deleted_at` | §D.3, **`LOCKED` (fermé)** | Migration 1.5 | — | `conversations_staff_select`/`_staff_update_own_state` (**corrigées, `DROP`+`CREATE POLICY`**), `messages_participant_*` (à écrire correctement dès le départ, Migration 2) | — | — | `T-dec022-neg-select` (0 rows), `T-dec022-neg-update` (0 rows), `T-dec022-pos` (régression, 1 row) — tous réels |
| DEC-023 | Aucune policy UPDATE owner/manager | §D.2, **`LOCKED` (fermé)** | Migration 1.5 | — | **`conversations_owner_manager_update_own_state`** (appliquée) | — | — | `T-dec023-pos` (même salon, accepté), `T-dec023-neg` (salon différent, 0 rows — aucune fuite cross-salon) |

---

## Traçabilité transversale — invariants métier (catalogue ADR §3)

| Invariant | Mécanisme | Table | Statut |
|---|---|---|---|
| 1 — `client_staff` requiert booking | CHECK `chk_staff_requires_booking` | `conversations` | `LOCKED` |
| 2/3/4 — tuple cohérent avec booking | FK composite | `conversations` | `LOCKED` |
| 5 — booking existe (`client_salon`) | FK simple | `conversations` | `LOCKED` |
| 6 — staff↔salon cohérent | Hérité de `bookings` via FK composite | `conversations` | `LOCKED` |
| 7 — salon actif à l'ouverture | Trigger `BEFORE INSERT` | `conversations` | `LOCKED` |
| 7bis — salon actif à l'envoi (fil déjà ouvert) | "décision 3", clause `messages_participant_insert` | `messages` | `LOCKED`, appliqué (Migration 2, `20260723180000_messages_schema_migration_2.sql:167-172`) — résidu §3 ADR fermé |
| 8 — paire unique | Index UNIQUE | `conversations` | `LOCKED` |
| 9 — aucun bypass (`service_role` compris) | Propriété structurelle | toutes | `LOCKED` |
| 10 (nouveau) — booking actif pour message `client_staff` (DEC-016) | RLS à la volée | `messages` (futur) | `LOCKED (règle)`, SQL planifié |
| 11 (nouveau) — colonnes protégées par catégorie (DEC-013) | Trigger + filet `to_jsonb` | `conversations` | `LOCKED`, appliqué et testé (Migration 1.5) |
| 12 (nouveau) — autorité de déblocage actuelle, pas figée (DEC-015) | Edge Function `service_role` | `conversations` | `LOCKED`, colonne protégée (Migration 1.5) ; Edge Function `toggle-conversation-block` toujours planifiée (Phase 2) |

## Traçabilité — publication Realtime (ADR §D.8)

| Table | Dans `supabase_realtime` ? | Action requise |
|---|---|---|
| `services`, `bookings`, `staff_profiles` | Oui (`20260624040000_enable_realtime_publication.sql`) | — |
| `conversations` | **Oui** (`20260723180000_messages_schema_migration_2.sql:393`) | — |
| `messages` | **Oui** (`:394`) | — |
