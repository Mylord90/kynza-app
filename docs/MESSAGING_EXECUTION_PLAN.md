# KYNZA Messaging — Plan d'exécution (lots)

**Rattachement** : ce document découpe chaque phase de `docs/MESSAGING_ROADMAP.md` en **lots**
(Mission 2) — chaque lot représente une fonctionnalité cohérente unique, jamais un mélange de
domaines. Un lot se ferme intégralement (migration + tests + rollback + Flutter + doc) avant que le
suivant ne démarre, selon le cycle Rule 8 complet. Aucune décision `DEC-XXX` n'est prise ici — les
lots qui touchent un point non tranché par l'ADR le signalent explicitement comme "décision requise
en ouverture de lot", jamais résolu par supposition.

**Convention de lecture** : `Piste` indique si le lot est Backend (migration/Edge Function/RLS),
Flutter (consomme un contrat déjà gelé), ou les deux en séquence stricte (Backend puis Flutter,
jamais en parallèle — principe de découplage, `MESSAGING_ROADMAP.md`).

---

## Monitoring précoce (Mission 4)

Le monitoring ne doit **plus** attendre Phase 5. Ce qui doit être instrumenté **dès le Lot 1.1**
(premier Edge Function écrit) :

| Quoi mesurer | Où | Pourquoi | Comment le prouver |
|---|---|---|---|
| Latence Edge Functions | Logs Supabase (`console.time`/timestamp début-fin dans chaque fonction, comme convention déjà utilisée ailleurs dans ce dépôt — à vérifier/réutiliser, pas réinventer) | Une régression de latence sur `send-message` est invisible sans mesure dès le premier appel réel — attendre Phase 5 la rendrait indiscernable d'une latence "normale" faute de baseline | Dashboard/logs montrant une distribution de latence réelle dès les premiers appels de test, pas une estimation |
| Temps SQL (requêtes RLS + triggers) | `EXPLAIN ANALYZE` ponctuel sur les policies `messages_participant_*` dès leur premier usage réel en Lot 1.3 (pagination) — pas l'audit de charge complet de Phase 5, juste une mesure de référence | Une policy RLS avec sous-requête (`staff_id IN (...)`) peut coûter cher selon le plan choisi par Postgres — vérifier tôt que l'index existant (`idx_messages_conversation`) est bien utilisé, pas après coup | Plan `EXPLAIN` capturé et archivé dès Lot 1.3, comparé en Phase 5 pour détecter une dérive |
| Erreurs (Edge Functions) | `console.error` systématique sur tout chemin d'échec, dès Lot 1.1 — même convention que `checkRateLimit()` (`_shared/rate_limit.ts:29`, déjà le patron du dépôt pour un échec silencieux corrigé) | Un échec silencieux en Edge Function est le bug de classe la plus coûteuse à découvrir tard (précédent réel déjà vécu sur ce projet, `_shared/fcm.ts`) | Logs Supabase contiennent une entrée pour chaque échec simulé en test négatif |
| Realtime (latence, déconnexions) | Capture du délai entre `INSERT` et réception websocket lors de `T-realtime-softdelete-rls` (Lot 1.4) | C'est le seul moment du projet où un abonnement réel est de toute façon ouvert pour le test de sécurité — mesurer la latence au même moment ne coûte rien de plus et évite un test dédié plus tard | Delta timestamp `created_at` → réception client, capturé dans le même test que la preuve RLS |
| FCM (délivrance) | Dès Lot 3.1 (premier envoi push réel) — **hérite de la limite déjà connue** : `_shared/fcm.ts` ne lit pas la réponse FCM, donc "délivré" ne peut être mesuré qu'au niveau "l'appel HTTP n'a pas échoué", pas "l'utilisateur a reçu la notification" tant que ce ticket n'est pas fermé séparément | Sans cette mesure dès Lot 3.1, la Phase 3 se déclarerait "GO" sur la base d'un signal qui ne prouve pas ce qu'il prétend prouver | `notification_logs` peuplé + tentative réelle sur au moins un appareil physique, avec la limite documentée explicitement dans le rapport de clôture du lot |
| Compteurs (`*_unread_count`) | Requête directe post-test dès Lot 1.2 (déjà fait pour Migration 2, à reconduire à chaque lot qui insère des messages) | Un compteur qui dérive silencieusement (double incrément, oubli de décrément) est un bug de confiance utilisateur (badge faux) — moins grave qu'une fuite de sécurité mais très visible | `SELECT client_unread_count/salon_unread_count` avant/après, comparé à l'attendu exact |
| Retry (Outbox, Edge Functions) | Dès que le premier mécanisme de retry existe (Lot 3.5 pour push, Lot 6.3 pour l'outbox offline) | Un retry mal dimensionné peut dupliquer une action (message envoyé 2×, notification 2×) — l'idempotence (`client_message_id`, ou équivalent pour le push) doit être vérifiée dès l'introduction du retry, pas après un incident réel | Test explicite : déclencher un retry et vérifier qu'aucun doublon n'apparaît côté effet observable (message, notification) |
| Logs (traçabilité) | `activity_logs` dès le premier lot qui l'écrit (Lot 2.5 blocage, Lot 4.4 audit signalement) | Déjà la convention du projet (DEC-015 §C) — vérifier tôt que le format est cohérent avec les autres écritures `activity_logs` existantes (mêmes colonnes, même style de `type_action`) | Ligne réelle insérée, relue, comparée au format des écritures `activity_logs` déjà en production ailleurs dans le dépôt |

**Principe** : chaque item ci-dessus se prouve **au moment où le mécanisme qu'il mesure existe pour
la première fois**, jamais différé à une phase de monitoring dédiée qui n'existerait qu'à la fin.

---

## Phase 1 — Backend Core

| Lot | Objectif | Piste | Dépend de | Décision requise en ouverture | Tests | Rollback |
|---|---|---|---|---|---|---|
| 1.0 | Sync documentaire — `MESSAGING_TRACEABILITY_MATRIX.md`/`MESSAGING_FOUNDATION_CHECKLIST.md` mis à jour pour refléter Migration 2 (déjà shipped, jamais synchronisé) | Doc uniquement | — | Aucune (housekeeping pur, zéro décision) | — | N/A |
| 1.1 | `create-conversation` (Edge Function, éligibilité anti-spam) | Backend | Migration 1/1.5 | Règle d'éligibilité exacte (quel statut de booking, quelle fenêtre) — l'ADR ne fixe que le principe | Positif (historique valide), négatif (aucun historique), cross-salon rejeté | Suppression de fonction |
| 1.2 | Envoi de message — **décision de fond** : Edge Function orchestrée ou INSERT direct client sous RLS ? Sans push (Phase 3 le prend en charge séparément — Mission 5) | Backend | Migration 2 (RLS déjà prouvée) | Oui — engage durablement le contrat Flutter, voir `MESSAGING_ROADMAP.md` Phase 1 risques | Positif/négatif/dédup `client_message_id` déjà couverts par les tests Migration 2 — ce lot teste seulement la couche d'appel choisie (Edge Function ou repository RLS direct) | Suppression de fonction si Edge Function ; sinon N/A |
| 1.3 | Lecture paginée (`.order(created_at desc).limit(N)`, ADR-0004) | Backend puis Flutter (contrat) | 1.2 | Valeur de `N` par défaut (200, cohérent ADR-0004, à confirmer pour ce domaine spécifiquement) | Curseur respecté, borne respectée, `EXPLAIN` capturé (monitoring précoce) | N/A (lecture seule) |
| 1.4 | Realtime — abonnement + `T-realtime-softdelete-rls` réel (jamais exécuté à ce jour malgré 2 migrations livrées) | Backend | 1.2, 1.3 | Aucune — c'est l'exécution d'un test déjà entièrement spécifié (DoD, section Realtime) | Scénario complet déjà écrit dans `MESSAGING_DEFINITION_OF_DONE.md:81-113` (positif C, négatif tiers, cas bloqué, cas owner/manager autre salon) | N/A |
| 1.5 | Monitoring minimal (voir section dédiée ci-dessus) | Backend | 1.1-1.4 | Aucune | Chaque item du tableau "Monitoring précoce" prouvé | N/A |
| 1.6 | Contrat Flutter (domain/data/providers, zéro écran) | Flutter | 1.1-1.5 gelés | Aucune | `flutter analyze` = 0 | Revert Flutter uniquement |

## Phase 2 — Conversation Experience

| Lot | Objectif | Piste | Dépend de | Décision requise | Tests | Rollback |
|---|---|---|---|---|---|---|
| 2.1 | Archive/Pin/Hide — **backend déjà livré** (Migration 1/1.5), ce lot = Flutter seulement | Flutter | Phase 1 | Aucune | Widget/UI, non-régression RLS déjà couverte par Migration 1.5 | Revert Flutter |
| 2.2 | Compteurs/Badge — **backend déjà livré** (DEC-014), ce lot = Flutter seulement | Flutter | Phase 1 | Aucune | Agrégat `SUM` correct à l'écran, pas de nouveau système de comptage (anti-inflation déjà actée) | Revert Flutter |
| 2.3 | Suppression — **backend déjà livré** (`messages_sender_soft_delete`), ce lot = vérification bout-en-bout + Flutter | Flutter (vérif Backend) | Phase 1 | Aucune | Rejeu des tests Migration 2 pertinents (auteur seul peut supprimer), UI de confirmation | Revert Flutter |
| 2.4 | Édition — migration additive (`edited_at`/`is_edited`) + révision `protect_message_columns` | Backend puis Flutter | 2.3 | Oui — fenêtre d'édition (illimitée / N minutes / aucune limite avec badge "modifié") | **Rejeu complet des tests Migration 2** (non-régression `protect_message_columns`) + nouveaux tests édition positif/négatif/hors-fenêtre | UP→DOWN testé comme Migration 2, `DROP COLUMN` + retour fonction version Migration 2 |
| 2.5 | Blocage — `toggle-conversation-block` (spec déjà écrite ADR §B/§C/§D.6) | Backend puis Flutter | Phase 1 | Aucune décision de conception (déjà tranchée) — seulement l'implémentation | Autorité actuelle (rotation manager), cross-salon rejeté, `activity_logs` écrit, UX asymétrique (le salon ne voit jamais l'option de débloquer un blocage client) | Suppression de fonction, colonnes déjà protégées inchangées |

