# KYNZA Messaging — Foundation Checklist

Document de suivi de progression du chantier Messaging. Source normative pour le contenu : voir
`docs/ADR_MESSAGING_FOUNDATION.md` (statuts, preuves, ledger). Ce document ne redéfinit rien — il
suit l'avancement. Mise à jour obligatoire à chaque commit qui ferme un item (Rule 8, étape
« Documentation »).

**Dernière mise à jour** : 2026-07-23 (Migration 2 committée — DEC-014/016 fermées avec preuve réelle ;
voir aussi `docs/MESSAGING_ROADMAP.md`/`docs/MESSAGING_EXECUTION_PLAN.md` pour la suite de la
livraison par phases/lots, et `docs/MESSAGING_API_CONTRACT.md` pour le contrat Backend↔Flutter).

---

## Gouvernance

- [x] ADR VERROUILLÉ (Migration 1, `28a269c`/`a6e3aee`) — DEC-001 à DEC-012
- [x] Addendum post-lock (provenance des preuves, re-sondage live) — `a6e3aee` (suivant)
- [x] Revue de finalisation de la fondation (BLOQUANT 1, BLOQUANT 2, DEC-013 à DEC-016 verrouillées
      en conception) — 2026-07-22
- [x] Checklist / Matrice de traçabilité / Definition of Done créées — 2026-07-22
- [x] 5 corrections pré-Migration 1.5 documentées (test `updated_at` réel, nuance sécurité du
      rollback, matrice de criticité des policies orphelines, arbitrage DEC-014, test Realtime RLS
      dans le DoD) — 2026-07-23
- [x] DEC-021, DEC-022, DEC-023 fermées avec preuve réelle (Migration 1.5,
      `20260723120000_conversations_hardening_1_5.sql`)

## Migration 1 — `conversations`

- [x] Schéma appliqué en production (`20260721160000_conversations_schema.sql`, commit `28a269c`)
- [x] 12/12 tests réels (T1-T9, T6a/T6b, T-inv4, T-inv8) — voir ADR §3, §7
- [x] Rollback vérifié (schéma miroir `zz_conv_rollback_check`)
- [x] Commentaires protecteurs (7 `COMMENT ON`) — ADR §8

## Migration 1.5 — `conversations` hardening

- [x] `protect_conversation_columns` (DEC-013) — trigger `BEFORE UPDATE`, 7 catégories, filet
      anti-dérive `to_jsonb` — appliqué (`20260723120000_conversations_hardening_1_5.sql`)
- [x] Policy `conversations_owner_manager_update_own_state` (DEC-023) — appliquée
- [x] Filtre `is_active`/`deleted_at` sur `conversations_staff_select`/`_update_own_state`
      (DEC-022) — appliqué (`DROP`+`CREATE POLICY`)
- [x] DEC-021 fermé comme conséquence directe de DEC-013 (colonnes désormais protégées)
- [x] 18 tests réels exécutés (T-cols, T-upd-forge-01, T-drift-09, T-cat-A, T-cat-A-salon,
      T-cat-B/C/D/E/F ×positif+négatif selon catégorie, T-cat-null-context, T-dec022 ×3,
      T-dec023 ×2) — voir ADR, sections "Migration 1.5 — Implémentation et clôture" et "Découverte
      critique pendant l'audit adversarial" (2 versions de `is_system` testées et rejetées avant la
      version finale committée)
- [x] Rollback vérifié en schéma miroir isolé `zz_conv15_rollback_check` (jamais en production),
      qualifié explicitement comme non-neutre en sécurité (Correction 2)
- [x] Cleanup vérifié à 0 (lignes de test, fixture staff réactivée, schéma miroir détruit)
- [x] `T-depth-01` (branche `nested`/`pg_trigger_depth()>1`) — **fermé par Migration 2** :
      `trg_bump_conversation_on_message` est le premier trigger imbriqué réel sur `conversations`,
      test "DEC-014: bump_conversation_on_message correctly incremented..." en est la preuve empirique
      (voir ADR §"Migration 2 — Implémentation et clôture")
