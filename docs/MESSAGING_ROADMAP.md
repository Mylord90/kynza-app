# KYNZA Messaging — Roadmap de livraison (post-fondation)

**Statut** : référence officielle à partir du 2026-07-23. **Remplace** la section "Feuille de route à
5 phases" de `docs/ADR_MESSAGING_FOUNDATION.md` (celle-ci reste dans l'ADR pour l'historique — elle
est marquée `SUPERSEDED BY docs/MESSAGING_ROADMAP.md` dans ce même commit, jamais supprimée).

**Ce que ce document est** : la liste des phases de livraison produit, leurs dépendances, leur
périmètre, leurs risques et leurs critères de passage. **Ce que ce document n'est pas** : une
nouvelle revue d'architecture. Aucune décision `DEC-001` à `DEC-023` n'est modifiée ici — ce document
organise l'**exécution** de ce qui est déjà verrouillé, il ne redéfinit rien.

**Rattachement** :
- Décisions normatives → `docs/ADR_MESSAGING_FOUNDATION.md` (inchangé, toujours la seule source pour
  un `DEC-XXX`).
- Découpage fin en lots testables → `docs/MESSAGING_EXECUTION_PLAN.md`.
- Contrat Backend ↔ Flutter → `docs/MESSAGING_API_CONTRACT.md`.
- Checklist d'avancement → `docs/MESSAGING_FOUNDATION_CHECKLIST.md`.
- Preuve par décision → `docs/MESSAGING_TRACEABILITY_MATRIX.md`.
- Critères de qualité par artefact → `docs/MESSAGING_DEFINITION_OF_DONE.md`.

---

## Principe de découplage (Mission 1 — comment lire chaque phase)

Chaque phase ci-dessous a **deux pistes séquentielles**, jamais entrelacées jour par jour :

1. **Piste Backend** — migrations SQL (indépendantes les unes des autres, une migration = un
   domaine cohérent, jamais un mélange de tables/décisions sans rapport), Edge Functions (regroupées
   par domaine métier : Conversation / Messages / Reports / Blocage / Notifications), RLS, triggers,
   tests SQL/Edge réels, rollback vérifié. **Se termine par un gel du contrat** :
   `docs/MESSAGING_API_CONTRACT.md` est mis à jour et considéré stable pour cette phase.
2. **Piste Flutter** — ne démarre **qu'après** le gel du contrat de la piste Backend de la même
   phase. Consomme uniquement `MESSAGING_API_CONTRACT.md`, jamais les fichiers de migration
   directement (c'est le critère de réussite de ce document : un développeur Flutter ne devrait
   jamais avoir besoin d'ouvrir `supabase/migrations/`).

Ce n'est pas un déplacement de Flutter vers une phase séparée à la fin du projet — chaque phase
livre encore du Flutter utilisable. C'est un ordonnancement strict à l'intérieur de chaque phase :
jamais de code Flutter écrit contre un contrat encore mouvant.

## Pourquoi une phase Notifications séparée (Mission 5 — justification)

Le squelette de phases initial regroupait les notifications sous "Sécurité & Modération" (à cause du
signalement, qui déclenche une notification). Ceci est corrigé ici : les notifications ne sont **pas**
un sous-produit de la sécurité, ce sont un domaine transversal à part entière (FCM, badge, deep
links, mute, retry, accusés de livraison/lecture) qui touche **toutes** les autres phases (un message
envoyé en Phase 1 notifie déjà ; un signalement en Phase 4 notifie aussi). Les mélanger à la sécurité
aurait reproduit exactement l'anti-pattern déjà documenté pour la catégorie 4 (D2 — notifications
système restent dans `notification_*`, jamais dans les tables de messagerie) : un domaine avec sa
propre table (`device_tokens`), son propre mécanisme (`_shared/fcm.ts`, déjà en production), et son
propre cycle de vie ne doit pas être absorbé par le domaine qui le déclenche. **Conséquence sur la
numérotation** : la phase "Notifications" est insérée entre "Conversation Experience" et "Sécurité &
Modération" dans le squelette fourni — elle porte le numéro 3, et les phases suivantes sont décalées
d'un rang. Le contenu de chaque phase reste identique à ce qui a été demandé ; seule la numérotation
absorbe l'insertion.

---

## Vue d'ensemble des 6 phases

