# KYNZA Messaging — Contrat d'API (Backend ↔ Flutter)

**But de ce document** : permettre à un développeur Flutter d'implémenter le domaine `lib/features/messaging/`
sans jamais ouvrir `supabase/migrations/`. Chaque opération ci-dessous est décrite avec tout ce qui
est nécessaire pour l'appeler correctement et gérer ses erreurs — pas seulement sa signature.

**Statut par opération** — trois valeurs possibles, jamais ambiguës :
- **SHIPPED** : en production, testé, référencé par migration/commit réel.
- **PLANNED** : spécifié par l'ADR mais pas encore codé — le contrat ci-dessous est la cible, pas
  l'état actuel. Ne pas appeler avant le commit qui le ferme (voir `MESSAGING_EXECUTION_PLAN.md`).
- **DÉCISION REQUISE** : ni l'ADR ni ce document ne tranche cet aspect — un choix doit être fait en
  ouverture du lot concerné avant que la ligne "PLANNED" ne devienne exploitable.

**Source normative pour les décisions d'architecture** : `docs/ADR_MESSAGING_FOUNDATION.md`. Ce
contrat ne redéfinit aucune règle métier, il les rend consultables sans lire le SQL.

---

## 1. Conversation

### 1.1 `createConversation` — **SHIPPED (spec) / PLANNED (code)**