## Phase 3 — Notifications

| Lot | Objectif | Piste | Dépend de | Décision requise | Tests | Rollback |
|---|---|---|---|---|---|---|
| 3.1 | Push au send — réutilise `_shared/fcm.ts`/`device_tokens` (déjà en production) | Backend | Phase 1 | Architecture de déclenchement : appel synchrone depuis l'Edge Function d'envoi (si Lot 1.2 a retenu ce chemin), ou déclenchement asynchrone (trigger/webhook) si l'insertion reste RLS directe | Notification réelle reçue sur device réel, idempotence si retry | Retrait du routage sans toucher `notification_*` (D2 garantit l'isolation) |
| 3.2 | Badge système (au-delà du badge in-app de Lot 2.2, si distinct) | Flutter | 3.1 | À confirmer si un badge OS distinct est réellement requis ou si le badge in-app suffit | Badge cohérent avec `SUM(*_unread_count)` | Revert Flutter |
| 3.3 | Deep link vers la conversation | Backend (payload) puis Flutter | 3.1, précédent `DeepLinkHandler` | Aucune — réutilisation directe d'un mécanisme existant | Tap sur notification ouvre la bonne conversation, cold-start et background | Revert payload + Flutter |
| 3.4 | Mute par conversation | Backend (nouveau schéma) puis Flutter | Phase 1 | **Oui — aucune colonne/mécanisme n'existe aujourd'hui.** Distinct de `client_hidden_at`/`archived` (qui affectent la liste, pas la notification). À trancher : nouvelle colonne sur `conversations` ou table séparée type `conversation_mutes` | Notification effectivement supprimée quand muet, conversation toujours visible dans la liste | Selon le schéma retenu, testé UP→DOWN |
| 3.5 | Retry + accusés délivrance/lecture (push) | Backend | 3.1 | Dimensionnement du retry (nombre de tentatives, backoff) — à spécifier, aucun précédent dans ce domaine précis | Idempotence sous retry (pas de double notification), délivrance mesurée avec la limite déjà connue de `_shared/fcm.ts` documentée explicitement | Retrait du mécanisme de retry, fallback sur l'envoi simple existant |

