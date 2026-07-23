# KYNZA Messaging — Foundation Checklist

Document de suivi de progression du chantier Messaging. Source normative pour le contenu : voir
`docs/ADR_MESSAGING_FOUNDATION.md` (statuts, preuves, ledger). Ce document ne redéfinit rien — il
suit l'avancement. Mise à jour obligatoire à chaque commit qui ferme un item (Rule 8, étape
« Documentation »).

**Dernière mise à jour** : 2026-07-23 (Migration 1.5 committée — DEC-013/021/022/023 fermées avec
preuve réelle).

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
- [ ] `T-depth-01` (branche `nested`/`pg_trigger_depth()>1`) — **non testable avant Migration 2**
      (aucun trigger imbriqué n'existe encore), explicitement non fermé, pas silencieusement oublié
      (voir ADR, Correction 4 et Migration 1.5 §"Explicitement non testé")
- [ ] Ajout de `conversations` à `supabase_realtime` — **délibérément hors périmètre de Migration
      1.5** (résidu #5, pas une `DEC`), reste `OPEN`, à fermer par son propre commit avant que
      Migration 2 ne s'appuie sur le Realtime de `messages`

## Messages

- [ ] Migration 2 écrite (schéma, doc canonique `KYNZA_MESSAGING_ARCHITECTURE.md:269-292`)
- [ ] RLS `messages_participant_select`/`_insert`/`_recipient_mark_read`
- [ ] DEC-016 intégré dès l'écriture de la RLS d'`INSERT` (booking actif, catégorie `client_staff`)
- [ ] `client_message_id` + `uq_message_client_dedup` (dédup offline)
- [ ] `bump_conversation_on_message`/`reset_unread_on_read` — `SECURITY DEFINER`, garde
      `pg_trigger_depth()` vérifié empiriquement contre `protect_conversation_columns`
- [ ] Ajout de `messages` à `supabase_realtime`
- [ ] Tests réels (positif + négatif), rollback vérifié, cleanup, commit unique

## Rapports (`message_reports`)

- [ ] Migration 3 écrite
- [ ] RLS (signalement par participant, lecture owner/manager)
- [ ] Trigger `flag_message_on_report` (doc canonique, si retenu tel quel)
- [ ] Tests réels, rollback vérifié, cleanup, commit unique

## Jetons d'appareil (`device_tokens`)

- [x] Table déjà en production (`20260717140000_device_tokens.sql`)
- [ ] Migration 4 — raccordement applicatif à la messagerie (pas de nouvelle table)

## Fonctions de bord (Edge Functions)

- [ ] `create-conversation` (règle anti-spam, éligibilité historique de réservation)
- [ ] `send-message-push` (miroir `_shared/fcm.ts`)
- [ ] `toggle-conversation-block` (**nouvelle**, DEC-015 — autorité actuelle, écrit `activity_logs`,
      lit `salon_id` depuis la ligne ciblée, jamais depuis l'appelant — voir ADR §D.6)
- [ ] `report-message` (écrit `message_reports`)
- [ ] Cas cross-salon testé et rejeté (`toggle-conversation-block`)

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