- [x] Ajout de `conversations` à `supabase_realtime` — fermé par Migration 2 (même fichier que
      l'ajout de `messages`, résidu #5 clos)

## Migration 2 — `messages`

- [x] Schéma appliqué en production (`20260723180000_messages_schema_migration_2.sql`, commit `d3c1d0f`) — 14 colonnes
- [x] RLS `messages_participant_select`/`_insert`/`_recipient_mark_read`/`_sender_soft_delete`
- [x] DEC-016 intégré dès l'écriture de la RLS d'`INSERT` (booking actif, `client_staff`) **+**
      décision 3 (garde salon-actif symétrique pour `client_salon`, confirmée avant écriture)
- [x] `client_message_id` + `uq_message_client_dedup` (dédup offline)
- [x] `bump_conversation_on_message`/`reset_unread_on_read` — `SECURITY DEFINER`, garde
      `pg_trigger_depth()` vérifiée empiriquement (voir `T-depth-01` ci-dessus)
- [x] `protect_message_columns` (nouveau mécanisme, mirroring DEC-013) — colonne-par-colonne,
      `read_at` forcé serveur, filet anti-dérive
- [x] Ajout de `messages` (et `conversations`) à `supabase_realtime`
- [x] 36 tests réels (`BEGIN...ROLLBACK` contre production), rollback vérifié UP→DOWN en transaction
      dédiée, cleanup vérifié à 0, commit unique (`d3c1d0f`)
- [x] 3 décisions pré-écriture confirmées explicitement (soft-delete auteur seul, édition différée,
      garde salon-actif) + 2 corrections mécaniques (filtre DEC-022, supervision owner/manager) — voir
      ADR §"Migration 2 — Implémentation et clôture"
- [ ] Édition de message (`edited_at`/fenêtre) — **différée par décision, pas un oubli** ; reprise en
      Phase 2/Lot 2.4 (`docs/MESSAGING_EXECUTION_PLAN.md`)

## Rapports (`message_reports`) — Phase 4 (`docs/MESSAGING_ROADMAP.md`)

- [ ] 5 points de conception tranchés (Lot 4.1) avant toute ligne SQL : conflit `protect_message_columns`
      (trigger `flag_message_on_report`), UNIQUE anti-doublon, conflit d'intérêt `FOR ALL`
      owner/manager, traçabilité `activity_logs`, DEC-XXX à assigner
- [ ] Migration 3 écrite (Lot 4.2)
- [ ] RLS (signalement par participant, lecture/résolution selon décision Lot 4.1)
- [ ] Trigger `flag_message_on_report` — `SECURITY DEFINER` ou garde `nested`, selon décision Lot 4.1
- [ ] Rate limiting — réutilisation `checkRateLimit()`/`check_rate_limit()` (ADR-0001, déjà en
      production sur ~15 Edge Functions), pas un nouveau mécanisme (Lot 4.3)
- [ ] Tests réels (y compris non-régression `protect_message_columns`), rollback vérifié, cleanup,
      commit unique

## Jetons d'appareil (`device_tokens`)

- [x] Table déjà en production (`20260717140000_device_tokens.sql`)
- [ ] Raccordement applicatif à la messagerie (push au message) — Phase 3 (Notifications),
      `docs/MESSAGING_EXECUTION_PLAN.md` Lot 3.1

## Fonctions de bord (Edge Functions) — voir `docs/MESSAGING_API_CONTRACT.md` pour le contrat complet

- [ ] `create-conversation` (règle anti-spam, éligibilité historique de réservation) — code écrit,
      testé (QA SQL 6/6 réels contre production), **MERGED, NON DÉPLOYÉ** (absent de `supabase
      functions list` — voir convention de statuts, ADR) — Phase 1/Lot 1.1
- [x] `send-message` — **décision prise : RLS direct** (`messages_participant_insert`), aucune Edge
      Function — 36 tests réels Migration 2 couvrent la base ; reste ouvert : résidu #7 (clause
      `deleted_at`, SQL en attente d'un commit distinct)
- [ ] `sendMessagePush` (miroir `_shared/fcm.ts`) — Phase 3/Lot 3.1
- [ ] `toggle-conversation-block` (DEC-015 — autorité actuelle, écrit `activity_logs`, lit `salon_id`
      depuis la ligne ciblée, jamais depuis l'appelant — voir ADR §D.6) — Phase 2/Lot 2.5
- [ ] `report-message` (écrit `message_reports`) — Phase 4/Lot 4.2
- [ ] Cas cross-salon testé et rejeté (`toggle-conversation-block`, `report-message`)

## Temps réel

- [ ] `conversations` ajoutée à `supabase_realtime`
- [ ] `messages` ajoutée à `supabase_realtime`
- [ ] Stream `messages` par conversation borné (`.order().limit()`, ADR-0004) — vérifié
      empiriquement, pas seulement par lecture de config

## Notifications

- [ ] Intégration `notification_templates`/`_shared/fcm.ts` existants (D2 — pas de duplication de
      `notification_logs`)
- [ ] Badge agrégé (`SUM(*_unread_count)`, pas de table `user_message_badges` — décision
      anti-inflation déjà actée)

## Pièces jointes

- [ ] Modèle `attachment JSONB` discriminé (image/gif/promotion/booking_confirmation) implémenté
- [ ] Re-fetch séparé de `promotions` à l'affichage (jamais une jointure SQL sur le stream de
      messages) — doc canonique `:314-333`
- [ ] Stockage (Supabase Storage) câblé pour image/gif

## Tests

- [ ] RLS (positif + négatif, toutes policies, y compris DEC-022/023 après fermeture)
- [ ] Concurrence (`T-depth-01` trigger imbriqué, compteurs concurrents §D.5)
- [ ] Sécurité (rejeu adversarial de l'ADR §D contre la base réellement appliquée)
- [ ] Charge/performance — différée à l'échelle réelle (ADR §10), pas un critère de cette fondation
- [x] `T-cols` (garde-fou statique anti-dérive de colonnes, ADR §A.3) — exécuté en Migration 1.5,
      à rejouer à chaque migration future qui touche `conversations`

## QA

- [ ] Revue croisée de chaque migration (Rule 8, étape « Validation »)
- [ ] Revue de sécurité rejouée après implémentation réelle (pas seulement en conception)

## Flutter

- [ ] `lib/features/messaging/` (domain/data/application/presentation, calqué sur `reviews/`)
- [ ] `is_local` implémenté et testé (`T-local-01`, ADR §B.1)
- [ ] Offline (`MutationOutboxService` + `OfflineSyncCoordinator`, backoff)
- [ ] Écrans : Inbox client, Inbox salon, Chat, Recherche, États UX (bloqué/archivé/masqué)
- [ ] `StatefulShellRoute` (résorbe la dette `_tabIndex` documentée séparément)

## Prêt pour la production

- [ ] Definition of Done satisfaite pour chaque feature (`docs/MESSAGING_DEFINITION_OF_DONE.md`)
- [ ] Matrice de traçabilité à jour (`docs/MESSAGING_TRACEABILITY_MATRIX.md`)
- [ ] Aucun résidu de sévérité "Élevée" ouvert (voir ADR, section Résidus)
- [ ] Manuels d'exploitation rédigés (procédure support litige bloqué/débloqué)
- [ ] Monitoring/alertes en place