## Phase 4 — Sécurité & Modération

| Lot | Objectif | Piste | Dépend de | Décision requise | Tests | Rollback |
|---|---|---|---|---|---|---|
| 4.1 | Trancher les 5 points `message_reports` (conflit `protect_message_columns`, UNIQUE anti-doublon, conflit d'intérêt `FOR ALL`, traçabilité `activity_logs`, DEC-XXX à assigner) | Décision (pas de code) | Phase 1 | Oui — les 5, avant toute ligne SQL | — | — |
| 4.2 | Migration 3 (`message_reports`) + Edge Function `report-message` | Backend | 4.1 tranché | Non (déjà tranché en 4.1) | Positif, doublon rejeté, cross-salon rejeté, `is_flagged` mis à jour sans casser `protect_message_columns` (non-régression Migration 2) | UP→DOWN testé, table neuve sans dépendant |
| 4.3 | Rate limiting — **réutilise `checkRateLimit()`/`check_rate_limit()` déjà en production (ADR-0001), pas un nouveau mécanisme** | Backend | 4.2 | Clé de limitation (`send-message:<uid>`, `report-message:<uid>`) et seuils (`max`/`windowSeconds`) — à choisir, pas de valeur par défaut du domaine messagerie aujourd'hui | Seuil déclenché réellement, comportement fail-open vérifié cohérent avec ADR-0001 (pas une régression vers fail-closed) | Retrait de l'appel `checkRateLimit`, aucun impact sur les 15 autres Edge Functions qui l'utilisent déjà |
| 4.4 | Audit — `activity_logs` à la résolution d'un signalement | Backend | 4.2 | Aucune — même mécanisme que DEC-015 §C, à reproduire à l'identique | Ligne réelle vérifiée après résolution | N/A (écriture additive) |
| 4.5 | Revue de sécurité rejouée (ADR §D) contre l'implémentation réelle de Phase 1-4 | Revue | 4.1-4.4 | Aucune | Checklist ADR §D item par item | N/A |

## Phase 5 — Optimisation & Production

| Lot | Objectif | Piste | Dépend de | Décision requise | Tests | Rollback |
|---|---|---|---|---|---|---|
| 5.1 | `EXPLAIN ANALYZE` + revue d'index sur trafic réel accumulé | Backend | Phases 1-4 | Aucune — mesure, pas de décision a priori (voir note ADR-0003 dans `MESSAGING_ROADMAP.md`) | Plans de requête capturés, comparés aux plans de Lot 1.3 | `DROP INDEX` si un index est ajouté |
| 5.2 | Monitoring avancé (au-delà du minimal Phase 1) | Backend/Infra | 5.1 | Choix d'outil de dashboard si pas déjà standard sur ce projet — à vérifier avant de choisir | Alertes réellement déclenchées en conditions de test | Désactivation d'alerte |
| 5.3 | Documentation finale + fermeture DoD | Doc | 5.1, 5.2 | Aucune | Checklist "Prêt pour la production" cochée en entier | N/A |

## Phase 6 — Offline & Synchronisation

| Lot | Objectif | Piste | Dépend de | Décision requise | Tests | Rollback |
|---|---|---|---|---|---|---|
| 6.1 | Cache Hive (lecture offline du fil déjà consulté) | Flutter | Phase 1 | Aucune | Lecture offline réelle après coupure réseau | Revert Flutter |
| 6.2 | Extension `MutationOutboxService` (type `messageSend`) | Flutter | 6.1 | Champ de backoff — l'ADR notait son absence à l'époque de Migration 2 ; vérifier s'il a été ajouté entre-temps avant de le recréer | Insertion en file en mode avion | Revert Flutter |
| 6.3 | Retry + reconnexion (réseau ET Realtime) | Flutter | 6.2 | Dimensionnement du retry (cohérence avec Lot 3.5 si le même pattern est réutilisable) | Coupure réelle simulée, reprise du stream Realtime | Revert Flutter |
| 6.4 | Réconciliation par `client_message_id` + `T-local-01` | Flutter | 6.2, 6.3 | Aucune — mécanisme déjà retenu (ADR Partie B.1), jamais par contenu/timestamp | `T-local-01` (ADR §B.1) exécuté réellement, zéro doublon visuel | Revert Flutter |

---

## Rappel — aucun lot ne commence avant que le précédent (même phase) soit fermé

Fermeture = migration poussée (si applicable) + tests réels + rollback vérifié + Flutter contract
consommé + `MESSAGING_API_CONTRACT.md`/`MESSAGING_TRACEABILITY_MATRIX.md`/
`MESSAGING_FOUNDATION_CHECKLIST.md` mis à jour + commit unique. C'est la même discipline que
Migration 2, appliquée à un grain plus fin.