| # | Phase | Contenu | Dépend de |
|---|---|---|---|
| 1 | Backend Core | Edge Functions fondatrices, API, Realtime transport, monitoring minimal | Migrations 1/1.5/2 (déjà en production) |
| 2 | Conversation Experience | Archive, pin, hide, compteurs, édition, suppression, blocage | Phase 1 (contrat gelé) |
| 3 | Notifications | FCM, push, badge, deep links, notifications silencieuses, mute, retry, delivery, read | Phase 1 (messages existent) ; réutilise `device_tokens`/`_shared/fcm.ts` déjà en production |
| 4 | Sécurité & Modération | `message_reports`, anti-spam, rate limiting, audit | Phase 1 (messages existent), Phase 3 (le signalement notifie) |
| 5 | Optimisation & Production | Monitoring avancé, observabilité, index, charge, documentation finale | Phases 1-4 livrées (mesurer un système qui existe, pas un système hypothétique) |
| 6 | Offline & Synchronisation | Hive, Outbox, retry, reconnexion, cache, réconciliation | Phase 1 (contrat serveur stable — l'outbox réconcilie contre un protocole figé) |

**Note d'ordonnancement, assumée explicitement, pas déduite** : Offline (6) est volontairement
positionné après Optimisation (5), pas avant — choix produit confirmé par vous dans la demande de
réorganisation. Techniquement, rien n'empêcherait Offline de suivre directement la Phase 1 (le
contrat `client_message_id`/dedup existe déjà) ; l'ordre retenu ici reflète une priorité produit
(stabiliser et mesurer le système connecté avant d'investir dans le mode déconnecté), pas une
dépendance technique bloquante.

---

## Phase 1 — Backend Core

**Objectif** : exposer un backend de messagerie utilisable de bout en bout (créer une conversation,
envoyer/lire/paginer des messages, accusé de lecture minimal, flux temps réel) pour que le
développement des écrans Flutter de conversation puisse commencer.

**Périmètre** :
- Edge Functions `create-conversation`, `send-message` (ou RLS directe — décision à prendre en
  premier, voir `MESSAGING_EXECUTION_PLAN.md`).
- Contrat de lecture paginée (`MESSAGING_API_CONTRACT.md`).
- Abonnement Realtime sur `messages`/`conversations` (déjà en publication depuis Migration 2),
  bornage `.order().limit()` (ADR-0004) vérifié en conditions réelles (websocket, pas simulé) — en
  particulier `T-realtime-softdelete-rls`, jamais exécuté à ce jour.
- Monitoring minimal (voir "Monitoring Précoce" dans `MESSAGING_EXECUTION_PLAN.md`).

**Exclus** : édition, suppression avancée (au-delà du soft-delete déjà livré), archive/pin/hide côté
Flutter, blocage, signalement, offline, tout écran au-delà du contrat de lecture/envoi minimal.

**Dépendances** : Migrations 1/1.5/2 (production, `hhdkjfpgaklhrhfoxlhj`) — aucune nouvelle migration
requise a priori pour cette phase, sauf si la décision `send-message` exige un ajustement mineur
(à confirmer en ouverture de phase).

**Risques** :
- `T-realtime-softdelete-rls` n'a jamais été exécuté en websocket réel malgré 2 migrations déjà
  livrées — c'est un vrai gap de preuve, pas une hypothèse, à fermer en premier.
- Le choix "Edge Function orchestrée" vs "RLS directe" pour `send-message` engage durablement le
  contrat Flutter (`MESSAGING_API_CONTRACT.md`) — un mauvais choix ici coûte cher à changer une fois
  Phase 2+ commencées.

**Preuves attendues** : appels Edge Function réels contre le projet lié, capture d'événements
websocket réels (positif + négatif tiers) pour le test Realtime, `flutter analyze` = 0 sur le
contrat Flutter (modèles/repository, pas d'écran).

**Critères GO/NO-GO** :
- GO si : les 2 Edge Functions (ou le chemin RLS direct documenté) sont testées positif/négatif/
  cross-salon, `T-realtime-softdelete-rls` est passé avec capture réelle, `MESSAGING_API_CONTRACT.md`
  section Conversation/Messages/Realtime est gelée.
- NO-GO si : la moindre de ces preuves manque, ou si une Edge Function a été écrite sans son test
  négatif.

**Rollback** : suppression des Edge Functions (aucune migration SQL nouvelle attendue dans le cas
nominal). Si un ajustement SQL s'avère nécessaire, il suit son propre cycle Rule 8 complet (rollback
testé UP→DOWN comme Migration 2).

---

## Phase 2 — Conversation Experience

**Objectif** : la messagerie atteint la richesse fonctionnelle d'un client de chat standard (WhatsApp-like).

**Périmètre** (découpé en lots indépendants, voir Mission 2 / `MESSAGING_EXECUTION_PLAN.md`) :
archive, pin, hide (déjà entièrement couvert côté RLS/trigger depuis Migration 1/1.5 — Flutter
seulement), compteurs (badge — déjà couvert DEC-014, Flutter seulement), édition (nouvelle migration
additive, fenêtre à définir), suppression (déjà couverte Migration 2 — vérification seulement),
blocage (Edge Function `toggle-conversation-block`, spec déjà écrite ADR §B/§C/§D.6, jamais codée).

**Exclus** : notifications (Phase 3), signalement/modération (Phase 4), offline (Phase 6).

**Dépendances** : Phase 1 livrée et son contrat gelé (l'édition et le blocage s'appuient sur le même
mécanisme d'appel que `send-message`/`create-conversation`).

**Risques** : l'édition touche `protect_message_columns`, une fonction **déjà en production** — tout
changement dessus doit rejouer l'intégralité des tests Migration 2 en non-régression, pas seulement
les nouveaux tests d'édition. C'est le risque technique le plus concret de cette phase.

**Preuves attendues** : non-régression complète Migration 2 (tous les tests déjà existants rejoués),
tests positifs/négatifs pour chaque nouvelle capacité, capture `activity_logs` réelle pour le
blocage (DEC-015 §C).

**Critères GO/NO-GO** :
- GO si : chaque lot de cette phase (voir plan d'exécution) est individuellement fermé selon Rule 8
  avant le suivant, la non-régression Migration 2 est prouvée après la modification de
  `protect_message_columns`, `toggle-conversation-block` est testée avec le cas rotation de manager
  (§B.1 de l'ADR) et le cas cross-salon (§D.6).
- NO-GO si : `protect_message_columns` est modifiée sans rejeu complet des tests Migration 2.

**Rollback** : par lot (voir `MESSAGING_EXECUTION_PLAN.md`) — la migration d'édition a son propre
DOWN testé ; `toggle-conversation-block` se retire sans SQL (aucune nouvelle colonne, seulement une
Edge Function).

---

## Phase 3 — Notifications

**Objectif** : chaque événement de messagerie pertinent (nouveau message, mention, blocage,
signalement traité) déclenche une notification fiable, livrée, et actionnable (deep link), avec
contrôle utilisateur (mute) — sans dupliquer l'infrastructure `notification_*` déjà en production
(D2, principe déjà verrouillé : catégorie 4 reste hors des tables de messagerie).

**Périmètre** : dispatch push à l'envoi d'un message (réutilise `_shared/fcm.ts`, `device_tokens`,
déjà en production depuis Phase 1b de l'architecture Phase 0 — **aucune nouvelle infrastructure FCM
à construire**, seulement le routage/template propre à la messagerie, exactement comme l'ADR le
prévoyait déjà pour `send-message`), badge agrégé (déjà couvert DEC-014 côté données, ce lot = la
consommation Flutter + son intégration avec le flux de notifications système), deep link vers la
conversation concernée (réutilise `DeepLinkHandler`, précédent déjà établi), notifications
silencieuses (à spécifier — aucune décision existante), mute par conversation (**nouveau** — aucune
colonne/mécanisme n'existe aujourd'hui pour "recevoir moins/pas de push sur ce fil précis sans le
masquer de l'inbox" ; distinct de `client_hidden_at`/`client_archived`, qui affectent la visibilité
dans la liste, pas la notification), retry d'envoi push (à spécifier), accusés de livraison/lecture
(le "delivered" FCM réel reste un ticket déjà connu et non résolu — voir note ci-dessous).

**Exclus** : signalement (Phase 4 — mais Phase 4 en dépend pour notifier une résolution), tout écran
de conversation lui-même (Phase 2).

**Dépendances** : Phase 1 (les messages existent, il faut un événement à notifier).

**Dette héritée à ne pas ignorer, déjà documentée** (mémoire `project_messaging_phase0_architecture`,
non résolue à ce jour) : `_shared/fcm.ts` avale toute erreur FCM et ne lit jamais le corps de la
réponse — `notification_logs.delivered` signifie "l'appel HTTP n'a pas levé d'exception", pas
"FCM a confirmé la livraison". Tant que ce ticket n'est pas fermé, tout "accusé de livraison" de
cette phase hérite de la même limite — à énoncer honnêtement dans la doc utilisateur/monitoring,
pas à prétendre résolu par ce chantier.

**Risques** : le "mute" nécessite une décision de schéma (nouvelle colonne/table) non prise — à
trancher en ouverture de phase, pas en cours d'implémentation. Le retry d'envoi push, si mal
dimensionné, peut dupliquer des notifications (idempotence à vérifier avant d'écrire).

**Preuves attendues** : notification réelle reçue sur un appareil réel après envoi d'un message
(pas seulement `notification_logs` peuplé), deep link réel ouvrant la bonne conversation, mute
vérifié empêchant réellement la réception (pas seulement l'écriture d'un flag).

**Critères GO/NO-GO** :
- GO si : push réel reçu + deep link réel vérifié sur appareil, mute conçu et testé, aucune
  duplication de `device_tokens`/`fcm.ts` (réutilisation stricte, pas de nouvelle infra parallèle).
- NO-GO si : une nouvelle table de notifications parallèle à `notification_*` est introduite (violerait D2).

**Rollback** : retrait du routage/template propre à la messagerie dans `send-notification` (ou de la
nouvelle Edge Function dédiée si ce choix est retenu) — n'affecte pas `notification_*` pour les
autres domaines (D2 garantit l'isolation).

---

## Phase 4 — Sécurité & Modération

**Objectif** : la messagerie est protégée contre l'abus (signalement, spam) avec une traçabilité
d'audit, avant toute exposition à des utilisateurs non contrôlés.

**Périmètre** : `message_reports` (Migration 3 — 5 points déjà identifiés à trancher, voir
`MESSAGING_EXECUTION_PLAN.md`), anti-spam/rate limiting (**réutilise `checkRateLimit()`/
`check_rate_limit()` déjà en production, gate ~15 Edge Functions existantes, ADR-0001 — pas un
mécanisme à inventer**), audit (`activity_logs`, même précédent que DEC-015).

**Exclus** : notifications (Phase 3, déjà livrée et consommée ici pour notifier un signalement
traité), offline (Phase 6).

**Dépendances** : Phase 1 (`messages` existe), Phase 3 (notifier la résolution d'un signalement).

**Risques** : le brouillon `message_reports` (doc canonique §5.7) a un trigger
(`flag_message_on_report`) qui fera un `UPDATE messages SET is_flagged=true` imbriqué — cet appel
sera **rejeté** par `protect_message_columns` (déjà en production depuis Migration 2, catégorie
`is_flagged` sans exception `nested`) sauf décision explicite (`SECURITY DEFINER` sur ce trigger, ou
extension de la garde). C'est un risque de régression silencieuse en production si non traité avant
d'écrire Migration 3, déjà identifié et à trancher en priorité absolue de cette phase.

**Preuves attendues** : signalement réel + `is_flagged` correctement mis à jour sans casser
`protect_message_columns`, rate limit déclenché après seuil réel (réutilisation de `checkRateLimit`),
`activity_logs` réellement peuplé à la résolution.

**Critères GO/NO-GO** :
- GO si : les 5 points `message_reports` (conflit `protect_message_columns`, UNIQUE anti-doublon,
  conflit d'intérêt `FOR ALL`, traçabilité `activity_logs`, DEC-XXX assigné) sont tranchés et
  implémentés, revue de sécurité ADR §D rejouée contre l'implémentation réelle.
- NO-GO si : le conflit `protect_message_columns` n'a pas de décision explicite avant l'écriture du
  trigger de signalement.

**Rollback** : `DROP TABLE message_reports` + retrait du trigger/Edge Function — testé UP→DOWN comme
Migration 2, pas en schéma miroir (table neuve, pas de dépendant).

---

## Phase 5 — Optimisation & Production

**Objectif** : le système mesuré, indexé et observé à l'échelle réelle du trafic accumulé depuis les
phases précédentes — jamais préventif sur des tables vides (ADR §10, principe déjà verrouillé).

**Périmètre** : `EXPLAIN ANALYZE` sur les requêtes réelles, revue d'index (les 2 index déjà en place
sur `messages` suffisent-ils au pattern de requête réellement observé), monitoring avancé (au-delà
du minimal de Phase 1), manuels d'exploitation, revue de sécurité finale, fermeture des résidus
"Élevée" restants de l'ADR.

**Point de vigilance factuel, pas une remise en cause** : DEC-014 (`bump_conversation_on_message`)
est un trigger `FOR EACH ROW`, alors qu'ADR-0003 (déjà accepté sur ce projet, pour
`monthly_bookings_count`) établit `FOR EACH STATEMENT` comme le patron par défaut pour un agrégat
par parent. Ce n'est **pas** un défaut à corriger par réflexe : ADR-0003 concerne un cas de bulk-
insert (import, migration de masse) ; l'insertion de messages est unitaire par construction
(un utilisateur envoie un message à la fois, jamais un lot). À **mesurer** dans cette phase avec le
trafic réel accumulé — pas à changer par supposition. Si la mesure montre un coût réel à l'échelle,
ce sera une nouvelle décision documentée (nouveau DEC ou nouvel ADR-000x), pas une correction
silencieuse d'une décision déjà `LOCKED`.

**Exclus** : toute nouvelle fonctionnalité — cette phase ne fait que mesurer/durcir l'existant.

**Dépendances** : Phases 1-4 livrées (mesurer un système réellement utilisé).

**Risques** : le principal risque de cette phase est l'optimisation prématurée — l'ADR l'interdit déjà
explicitement, la discipline est de s'y tenir, pas de la contourner "pour être sûr".

**Preuves attendues** : `EXPLAIN ANALYZE` réel avec des lignes réelles (pas des fixtures jetables),
monitoring effectivement branché et recevant des données de production.

**Critères GO/NO-GO** :
- GO si : `docs/MESSAGING_FOUNDATION_CHECKLIST.md` section "Prêt pour la production" est cochée en
  entier, aucun résidu "Élevée" `OPEN` restant dans l'ADR.
- NO-GO si : un index/changement est ajouté sans mesure réelle préalable.

**Rollback** : `DROP INDEX` pour tout index ajouté ; aucun changement fonctionnel à annuler.

---

## Phase 6 — Offline & Synchronisation

**Objectif** : la messagerie fonctionne sans connexion réseau, avec réconciliation fiable au retour
en ligne.

**Périmètre** : cache Hive, extension `MutationOutboxService`/`OfflineSyncCoordinator` (déjà
existants, `lib/core/services/`) pour le type `messageSend`, retry avec backoff, réconciliation par
`client_message_id` (jamais par contenu — mécanisme déjà retenu, ADR Partie B.1), reprise du flux
Realtime après coupure.

**Exclus** : toute nouvelle fonctionnalité serveur — cette phase est presque entièrement Flutter, le
contrat serveur (dédup, `is_local`) existe déjà depuis Migration 2/Phase 1.

**Dépendances** : Phase 1 (contrat serveur stable), Phase 5 par choix produit (voir note
d'ordonnancement ci-dessus), pas par nécessité technique.

**Risques** : précédent déjà connu sur ce projet — les tests Hive + reconnexion réseau réels peuvent
geler silencieusement en environnement de test (`feedback_widget_test_hive_router_hangs`) ; utiliser
des fakes en mémoire dans les tests automatisés, jamais un vrai tempdir Hive.

**Preuves attendues** : `T-local-01` (ADR §B.1) exécuté réellement (mode avion → reconnexion → une
seule bulle, pas de doublon), test manuel réel sur téléphone.

**Critères GO/NO-GO** :
- GO si : `T-local-01` passe, aucun doublon visuel après réconciliation, retry testé avec échec
  réseau simulé réel (pas mocké au niveau HTTP uniquement).
- NO-GO si : la réconciliation s'appuie sur autre chose que `client_message_id` (correspondance de
  contenu, timestamp, etc. — régresserait un principe déjà verrouillé, ADR Partie B.1).

**Rollback** : N/A côté serveur (aucune migration) — rollback Flutter uniquement.

---

## Gouvernance d'exécution (Mission 6 — rappel, détail dans l'ADR)

À partir de ce document, **aucune revue générale d'architecture n'est plus ouverte par défaut**. Les
seules revues autorisées pendant l'exécution des Phases 1-6 sont : revue du lot/phase courante, revue
sécurité, revue performance, revue rollback. Une revue d'architecture globale ne rouvre que sur
preuve réelle d'une contradiction démontrée (même standard que celui déjà appliqué à DEC-022/023 :
preuve directe, pas supposition) — voir `docs/ADR_MESSAGING_FOUNDATION.md`, section "Gouvernance
d'exécution post-fondation" pour le texte normatif complet.