| Champ | Valeur |
|---|---|
| Responsabilité | Ouvrir une conversation `client_staff` ou `client_salon`, en appliquant l'éligibilité anti-spam (historique de réservation) — la seule règle non exprimable en contrainte SQL |
| Edge Function | `create-conversation` (service_role) — **PLANNED**, non encore codée (Lot 1.1) |
| Paramètres | `type: 'client_staff' | 'client_salon'`, `salon_id: uuid`, `staff_id?: uuid` (requis si `client_staff`), `related_booking_id?: uuid` (requis si `client_staff`) |
| Réponse | `{ conversation_id: uuid, created_at: timestamptz }` |
| Erreurs | `403 not_eligible` (pas d'historique de réservation qualifiant), `409 already_exists` (index unique déjà satisfait — `uq_conversations_client_staff`/`uq_conversations_client_salon`, à vérifier noms exacts avant implémentation), `422 invalid_type` |
| Contraintes métier | Éligibilité anti-spam exacte : **DÉCISION REQUISE** (Lot 1.1) — l'ADR ne fixe que le principe |
| RLS impliquée | Aucune policy `INSERT` authenticated sur `conversations` (Migration 1 : "création uniquement via l'Edge Function `create-conversation`, service_role") |
| Triggers exécutés | `trg_check_conversation_salon_active` (BEFORE INSERT, invariant 7/DEC-006 — salon actif), `conversations_updated_at` |
| Événements Realtime | Aucun à la création (le client crée puis s'abonne) |
| Tests obligatoires | Positif (historique valide), négatif (aucun historique), cross-salon rejeté, salon soft-supprimé rejeté (invariant 7) |
| Flutter Repository attendu | `ConversationRepository.create({type, salonId, staffId?, relatedBookingId?}) → Future<Conversation>` |

### 1.2 `listConversations` — **SHIPPED**

| Champ | Valeur |
|---|---|
| Responsabilité | Lister les conversations visibles par l'appelant (client, staff assigné actif, owner/manager du salon) |
| Accès | RLS directe, `SELECT` sur `public.conversations` |
| Paramètres (requête Flutter) | Filtre client SDK : `.eq('client_id', uid)` OU dépend du rôle appelant (voir policies) ; tri `.order('last_message_at', ascending: false)` ; pagination `.range()` ou `.limit()` |
| Réponse | Liste de lignes `conversations` (23 colonnes, voir `20260721160000_conversations_schema.sql`) |
| Erreurs | Aucune — RLS filtre silencieusement, jamais d'erreur pour "pas visible" |
| Contraintes métier | Un staff désactivé/retiré ne voit plus ses conversations (DEC-022, filtre `is_active`/`deleted_at` déjà dans la policy) |
| RLS impliquée | `conversations_client_select`, `conversations_staff_select` (filtré DEC-022), `conversations_owner_manager_select` |
| Triggers exécutés | Aucun (lecture) |
| Événements Realtime | `postgres_changes` sur `conversations` (déjà en publication `supabase_realtime`) pour `last_message_at`/compteurs |
| Tests obligatoires | Chaque rôle voit exactement ses lignes attendues, staff désactivé voit 0 ligne |
| Flutter Repository attendu | `ConversationRepository.watchAll() → Stream<List<Conversation>>` (stream borné, jamais un `.stream()` non filtré/non limité — ADR-0004) |

### 1.3 `updateConversationState` (pin/archive/hide) — **SHIPPED**

| Champ | Valeur |
|---|---|
| Responsabilité | Épingler/archiver/masquer une conversation de son propre côté |
| Accès | RLS directe, `UPDATE` sur `public.conversations`, colonnes `client_pinned`/`client_archived`/`client_hidden_at` (côté client) ou `salon_pinned`/`salon_archived`/`salon_hidden_at` (côté salon) |
| Paramètres | `conversationId: uuid`, `field: 'pinned'|'archived'|'hidden'`, `value: bool | timestamptz` |
| Réponse | Ligne mise à jour |
| Erreurs | `42501` (RLS) si l'appelant n'est pas partie légitime ; **`P0001` si une colonne hors périmètre autorisé est incluse dans le même `UPDATE`** (`protect_conversation_columns`, refus par défaut) |
| Contraintes métier | Le client ne peut jamais toucher aux colonnes `salon_*` et inversement (Catégories C/D, DEC-013) |
| RLS impliquée | `conversations_client_update_own_state`, `conversations_staff_update_own_state` (DEC-022), `conversations_owner_manager_update_own_state` (DEC-023) |
| Triggers exécutés | `trg_protect_conversation_columns` (colonne-par-colonne), `conversations_updated_at` |
| Événements Realtime | `UPDATE` sur `conversations`, RLS des événements déjà couverte par la même policy que le `SELECT` |
| Tests obligatoires | Déjà couverts par Migration 1.5 (`T-cat-C-pos`, `T-cat-D-neg`, `T-dec023-pos/neg`) — ce lot (2.1) ne fait que consommer, pas re-tester le backend |
| Flutter Repository attendu | `ConversationRepository.updateState(conversationId, {pinned?, archived?, hidden?}) → Future<void>` — **n'envoyer que les colonnes du côté de l'appelant**, jamais un objet fusionné qui inclurait par erreur une colonne `salon_*`/`client_*` de l'autre côté |

### 1.4 `toggleConversationBlock` — **PLANNED (Lot 2.5)**

| Champ | Valeur |
|---|---|
| Responsabilité | Bloquer/débloquer une conversation — autorité **actuelle**, jamais figée (DEC-015 §B.3) |
| Edge Function | `toggle-conversation-block` (service_role) |
| Paramètres | `conversationId: uuid`, `action: 'block' | 'unblock'` |
| Réponse | `{ blocked: bool, blocked_by: uuid|null, blocked_at: timestamptz|null }` |
| Erreurs | `403 not_current_authority` (ex-manager qui a bloqué puis quitté — ne peut plus débloquer, un manager/owner **actuel** le peut), `403 client_only_can_unblock_own` (si `blocked_by = client_id`, seul ce client peut lever), `404 conversation_not_found` |
| Contraintes métier | `salon_id`/`staff_id`/`client_id` lus depuis la ligne ciblée par la fonction, **jamais** depuis un paramètre fourni par l'appelant (§D.6 — anti cross-salon) |
| RLS impliquée | Aucune — colonnes en Catégorie E, `service_role` uniquement (DEC-013/015), jamais un `UPDATE` authenticated direct |
| Triggers exécutés | `trg_protect_conversation_columns` (catégorie E, `is_system` laisse passer) |
| Événements Realtime | `UPDATE` sur `conversations` (`blocked_by`/`blocked_at`), visible uniquement aux parties réelles |
| Tests obligatoires | Autorité actuelle (rotation manager — ADR §B.1 scénarios 1-3), cross-salon rejeté, asymétrie (salon ne peut jamais lever un blocage client), `activity_logs` écrit (DEC-015 §C) |
| Flutter Repository attendu | `ConversationRepository.toggleBlock(conversationId, action) → Future<BlockState>` ; UI ne propose **jamais** l'option de débloquer côté salon si `blocked_by = client_id` (asymétrie déjà actée) |

---

## 2. Messages

### 2.1 `sendMessage` — **SHIPPED (RLS) / DÉCISION REQUISE (orchestration)**

| Champ | Valeur |
|---|---|
| Responsabilité | Envoyer un message dans une conversation existante |
| Accès | **DÉCISION REQUISE (Lot 1.2)** : `INSERT` direct client sous RLS (chemin déjà prouvé, 36 tests Migration 2) OU Edge Function `send-message` orchestrée. Tant que non tranché, le chemin RLS direct est le seul **SHIPPED**. |
| Paramètres | `conversationId: uuid`, `clientMessageId: uuid` (généré Flutter, `uuid` package déjà dépendance du projet), `kind: 'text'|'image'|'gif'|'promotion'|'booking_confirmation'`, `body?: string`, `attachment?: jsonb` |
| Réponse | Ligne `messages` créée (14 colonnes) |
| Erreurs | `42501` (RLS — non participant, booking annulé/DEC-016, salon soft-supprimé/décision 3, conversation bloquée), `23505` (`uq_message_client_dedup` — renvoi idempotent, **traiter comme succès côté Flutter, pas comme erreur**, c'est le mécanisme de dédup offline voulu) |
| Contraintes métier | `client_staff` : `bookings.status NOT IN ('cancelled','no_show')` revérifié à **chaque envoi** (DEC-016, pas seulement à l'ouverture) ; `client_salon` : `salons.deleted_at IS NULL` revérifié à chaque envoi (décision 3, symétrique) ; `blocked_by IS NULL` obligatoire |
| RLS impliquée | `messages_participant_insert` |
| Triggers exécutés | `trg_bump_conversation_on_message` (AFTER INSERT, DEC-014 — met à jour `last_message_at`/`last_message_preview`/`*_unread_count`/`*_hidden_at` sur `conversations`) |
| Événements Realtime | `INSERT` sur `messages`, RLS événement = `messages_participant_select` |
| Tests obligatoires | Déjà couverts Migration 2 (36 tests) pour le chemin RLS ; si Edge Function retenue, ajouter positif/négatif/dédup au niveau de la fonction elle-même |
| Flutter Repository attendu | `MessageRepository.send({conversationId, clientMessageId, kind, body?, attachment?}) → Future<Message>` — **l'écho optimiste (`is_local=true`) est géré côté Hive/cache, jamais une colonne serveur** (ADR Partie B.1) ; sur `23505`, résoudre en relisant la ligne serveur existante, ne jamais afficher une erreur utilisateur |

### 2.2 `listMessages` (pagination) — **SHIPPED**

| Champ | Valeur |
|---|---|
| Responsabilité | Lire l'historique d'une conversation, borné |
| Accès | RLS directe, `SELECT` sur `public.messages` |
| Paramètres | `conversationId: uuid`, `before?: timestamptz` (curseur), `limit: int` (défaut recommandé 50-100, à confirmer Lot 1.3 — distinct du cap Realtime de 200, ADR-0004, qui borne le *stream*, pas la pagination historique) |
| Réponse | Liste de messages, triée `created_at DESC` |
| Erreurs | Aucune — RLS filtre silencieusement |
| Contraintes métier | `WHERE deleted_at IS NULL` pour l'affichage par défaut (index `idx_messages_conversation` déjà scopé ainsi) ; un message supprimé reste en base (soft-delete, DEC-010) mais ne doit pas s'afficher dans le fil standard |
| RLS impliquée | `messages_participant_select` (owner/manager ont une supervision en lecture non gatée par `type` — voir commentaire protecteur sur la policy elle-même) |
| Triggers exécutés | Aucun (lecture) |
| Événements Realtime | N/A (pagination = requête ponctuelle, pas un stream) |
| Tests obligatoires | Borne respectée, curseur correct, `deleted_at` filtré, `EXPLAIN` capturé (monitoring précoce Lot 1.3) |
| Flutter Repository attendu | `MessageRepository.fetchPage(conversationId, {before}) → Future<List<Message>>` |

### 2.3 `markMessageRead` — **SHIPPED**

| Champ | Valeur |
|---|---|
| Responsabilité | Marquer un message comme lu par son destinataire (non-expéditeur) |
| Accès | RLS directe, `UPDATE public.messages SET status='read'` |
| Paramètres | `messageId: uuid` |
| Réponse | Ligne mise à jour (`status='read'`, `read_at` fixé **serveur**, jamais la valeur envoyée par le client) |
| Erreurs | `0 rows affected` (pas d'erreur SQL) si l'appelant est l'expéditeur, ou n'est pas participant, ou (côté `client_staff`) est owner/manager (supervision lecture seule — l'écriture reste staff-only sur ce type) |
| Contraintes métier | `read_at` gelé côté client par `protect_message_columns`, avancé uniquement par la fonction elle-même |
| RLS impliquée | `messages_recipient_mark_read` |
| Triggers exécutés | `trg_protect_message_columns` (force `read_at`), `trg_reset_unread_on_read` (décrémente le compteur sur `conversations`), `messages_updated_at` |
| Événements Realtime | `UPDATE` sur `messages` (`status`, `read_at`) |
| Tests obligatoires | Déjà couverts Migration 2 — non-régression à rejouer si ce chemin est retouché par un lot ultérieur |
| Flutter Repository attendu | `MessageRepository.markRead(messageId) → Future<void>` — **vérifier `rowCount`/l'absence d'exception ne suffit pas** à confirmer le succès côté RLS `UPDATE` ; traiter "0 ligne affectée" comme un no-op silencieux, pas une erreur affichée |

### 2.4 `editMessage` — **PLANNED (Lot 2.4), DÉCISION REQUISE (fenêtre)**

| Champ | Valeur |
|---|---|
| Responsabilité | Modifier le contenu d'un message déjà envoyé |
| Accès | À trancher (RLS directe probable, mirroring `messages_sender_soft_delete`) |
| Paramètres | `messageId: uuid`, `body: string` |
| Réponse | Ligne mise à jour, `edited_at` renseigné |
| Erreurs | `P0001` si hors fenêtre d'édition (**DÉCISION REQUISE**), `42501`/`0 rows` si non-auteur |
| Contraintes métier | Fenêtre d'édition — **non tranchée** (illimitée / N minutes / aucune limite avec badge visuel) |
| RLS impliquée | Nouvelle policy à écrire (Lot 2.4), mirroring `messages_sender_soft_delete` |
| Triggers exécutés | `protect_message_columns` **révisée** (nouvelle catégorie positive pour `body`/`edited_at`, bornée par la fenêtre si celle-ci est exprimable en SQL, sinon vérifiée côté Edge Function) |
| Événements Realtime | `UPDATE` sur `messages` |
| Tests obligatoires | Positif (dans la fenêtre), négatif (hors fenêtre), négatif (non-auteur), **rejeu intégral des tests Migration 2** (non-régression `protect_message_columns`) |
| Flutter Repository attendu | `MessageRepository.edit(messageId, body) → Future<Message>` — afficher un badge "modifié" si `edited_at != null` |

### 2.5 `deleteMessage` — **SHIPPED**

| Champ | Valeur |
|---|---|
| Responsabilité | Suppression logique d'un message par son auteur ("delete for everyone" — décision 1, un seul `deleted_at`) |
| Accès | RLS directe, `UPDATE public.messages SET deleted_at = NOW()` |
| Paramètres | `messageId: uuid` |
| Réponse | Ligne mise à jour |
| Erreurs | `0 rows affected` si non-auteur |
| Contraintes métier | Auteur uniquement ; pas de "delete for me" par message (distinct de `conversations`, qui a un modèle par-partie — décision 1 documentée dans la migration) |
| RLS impliquée | `messages_sender_soft_delete` |
| Triggers exécutés | `trg_protect_message_columns` (catégorie D), `messages_updated_at` |
| Événements Realtime | `UPDATE` sur `messages` (`deleted_at`) — le fil doit retirer le message de l'affichage sur réception de cet événement, pas seulement au prochain fetch |
| Tests obligatoires | Déjà couverts Migration 2 |
| Flutter Repository attendu | `MessageRepository.delete(messageId) → Future<void>` |

---

## 3. Reports (Modération) — **Domaine PLANNED en entier (Phase 4)**

### 3.1 `reportMessage` — **PLANNED**

| Champ | Valeur |
|---|---|
| Responsabilité | Signaler un message |
| Edge Function | `report-message` (nouvelle) |
| Paramètres | `messageId: uuid`, `reason: string` |
| Réponse | `{ report_id: uuid }` |
| Erreurs | `409 already_reported` (**DÉCISION REQUISE** — UNIQUE anti-doublon `(message_id, reporter_id)` absente du brouillon actuel), `429 rate_limited` (réutilisation `checkRateLimit`, ADR-0001) |
| Contraintes métier | Aucune modération automatique par IA (contrainte explicite, cahier des charges) — confirmation humaine uniquement côté UI |
| RLS impliquée | `message_reports_own_insert` (brouillon existant, `docs/KYNZA_MESSAGING_ARCHITECTURE.md:564-565`) |
| Triggers exécutés | `flag_message_on_report` — **conflit connu, à résoudre avant d'écrire** (Lot 4.1) : cet `UPDATE messages SET is_flagged=true` imbriqué sera rejeté par `protect_message_columns` (catégorie system-only, aucune exception `nested`) sauf `SECURITY DEFINER` sur ce trigger (mirroring DEC-014) ou extension de la garde |
| Événements Realtime | Aucun prévu à ce jour (pas de stream sur `message_reports`) |
| Tests obligatoires | Positif, doublon rejeté (une fois la décision UNIQUE prise), rate-limit déclenché, `is_flagged` mis à jour sans régression `protect_message_columns` |
| Flutter Repository attendu | `ReportRepository.report(messageId, reason) → Future<void>` — écran de confirmation, jamais de détection automatique |

### 3.2 `resolveReport` — **PLANNED, DÉCISION REQUISE**

| Champ | Valeur |
|---|---|
| Responsabilité | Marquer un signalement comme traité |
| Accès | À trancher — le brouillon actuel (`message_reports_owner_manager_manage`, `FOR ALL`) pose un conflit d'intérêt (le salon gère les signalements visant son propre staff, sans escalade `is_system_admin` alors que cette colonne existe déjà) |
| Paramètres | `reportId: uuid`, `resolution: string` |
| Réponse | `{ resolved_at: timestamptz, resolved_by: uuid }` |
| Erreurs | Selon la policy finalement retenue |
| Contraintes métier | Traçabilité `activity_logs` requise (cohérence avec DEC-015 §C, absente du brouillon actuel) |
| RLS impliquée | À réviser (Lot 4.1) |
| Triggers exécutés | Aucun prévu, sauf si `activity_logs` est écrit par trigger plutôt que par la fonction |
| Événements Realtime | Aucun |
| Tests obligatoires | Autorité correcte selon la décision retenue, `activity_logs` peuplé |
| Flutter Repository attendu | `ReportRepository.resolve(reportId, resolution) → Future<void>` (écran owner/manager, hors périmètre client) |

---

## 4. Notifications — **Domaine partiellement SHIPPED, reste PLANNED (Phase 3)**

### 4.1 `registerDeviceToken` — **SHIPPED** (Phase 1b de l'architecture, antérieure à ce plan)

| Champ | Valeur |
|---|---|
| Responsabilité | Enregistrer/rafraîchir le token FCM de l'appareil courant |
| Edge Function/RPC | `upsert_device_token` (RPC, `SECURITY DEFINER`, `authenticated`) |
| Paramètres | `token: string`, `platform: 'android'|'ios'` |
| Réponse | Ligne `device_tokens` |
| Erreurs | Contrainte `uq_device_tokens_token` |
| Contraintes métier | Un token appartient à un seul utilisateur à la fois (ré-assigné au sign-in, révoqué au sign-out — déjà géré par `NotificationService`) |
| RLS impliquée | `device_tokens_own` |
| Triggers exécutés | Aucun |
| Événements Realtime | Aucun |
| Tests obligatoires | Déjà couverts (Phase 1b, mémoire `project_messaging_phase0_architecture`) |
| Flutter Repository attendu | Déjà implémenté — `NotificationService.saveFcmToken()`/`revokeDeviceToken()`, ne pas dupliquer |

### 4.2 `sendMessagePush` — **PLANNED (Lot 3.1)**

| Champ | Valeur |
|---|---|
| Responsabilité | Notifier le(s) destinataire(s) d'un nouveau message |
| Edge Function | Nouvelle, ou routage ajouté à `send-notification` existant — **DÉCISION REQUISE** (Lot 3.1) : déclenchement synchrone (si `sendMessage` est orchestrée par Edge Function) ou asynchrone (si `sendMessage` reste RLS directe) |
| Paramètres | `messageId: uuid` (la fonction relit `conversation_id`/`sender_id`/destinataires depuis la ligne réelle, jamais depuis des paramètres fournis par l'appelant) |
| Réponse | `{ dispatched: int }` (nombre de `device_tokens` ciblés) |
| Erreurs | Avalées et loguées par `_shared/fcm.ts` (comportement existant, fail-open côté notification — une notification manquée ne doit jamais bloquer l'envoi du message lui-même) |
| Contraintes métier | Catégorie 4 (D2) : le template/contenu de notification est propre à la messagerie, mais **jamais** stocké dans `messages`/`conversations` — reste dans `notification_templates`/`notification_logs` |
| RLS impliquée | Aucune (service_role) |
| Triggers exécutés | Aucun (appel Edge Function direct ou webhook, pas un trigger SQL synchrone sur `messages` — éviterait de coupler l'insertion du message à la disponibilité de FCM) |
| Événements Realtime | Aucun (le push est hors Postgres Changes) |
| Tests obligatoires | Notification réelle reçue sur device réel, idempotence si retry (Lot 3.5) |
| Flutter Repository attendu | Aucun — consommé côté OS (FCM), Flutter ne fait qu'afficher/router au tap (`DeepLinkHandler`) |

### 4.3 `muteConversation` — **PLANNED, DÉCISION REQUISE (schéma)**

| Champ | Valeur |
|---|---|
| Responsabilité | Suspendre les notifications d'une conversation précise sans la masquer de la liste |
| Accès | À concevoir — **aucune colonne n'existe aujourd'hui** ; distinct de `client_hidden_at` (qui masque de la liste, pas des notifications) |
| Paramètres | `conversationId: uuid`, `muted: bool` |
| Réponse | À définir selon le schéma retenu |
| Erreurs | À définir |
| Contraintes métier | Ne doit jamais affecter la visibilité dans la liste de conversations (domaine strictement séparé de pin/archive/hide) |
| RLS impliquée | À écrire (Lot 3.4) |
| Triggers exécutés | Le dispatch de `sendMessagePush` devra lire cet état avant d'émettre |
| Événements Realtime | Aucun a priori |
| Tests obligatoires | Notification effectivement supprimée si muet, conversation toujours visible en liste |
| Flutter Repository attendu | `ConversationRepository.mute(conversationId, muted) → Future<void>` |

---

## 5. Realtime

### 5.1 `streamMessages` — **SHIPPED (transport) / à borner explicitement côté Flutter**

| Champ | Valeur |
|---|---|
| Responsabilité | Flux temps réel des messages d'une conversation |
| Mécanisme | Supabase Postgres Changes, `supabase_realtime` contient `messages` (vérifié en production) |
| Paramètres client | `.stream(primaryKey: ['id']).eq('conversation_id', id).order('created_at', ascending: false).limit(200)` — **un seul `.eq()` supporté par `SupabaseStreamBuilder`** (limite SDK réelle, ADR-0004), ne jamais chaîner un second filtre |
| RLS événement | `messages_participant_select` (appliquée aux événements Postgres Changes, pas seulement au `SELECT` direct — à vérifier séparément, `T-realtime-softdelete-rls`) |
| Contraintes métier | Cap à 200 par défaut (ADR-0004) — réévaluer seulement si `supabase_flutter` gagne un filtre multi-colonnes |
| Tests obligatoires | `T-realtime-softdelete-rls` (Lot 1.4) — jamais exécuté à ce jour, priorité de Phase 1 |
| Flutter Repository attendu | `MessageRepository.watch(conversationId) → Stream<List<Message>>` |

### 5.2 `streamConversations` — **SHIPPED (transport)**

| Champ | Valeur |
|---|---|
| Responsabilité | Flux temps réel de la liste de conversations (badge, dernier message, réordonnancement) |
| Mécanisme | `supabase_realtime` contient `conversations` (vérifié) |
| Paramètres client | `.stream().eq('client_id', uid)` (ou filtre équivalent selon rôle) `.order('last_message_at', ascending: false).limit(200)` |
| RLS événement | `conversations_client_select`/`_staff_select`/`_owner_manager_select` |
| Tests obligatoires | Inclus dans le même scénario que 5.1 (cas bloqué, cas owner/manager autre salon) |
| Flutter Repository attendu | `ConversationRepository.watchAll()` (déjà listé en 1.2) |

### 5.3 `typingIndicator` — **NON SPÉCIFIÉ**

| Champ | Valeur |
|---|---|
| Statut | Aucune décision prise par l'ADR (§Phase 3 de l'ancienne feuille de route : "Realtime Broadcast, pas Postgres Changes — aucune colonne DB dédiée, état éphémère") — mécanisme correct (Broadcast) déjà nommé, jamais implémenté ni testé |
| À faire avant implémentation | Spécifier le canal Broadcast, le format du payload, le TTL d'expiration côté client |

### 5.4 `presence` — **NON SPÉCIFIÉ**

| Champ | Valeur |
|---|---|
| Statut | Même remarque — Realtime Presence nommé par l'ADR, jamais spécifié ni implémenté |
| À faire avant implémentation | Spécifier la granularité (par conversation ou globale), le comportement multi-device |

---

## Rappel de gouvernance sur ce document

Ce contrat est mis à jour **dans le même commit** que tout changement qui le rend caduc (nouvelle
Edge Function, nouvelle policy, changement de statut PLANNED→SHIPPED) — même discipline que
`docs/ADR_MESSAGING_FOUNDATION.md`. Une ligne marquée "DÉCISION REQUISE" ne devient "PLANNED" utilisable
qu'après que la décision a été prise et documentée ici même.
