# ADR — Fondation de la messagerie KYNZA

**Statut : `LOCKED — verrouillé le 2026-07-21 après audit final pré-verrouillage`.**

Ce document est désormais la référence unique et contraignante pour toute décision d'architecture
touchant la messagerie — aucune revue de conception ne doit être rejouée depuis zéro pour une
fonctionnalité déjà couverte ici : on lit l'ADR. Voir « Verrouillage — audit final » en fin de
document pour le détail des 22 vérifications et des corrections cléricales appliquées à ce tour.

Toute affirmation de ce document est adossée à une preuve réelle : `fichier:ligne` du dépôt, la
migration réellement appliquée (`20260721160000_conversations_schema.sql`, commit `28a269c`,
projet lié `hhdkjfpgaklhrhfoxlhj`), ou un résultat de test réel (SQLSTATE + message). Tout élément
qui ne peut être adossé à une preuve est marqué `NON PROUVÉ`, jamais affirmé.

---

## §1 — Décisions d'architecture verrouillées

### DEC-001 — FK simple `related_booking_id → bookings(id)` conservée
**Énoncé** : la FK simple coexiste avec la FK composite (DEC-002), elle n'est jamais redondante.
**Raison** : sous MATCH SIMPLE, une FK composite est un no-op dès qu'une colonne référençante est
`NULL`. Pour `type = 'client_salon'`, `staff_id IS NULL` est imposé par `chk_staff_type`
(DEC-003) — la FK composite ne vérifie donc rien sur cette branche. Seule la FK simple garantit
que `related_booking_id`, quand renseigné, pointe une réservation réelle.
**Preuve** : `20260721160000_conversations_schema.sql:147-148,211-212` (SQL + commentaire
protecteur committé) ; test **T5** — `INSERT` `client_salon`/`staff_id NULL`/booking inexistant
→ **REJETÉ**, `23503`, `violates foreign key constraint "fk_conversations_related_booking_simple"`.
Précédent de la même forme (référence justificative optionnelle, sans condition) :
`notification_logs.related_booking_id` (`20260624060000_notifications_schema.sql:69`).
**Conséquence** : ne jamais supprimer cette FK au prétexte de redondance avec la composite.

### DEC-002 — FK composite `(related_booking_id, client_id, staff_id, salon_id) → bookings(id, client_id, practitioner_id, salon_id)` conservée
**Énoncé** : verrouille en une seule contrainte l'identité complète d'une conversation
`client_staff` contre la réservation citée.
**Raison** : sans elle, rien n'empêche un `staff_id`/`client_id`/`salon_id` incohérent avec le
`related_booking_id` cité sur la branche `client_staff`.
**Preuve** : `20260721160000_conversations_schema.sql:149-151,214-215` ; test **T4** — tuple avec
`staff_id` ne correspondant pas au `practitioner_id` du booking → **REJETÉ**, `23503`,
`violates foreign key constraint "fk_conversations_related_booking_composite"` ; test **T9** —
tuple réellement cohérent → **ACCEPTÉ**.
**Conséquence** : ne remplace pas DEC-001 ; les deux sont complémentaires, jamais l'une sans
l'autre.

### DEC-003 — MATCH SIMPLE (défaut Postgres, non modifié)
**Énoncé** : la FK composite utilise MATCH SIMPLE, pas MATCH FULL.
**Raison** : MATCH FULL exigerait que toutes les colonnes référençantes soient NULL ou toutes
non-NULL simultanément — incompatible avec `client_salon` (`staff_id` seul NULL, les trois autres
renseignées). MATCH SIMPLE est le comportement recherché : no-op dès qu'une seule colonne est
NULL.
**Preuve** : `pg_constraint.confmatchtype = 's'` (confirmé par sondage direct de la contrainte lors
de la revue scratch du 2026-07-21, avant écriture de la migration).
**Conséquence** : ne jamais passer cette FK en MATCH FULL — casserait `client_salon` (DEC-003 fait
partie intégrante de DEC-001/DEC-002, pas une option indépendante).

### DEC-004 — CHECK biconditionnelle `chk_staff_type`
**Énoncé** : `(type = 'client_salon' AND staff_id IS NULL) OR (type = 'client_staff' AND staff_id IS NOT NULL)`.
**Raison** : rend le no-op MATCH SIMPLE de DEC-002 sur `client_salon` une conséquence **prouvée
par construction** du schéma, pas une hypothèse — la base refuse physiquement toute autre
combinaison, sur tout chemin d'écriture, `service_role` compris.
**Preuve** : `20260721160000_conversations_schema.sql:140-143,226-227` ; tests **T1**
(`client_salon`+`staff_id` renseigné → `23514`, `violates check constraint "chk_staff_type"`) et
**T2** (`client_staff`+`staff_id` NULL → même SQLSTATE/contrainte).
**Conséquence** : ne jamais affaiblir en CHECK unidirectionnelle.

### DEC-005 — CHECK `chk_staff_requires_booking` (invariant 1)
**Énoncé** : `type = 'client_salon' OR (type = 'client_staff' AND related_booking_id IS NOT NULL)`.
**Raison** : une conversation `client_staff` doit toujours citer la réservation qui la justifie.
**Preuve** : `20260721160000_conversations_schema.sql:144-146,229-230` ; test **T3** —
`client_staff`+`related_booking_id` NULL → **REJETÉ**, `23514`,
`violates check constraint "chk_staff_requires_booking"`.
**Conséquence** : l'invariant 6 (cohérence staff↔salon) est hérité de `bookings` via DEC-002,
jamais ré-appliqué indépendamment par une contrainte dédiée ici (voir §3, invariant 6).

### DEC-006 — Trigger invariant 7, inconditionnel
**Énoncé** : `BEFORE INSERT` sur `conversations`, rejette tout `INSERT` dont `salon_id` référence
un salon `deleted_at IS NOT NULL`. Aucun garde `auth.role()`.
**Raison** : un garde `auth.role() = 'authenticated'` exempterait `service_role` — le rôle exact de
la future Edge Function `create-conversation` — et casserait DEC-007 (invariant 9).
**Preuve** : `20260721160000_conversations_schema.sql:165-179,223-224` (`SECURITY DEFINER`,
`SET search_path = public, pg_temp`, `REVOKE EXECUTE ... FROM authenticated, anon, public`) ;
squelette calqué sur `protect_user_columns` (`20260623120000_users_schema_rls_hardening.sql:48-71,118-119`)
**moins** son garde `auth.role()` ; forme inconditionnelle déjà en production ailleurs :
`prevent_staff_removal_with_future_bookings` (`20260623240000_bookings_schema.sql:86-106`).
Tests **T6a** (rôle `postgres`, `rolbypassrls=true`) et **T6b** (`SET ROLE service_role`,
`rolbypassrls=true`) contre un vrai salon soft-deleted en production
(`27db89d3-4590-4c4c-be45-b6dad01706a8`) → **REJETÉS**, `P0001`,
`conversations.salon_id ... is soft-deleted (invariant 7): cannot open a conversation against an inactive salon`,
message identique sous les deux rôles.
**Conséquence** : ne jamais ajouter de garde de rôle sur ce trigger (voir §6, inversion critique).

### DEC-007 — Invariant 9 : aucun contournement, `service_role` compris
**Énoncé** : les contraintes de table et les triggers lient tout rôle, y compris tout rôle
`BYPASSRLS` ; seule la RLS (`USING`/`WITH CHECK`) est contournée par `BYPASSRLS`.
**Raison** : `service_role` (Edge Functions) a `rolbypassrls = true` — une garantie qui ne
survivrait pas à `service_role` n'est pas une garantie.
**Preuve** : `pg_roles` confirme `service_role.rolbypassrls = true` et `postgres.rolbypassrls = true`
(sondé en direct sur le projet lié avant écriture de la migration) ; test **T6b** (ci-dessus) est
la preuve empirique directe, rejouée contre la table réellement appliquée en production.
**Conséquence** : toute règle d'intégrité future sur ce domaine doit être exprimée en CHECK/FK/
UNIQUE/Trigger, jamais en RLS seule (voir §5).

### DEC-008 — UNIQUE additif `bookings(id, client_id, practitioner_id, salon_id)`
**Énoncé** : nouvelle contrainte UNIQUE sur `bookings`, seule modification d'une table existante
dans cette fondation.
**Raison** : backing obligatoire de la FK composite (DEC-002) — Postgres exige qu'une FK
multi-colonnes référence un ensemble de colonnes couvert exactement par une UNIQUE/PK du parent.
**Preuve** : `20260721160000_conversations_schema.sql:106-107` ; créée sans erreur, sans risque de
donnée (`bookings.id` déjà PK — tout sur-ensemble incluant `id` est trivialement déjà unique pour
chaque ligne existante) ; disjointe de `uq_practitioner_slot(practitioner_id, start_time)`
(`20260623240000_bookings_schema.sql:34`).
**Conséquence** : c'est la seule extension autorisée d'une table préexistante en Maintenance Mode
pour cette fondation — déclarative, additive, sans trigger.

### DEC-009 — Index uniques anti-doublon en unicité TOTALE
**Énoncé** : `uq_conversations_client_salon`/`uq_conversations_client_staff`, jamais
`AND deleted_at IS NULL`.
**Raison** : `conversations.deleted_at` (global) n'a aucun écrivain applicatif — réservé à un
effacement administratif/RGPD futur, jamais posé par une action utilisateur (le retrait par
partie utilise `client_deleted_at`/`salon_deleted_at`, hors du prédicat de ces index). Le modèle
produit est **réouverture, pas recréation**.
**Preuve** : `20260721160000_conversations_schema.sql:154-157,217-221` ; test **T7** (2ᵉ
`client_staff` même paire → `23505`, `uq_conversations_client_staff`) ; test **T8** (même paire
après `deleted_at` global posé sur la 1ʳᵉ ligne → **toujours** `23505`, confirmant l'absence de
tout filtrage partiel).
**Conséquence** : ne jamais copier le patron partiel de `idx_device_tokens_token_unique`
(`20260717140000_device_tokens.sql:30-31`) — ce cas a un cycle réel révocation/réémission ;
`conversations` n'en a pas.

### DEC-010 — `NO ACTION` sur toutes les FK
**Énoncé** : aucune clause `ON DELETE`/`ON UPDATE` sur `salon_id`, `client_id`, `staff_id`,
`related_booking_id` (simple et composite), `blocked_by`.
**Raison** : domaine soft-delete-only — aucune ligne référencée n'est censée disparaître
physiquement ; une suppression physique doit surfacer une erreur, jamais cascader en silence.
Aligné sur 100 % des FK existantes du domaine métier.
**Preuve** : `20260721160000_conversations_schema.sql:68-78,114-117,133,147-151` ; convention
confirmée sur `bookings.salon_id/client_id/practitioner_id`
(`20260623240000_bookings_schema.sql:7-9`) et `notification_logs.related_booking_id`
(`20260624060000_notifications_schema.sql:69`), aucune sans clause.
**Conséquence — ticket RGPD ouvert** : `public.users.id → auth.users(id)` est en
`ON DELETE CASCADE` (`20260622182007_foundation.sql:37`), seule exception du dépôt. Le jour où un
flux RGPD supprimera un compte `auth.users`, la cascade vers `public.users` sera **bloquée** par
ces FK `NO ACTION` tant que les conversations (et futurs messages) de l'utilisateur ne sont pas
purgées d'abord. Aucun flux RGPD n'existe encore dans ce dépôt — ceci doit être un prérequis du
premier flux construit. Voir ledger `DEC-010`, statut « ticket ouvert ».

### DEC-011 — Commentaires protecteurs obligatoires
**Énoncé** : chaque décision à risque de simplification future porte un `COMMENT ON ...` dans le
SQL lui-même, pas seulement dans la documentation.
**Preuve** : les 7 `COMMENT ON` réellement committés (compte vérifié par recherche exhaustive du
fichier, 2026-07-21) — `20260721160000_conversations_schema.sql:
211-212` (FK simple), `:214-215` (FK composite), `:217-218` (index client_salon), `:220-221`
(index client_staff, par renvoi), `:223-224` (fonction trigger invariant 7), `:226-227`
(`chk_staff_type`), `:229-230` (`chk_staff_requires_booking`).
**Conséquence** : voir §8 pour le détail de chacun.

### DEC-012 — Convention de nommage retenue
**Énoncé** : préfixes `chk_`/`uq_`/`idx_` conformes à la convention existante ; les deux FK
(`fk_conversations_related_booking_simple`/`_composite`) sont nommées explicitement, en
déviation minimale et délibérée de la convention (aucune FK simple n'est nommée ailleurs dans le
dépôt — auto-nommage Postgres `<table>_<colonne>_fkey`).
**Preuve** : `20260721160000_conversations_schema.sql:80-87` ; précédent `chk_` :
`chk_maintenance_window_order` (`20260630110100_phase4_maintenance.sql:14`) ; précédent `uq_` :
`uq_practitioner_slot` (`20260623240000_bookings_schema.sql:34`) ; absence de précédent `fk_` :
recherche exhaustive du dépôt lors de la revue du 2026-07-21, zéro résultat.
**Conséquence** : justifié uniquement pour que `COMMENT ON CONSTRAINT` (DEC-011) puisse cibler
les deux FK de façon symétrique et prévisible — aucune autre convention nouvelle n'est introduite.

### DEC-021 — Gap RLS Migration 1 : policies `UPDATE` sans restriction de colonnes
**Énoncé** : `conversations_client_update_own_state`/`conversations_staff_update_own_state`
bornent la LIGNE affectée (`client_id = auth.uid()` / `staff_id IN (...)`) mais aucune COLONNE —
un client ou un membre du staff peut aujourd'hui muter via un `UPDATE` direct n'importe quelle
colonne de sa propre ligne, y compris `salon_pinned`/`client_pinned` du côté adverse au sens
large, `blocked_by`/`blocked_at`, `last_message_at`/`last_message_preview`,
`client_unread_count`/`salon_unread_count`.
**Raison** : une policy RLS `WITH CHECK` borne des lignes, jamais des colonnes individuelles — ce
n'est pas un défaut de Migration 1 (son périmètre verrouillé ne couvrait pas la protection de
colonnes, signalé dès le commit `28a269c`) mais une dette de sécurité réelle et déjà active tant
que DEC-013 n'est pas implémentée.
**Preuve** : absence de toute restriction de colonnes dans les deux policies `UPDATE`,
`20260721160000_conversations_schema.sql:200-205`.
**Statut** : `OPEN` — dette de sécurité tracée, non bloquante pour ce verrouillage (elle ne
contredit aucune décision `LOCKED` de Migration 1), fermée par DEC-013
(`protect_conversation_columns`) avant Migration 2.
**Conséquence** : ne pas commencer Migration 2 tant que DEC-013 n'a pas fermé ce gap — un message
inséré dans une conversation dont l'état a été manipulé via ce gap (ex. `blocked_by` auto-effacé)
serait une régression de sécurité, pas seulement de schéma.

---

## §2 — Decision Ledger

| ID | Décision | Statut | Date | Migration | Preuve |
|---|---|---|---|---|---|
| DEC-001 | FK simple conservée | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:147-148` · test T5 (`23503`) |
| DEC-002 | FK composite conservée | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:149-151` · tests T4/T9 |
| DEC-003 | MATCH SIMPLE | **LOCKED** | 2026-07-21 | Migration 1 | `pg_constraint.confmatchtype='s'` (sondage scratch) |
| DEC-004 | `chk_staff_type` biconditionnelle | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:140-143` · tests T1/T2 (`23514`) |
| DEC-005 | `chk_staff_requires_booking` (invariant 1) | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:144-146` · test T3 (`23514`) |
| DEC-006 | Trigger invariant 7 inconditionnel | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:165-179` · tests T6a/T6b (`P0001`) |
| DEC-007 | Invariant 9 (aucun bypass) | **LOCKED** | 2026-07-21 | Migration 1 | `pg_roles` (`service_role.rolbypassrls=true`) · test T6b |
| DEC-008 | UNIQUE additif sur `bookings` | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:106-107` |
| DEC-009 | Index uniques TOTAUX | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:154-157` · tests T7/T8 (`23505`) |
| DEC-010 | `NO ACTION` sur toutes les FK — **ticket RGPD ouvert** | **LOCKED** (ticket ouvert) | 2026-07-21 | Migration 1 | `...conversations_schema.sql:68-78` · `foundation.sql:37` |
| DEC-011 | Commentaires protecteurs | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:211-230` |
| DEC-012 | Convention de nommage FK | **LOCKED** | 2026-07-21 | Migration 1 | `...conversations_schema.sql:80-87` |
| DEC-013 | `protect_conversation_columns` (garde par colonne) | **TO-DESIGN** | — | avant Migration 2 | §"TO-DESIGN" ci-dessous |
| DEC-014 | Trigger de compteurs `*_unread_count`/`last_message_*` | **TO-DESIGN** | — | Migration 2 (`messages`) | §"TO-DESIGN" ci-dessous |
| DEC-015 | Règle de blocage (`blocked_by`/`blocked_at`) | **TO-DESIGN — À CONFIRMER** | — | avant Migration 2 | doc canonique §5.2, non re-vérifié dans ce tour |
| DEC-016 | Éligibilité dérivée catégorie 2 (booking actif) | **TO-DESIGN** | — | Migration 2 (`messages`) | voir §"Points spécifiques" |
| DEC-017 | Catégorie 3 (diffusion salon→N), `broadcast_*` | **OUT-OF-SCOPE** | — | mandat marketing séparé | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:466-520` |
| DEC-018 | `gift_cards`, attachement `gift_card` | **OUT-OF-SCOPE** | — | mandat produit financier séparé | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:482-496,856` |
| DEC-019 | Attachement `coupon` | **OUT-OF-SCOPE** | — | différé, cf. §11 doc canonique | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:857` |
| DEC-020 | `conversation_requests` (contact pré-réservation) | **OUT-OF-SCOPE** | — | mandat produit futur, priorité haute | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:604-617` |
| DEC-021 | Gap RLS Migration 1 (policies `UPDATE` sans restriction de colonnes) | **OPEN** (dette sécurité) | 2026-07-21 | Migration 1 (gap) — fermeture avant Migration 2 | `...conversations_schema.sql:200-205` · lié à DEC-013 |

---

## Notes ouvertes

| Statut | Note |
|---|---|
| `OPEN` | §6, pattern squelette `protect_user_columns` : la mention "aucun GRANT" est une propriété du cas TRIGGER, pas du squelette `SECURITY DEFINER` en général — une fonction RPC `SECURITY DEFINER` (ex. `upsert_device_token`, `GRANT EXECUTE TO authenticated`) fait exception. Préciser le jour où le §6 servira de modèle à une fonction RPC. Non traité ici. |

---

## §3 — Catalogue des invariants (1 à 9)

| # | Énoncé | Mécanisme réel | Test | SQLSTATE attendu | Résultat réel |
|---|---|---|---|---|---|
| **1** | `client_staff` requiert `related_booking_id IS NOT NULL` | CHECK `chk_staff_requires_booking` | T3 | `23514` | **Obtenu** — `violates check constraint "chk_staff_requires_booking"` |
| 2 | tuple `(client_id)` de la conversation cohérent avec la réservation citée | FK composite (partie 1/3) | T4 | `23503` | **Obtenu** — `violates foreign key constraint "fk_conversations_related_booking_composite"` |
| 3 | tuple `(staff_id)` cohérent avec `practitioner_id` du booking | FK composite (partie 2/3) | T4 | `23503` | **Obtenu** (même test que #2, un seul mécanisme couvre les trois) |
| 4 | tuple `(salon_id)` cohérent avec `salon_id` du booking | FK composite (partie 3/3) | T-inv4 (isolé, 2026-07-21) | `23503` | **Obtenu** — `violates foreign key constraint "fk_conversations_related_booking_composite"`. Test isolé : `client_id`/`staff_id`/`related_booking_id` strictement identiques à un booking réel existant, seul `salon_id` diffère (un second salon réel, actif, distinct) ; exécuté dans une transaction `BEGIN...ROLLBACK`, aucune persistance. |
| 5 | `related_booking_id`, quand renseigné sur `client_salon`, pointe une réservation réelle | FK simple | T5 | `23503` | **Obtenu** — `violates foreign key constraint "fk_conversations_related_booking_simple"` |
| **6** | cohérence staff↔salon (le staff cité appartient bien au salon cité) | **hérité de `bookings` via la FK composite** — non ré-implémenté indépendamment | aucun test dédié sur `conversations` | — | Garanti transitivement, jamais vérifié en double ici (voir DEC-005) |
| **7** | une conversation ne peut être ouverte contre un salon soft-deleted | Trigger `BEFORE INSERT` inconditionnel | T6a, T6b | `P0001` | **Obtenu**, sous `postgres` et sous `service_role` |
| 8 | une paire `(salon_id, client_id)` `client_salon` ne peut exister deux fois | Index UNIQUE `uq_conversations_client_salon` | T-inv8 (isolé, 2026-07-21) | `23505` | **Obtenu** — `duplicate key value violates unique constraint "uq_conversations_client_salon"`. Test isolé : 1ʳᵉ insertion `client_salon` acceptée, 2ᵈᵉ insertion même paire `(salon_id, client_id)` rejetée ; exécuté dans une transaction `BEGIN...ROLLBACK`, aucune persistance. |
| **9** | aucune contrainte/trigger n'est contournée par un rôle `BYPASSRLS` (`service_role` compris) | Propriété structurelle des contraintes/triggers Postgres — pas un mécanisme dédié | T6b | `P0001` | **Obtenu** — preuve directe |

**Marquage explicite** : l'invariant 3 est couvert par le même mécanisme que l'invariant 2 (test
T4) mais n'a pas été isolé par un test dédié variant `staff_id` seul — il reste donc
`NON PROUVÉ INDIVIDUELLEMENT`, bien que le mécanisme sous-jacent (une contrainte unique de table,
pas des mécanismes séparés) rende la distinction largement théorique. Ne pas présenter cela comme
une lacune de couverture réelle sans le qualifier ainsi.
Les invariants 4 et 8, précédemment dans cette même situation, ont depuis été isolés par un test
dédié (2026-07-21, transactions `BEGIN...ROLLBACK`, aucune persistance) — voir leurs lignes
ci-dessus.

---

## §4 — Matrice « qui garantit quoi »

| Invariant | CHECK | FK | UNIQUE | Trigger | RLS | Edge Function |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 — booking requis si `client_staff` | ✕ | | | | | |
| 2/3/4 — tuple cohérent avec le booking | | ✕ | | | | |
| 5 — booking existe (branche `client_salon`) | | ✕ | | | | |
| 6 — staff↔salon cohérent | | ✕ *(hérité)* | | | | |
| 7 — salon actif à l'ouverture | | | | ✕ | | |
| 8 — paire unique | | | ✕ | | | |
| 9 — aucun bypass | *(propriété transversale, pas une ligne du tableau — vraie par construction pour CHECK/FK/UNIQUE/Trigger, fausse pour RLS)* |
| Qui peut créer une conversation | | | | | (aucune policy INSERT `authenticated`) | ✕ *(future `create-conversation`, éligibilité anti-spam)* |
| Qui peut lire une conversation | | | | | ✕ (`conversations_client_select`/`_staff_select`/`_owner_manager_select`) | |

**Objectif explicite** : ce tableau existe pour qu'une future Edge Function ne duplique jamais une
garantie déjà portée par PostgreSQL. La colonne « Edge Function » n'a qu'une seule croix dans tout
le tableau — l'éligibilité de création (logique métier non exprimable en CHECK/FK/RLS : historique
de réservation, cf. §"Points spécifiques"). Toute autre case cochée ailleurs signifie que
l'Edge Function correspondante n'a **rien à revérifier** : la base rejette déjà.

---

## §5 — Convention de mécanisme (ordre de préférence)

**Règle** : exprimer un invariant par le mécanisme le plus déclaratif possible, dans cet ordre :
**CHECK → FK → UNIQUE → Trigger** (dernier recours) **→ jamais une Edge Function comme garantie**.

Un trigger n'est justifié que lorsqu'aucune contrainte déclarative ne peut exprimer la règle.
Exemple réel et unique de cette fondation : l'invariant 7 exige une condition sur une colonne
**d'une ligne référencée** (`salons.deleted_at`) — ni une FK (qui ne vérifie que l'existence, pas
un état) ni un CHECK (limité aux colonnes de la ligne en cours d'écriture) ne peuvent l'exprimer.
Un trigger `BEFORE INSERT` est la seule solution déclarative-adjacente disponible.

**Une Edge Function n'est jamais une garantie d'intégrité.** Elle orchestre (ex. : appelle
`create-conversation`, vérifie l'éligibilité métier non modélisable en contrainte, insère), elle
ne garantit pas — parce qu'elle tourne en `service_role` (`BYPASSRLS`) et peut contenir un bug.
Toute garantie qui doit survivre à un appelant `service_role` buggé est une contrainte ou un
trigger, jamais une vérification applicative seule (DEC-007).

---

## §6 — Patterns validés

### Pattern « squelette `protect_user_columns` »
**Composition** : `SECURITY DEFINER` + `SET search_path = public, pg_temp` + `REVOKE EXECUTE FROM authenticated, anon, public` + aucun `GRANT`.
**Précédent** : `20260623120000_users_schema_rls_hardening.sql:48-71,118-119`.
**Quand l'utiliser** : toute fonction déclenchée par trigger qui doit être protégée contre un appel
RPC direct (`SELECT ma_fonction()`), tout en restant appelable par le mécanisme de trigger
lui-même (le déclenchement d'un trigger n'exige aucun `EXECUTE` accordé à l'appelant du DML).
**Quand ne pas l'utiliser** : jamais de contre-indication identifiée — c'est le squelette de base
de toute fonction `SECURITY DEFINER` déclenchée par trigger dans ce dépôt.

### Pattern « trigger inconditionnel » (aucun garde de rôle)
**Précédent LIVE** : `prevent_staff_removal_with_future_bookings`
(`20260623240000_bookings_schema.sql:87,103-106`) — en production avant cette fondation.
**Repris pour** : le trigger invariant 7 (DEC-006).
**Quand l'utiliser** : pour un **contrôle d'intégrité métier qui doit lier tout rôle**, y compris
`service_role`/tout `BYPASSRLS` — c'est-à-dire chaque fois que le contrôle protège une propriété
du système lui-même (ex. « ce salon est actif »), pas une frontière entre un client et le système.
**Quand ne pas l'utiliser** : quand le contrôle vise justement à distinguer un client d'un
écrivain système autorisé (voir pattern suivant).

### Pattern « trigger avec garde `auth.role() = 'authenticated'` »
**Précédent** : `protect_user_columns` lui-même porte ce garde
(`20260623120000_users_schema_rls_hardening.sql:51`).
**Quand l'utiliser** : pour une **frontière d'autorisation par rôle** — bloquer le client sur des
colonnes que seul `service_role` doit écrire (ex. futur DEC-013,
`protect_conversation_columns`, qui doit laisser passer l'écrivain système des compteurs).
**Quand ne pas l'utiliser** : jamais sur un invariant métier qui doit lier `service_role` lui-même
(le trigger invariant 7 ne doit **jamais** recevoir ce garde).

**INVERSION CRITIQUE, à documenter explicitement pour tout futur lecteur** : le même
`auth.role() = 'authenticated'` est un **poison** dans le premier cas (il exempterait
`service_role` et casserait DEC-007/invariant 9) et **l'outil correct** dans le second cas (il
bloque le client et laisse passer l'écrivain système légitime). La règle n'est donc **pas**
« jamais de `auth.role()` » — c'est : **pas de garde de rôle sur un invariant métier ; garde de
rôle sur une frontière d'autorisation.** Un futur lecteur qui applique mécaniquement « jamais de
`auth.role()` » se trompera et cassera DEC-013 en la rendant inutilisable par le futur trigger de
compteurs.

---

## §7 — Conventions de tests (cycle Rule 8)

Chaque migration suit, sans exception :

1. **Preuves AVANT** — inventaire des dépendances, confirmées `fichier:ligne` et par requête
   directe contre le projet lié (`to_regclass`, `pg_proc`, `pg_roles` selon le besoin).
2. **Écriture** du fichier de migration.
3. **Compilation/push** — `supabase db push --linked` (jamais `supabase config push`, qui ne
   pousse pas de schéma).
4. **Tests** exécutés contre la table **réellement appliquée**, SQLSTATE + message capturés pour
   chaque cas attendu en rejet ; les cas d'acceptation sont vérifiés aussi (une contrainte trop
   stricte est une régression au même titre qu'une contrainte absente).
5. **Rollback vérifié** — ordre inverse rejoué dans un schéma miroir isolé (ne jamais rejouer un
   rollback réel sur la table de production qu'on vient de committer).
6. **Cleanup vérifié à 0** — toute ligne de test insérée directement dans la vraie table de
   production est supprimée, confirmé par un `count(*)` post-nettoyage.
7. **Commit unique** — une migration, une table, un commit.
8. **PORTE** — arrêt, rapport de preuves, attente de validation explicite avant la migration
   suivante.

**Preuve d'application réelle de ce cycle** : Migration 1 (`conversations`), commit `28a269c`,
12/12 tests réels conformes (§3), rollback vérifié dans le schéma miroir
`zz_conv_rollback_check` (supprimé, vérifié à 0), lignes de test supprimées de la vraie table
(`count(*) = 0` post-nettoyage sur `public.conversations`).

---

## §8 — Conventions de commentaires protecteurs

Obligatoires dans le SQL committé, style impératif `DO NOT DROP`/`NEVER` + raison + preuve —
jamais seulement dans la documentation externe. Déjà en place, cités depuis le fichier committé :

- **FK simple** (`...conversations_schema.sql:211-212`) : *"DO NOT DROP. Protects the client_salon
  branch, where the composite FK is a MATCH SIMPLE no-op..."*
- **FK composite** (`:214-215`) : *"Does not replace fk_conversations_related_booking_simple..."*
- **Index `uq_conversations_client_salon`** (`:217-218`) : *"TOTAL uniqueness, deliberate: never
  add AND deleted_at IS NULL..."*
- **Index `uq_conversations_client_staff`** (`:220-221`) : renvoi explicite au commentaire
  précédent, même règle.
- **Fonction du trigger invariant 7** (`:223-224`) : *"NEVER add an auth.role() =
  'authenticated' guard: it would exempt service_role and break invariant 9..."*
- **`chk_staff_type`** (`:226-227`) : *"Makes the composite FK's MATCH SIMPLE no-op on
  client_salon a proven consequence of the schema, not an assumption."*
- **`chk_staff_requires_booking`** (`:229-230`) : *"Invariant 6 ... is inherited from bookings via
  the composite FK, never re-implemented independently here."*

Toute future migration de ce domaine reprend ce style exact : impératif, la raison, la preuve
(test # ou fichier:ligne), jamais une explication de ce que fait le code (déjà lisible), toujours
pourquoi une simplification serait une régression.

---

## §9 — Roadmap officielle

```
Migration 1 (conversations) ✓ — commit 28a269c
        ↓
Revue de conception dédiée — protect_conversation_columns + trigger de compteurs (DEC-013/014/015)
        ↓
Migration 2 (messages) — invariant catégorie 2 (DEC-016), RLS d'appartenance
        ↓
Migration 3 (message_reports)
        ↓
Migration 4 (device_tokens, raccord — table déjà en production depuis 20260717140000,
             cette étape ne fait que le raccordement applicatif, pas une nouvelle table)
        ↓
Audit global du schéma (§10)
        ↓
Edge Functions (create-conversation, send-message-push, ...)
        ↓
Intégration Flutter (lib/features/messaging/)
        ↓
Monitoring
        ↓
Launch
```

**Aucune Edge Function n'est écrite avant la validation de l'audit global (§10).**

---

## §10 — Définition de l'audit final

**Portée, à l'échelle actuelle du projet (pré-lancement, quelques utilisateurs réels)** :
- Couverture RLS : chaque table a `ENABLE ROW LEVEL SECURITY` et au moins une policy par
  opération pertinente ; aucune table exposée par défaut sans policy explicite.
- Complétude des contraintes : chaque invariant métier identifié a un mécanisme réel (§4), aucune
  case du tableau « qui garantit quoi » laissée vide pour un invariant recensé.
- `search_path` : chaque fonction `SECURITY DEFINER` du domaine messagerie a
  `SET search_path = public, pg_temp` (ou équivalent qualifié).
- `SECURITY DEFINER` : usage justifié au cas par cas (accès à des lignes hors de ce que la RLS de
  l'appelant garantirait), jamais par défaut.
- `REVOKE`/permissions : toute fonction de trigger a son `EXECUTE` révoqué de
  `authenticated, anon, public` ; aucun `GRANT` superflu.
- Couverture `BYPASSRLS` : chaque invariant métier critique est prouvé sous `service_role` en plus
  du rôle normal (comme DEC-006/007 l'ont été).
- Cohérence des triggers : aucun conflit d'ordre de déclenchement entre deux triggers sur la même
  table (voir le gap DEC-013/014 explicitement non résolu ci-dessous — c'est exactement ce que cet
  audit devra clore avant Migration 3).
- Nommage : conformité à §1/DEC-012 et aux conventions préexistantes du dépôt.

**Explicitement DIFFÉRÉ, pas un livrable de cette fondation** : toute section performance
(`EXPLAIN ANALYZE`, détection d'index morts/inutilisés, analyse de cardinalité). Sur des tables
quasi vides pré-lancement, cet exercice produit du bruit statistique, pas un signal exploitable —
le produire maintenant serait une optimisation prématurée, explicitement écartée par calibrage
d'échelle. Il est documenté ici comme **« à exécuter à l'échelle réelle »**, une fois des données
de production significatives accumulées, pas comme un critère de validation de cette fondation.

---

## Partition de statut

### LOCKED
DEC-001 à DEC-012 (§1/§2) — prouvées, appliquées en Migration 1, committées (`28a269c`).

### TO-DESIGN (à concevoir avant la Migration 2 — aucun SQL dans ce tour)

**DEC-013 — `protect_conversation_columns`.**
- Doit porter un garde `auth.role() = 'authenticated'` (pattern §6, cas « frontière
  d'autorisation ») : bloque le client sur les colonnes réservées, laisse passer l'écrivain
  système (`service_role`).
- Partition des colonnes déjà arrêtée comme cadre de la revue :
  - **Réservées système** (mutables uniquement par `service_role`) : `client_unread_count`,
    `salon_unread_count`, `last_message_at`, `last_message_preview`.
  - **Écrivables par chaque partie sur son propre côté, jamais sur celui de l'autre** :
    `client_pinned`/`client_archived`/`client_hidden_at`/`client_deleted_at` (et symétrique
    `salon_*`).
  - **`blocked_by`/`blocked_at` (DEC-015) : NON TRANCHÉ.** À confirmer contre le doc canonique
    `docs/KYNZA_MESSAGING_ARCHITECTURE.md` §5.2 (règle de blocage) avant de figer. Marqué
    `À CONFIRMER` — ne pas inventer la règle dans la revue de conception sans revérifier ce
    document.

**DEC-014 — Trigger de compteurs (`*_unread_count`, `last_message_*`).**
- Contrainte d'interaction explicite : DEC-013 (`BEFORE UPDATE`) et ce trigger doivent coexister
  sans se contredire ni dépendre d'un ordre de déclenchement fragile. Risque identifié et **non
  résolu** dans ce document : si DEC-013 gèle inconditionnellement `last_message_at`/les compteurs
  pour toute mise à jour non `service_role`, et que le trigger de compteurs écrit ces mêmes
  colonnes via une commande interne, l'ordre des triggers `BEFORE UPDATE` sur la même table
  devient significatif — objet exprès de la revue de conception dédiée, pas de ce document.

**DEC-016 — Invariant catégorie 2 (Migration 2, `messages`).**
Un message n'est insérable dans un fil `client_staff` que si le booking lié est actif — lu à la
volée en RLS : `status NOT IN ('cancelled','no_show')` (idiome déjà présent dans
`20260623240000_bookings_schema.sql`, ex. ligne 95). Aucune colonne d'état dupliquée sur
`messages`/`conversations`, aucun trigger sur `bookings`.

### OUT-OF-SCOPE (documenté, non traité en V1)

| Élément | Raison de report |
|---|---|
| Catégorie 3 — diffusion salon→N (`broadcast_campaigns`/`broadcast_recipients`) | Mandat moteur marketing séparé — `MarketingRepository` n'a aujourd'hui aucune méthode d'envoi (`docs/KYNZA_MESSAGING_ARCHITECTURE.md:498-507`) |
| `gift_cards`, attachement `gift_card` | Produit financier absent (achat, solde, expiration, remboursement) — pas une simple table manquante (`docs/KYNZA_MESSAGING_ARCHITECTURE.md:482-496`) |
| Attachement `coupon` | Exige une entité d'assignation par destinataire non existante — même piège que la carte cadeau, en plus petit (`docs/KYNZA_MESSAGING_ARCHITECTURE.md:857`) |
| `conversation_requests` (contact pré-réservation, "salon répond à une demande") | Aucune entité de demande/inquiry n'existe dans le dépôt actuel — mandat produit futur, priorité haute mais non défini au niveau modèle de données (`docs/KYNZA_MESSAGING_ARCHITECTURE.md:604-617`) |

### OPEN (dette tracée, non bloquante pour ce verrouillage)

**DEC-021 — Gap RLS Migration 1.** Policies `UPDATE` sans restriction de colonnes
(`...conversations_schema.sql:200-205`). Ne contredit aucune décision `LOCKED` — fermeture prévue
par DEC-013, avant Migration 2. Voir §1/DEC-021 et ledger §2.

---

## Points spécifiques à ne pas perdre

- **Ticket RGPD** (DEC-010) : `public.users.id → auth.users(id) ON DELETE CASCADE`
  (`20260622182007_foundation.sql:37`). Toute conversation existante bloquera le hard-delete d'un
  compte tant qu'elle n'est pas purgée. Le futur flux d'effacement RGPD doit purger
  `conversations` puis `messages` **avant** le compte `auth.users`. Inscrit au ledger (§2) comme
  décision LOCKED avec statut « ticket ouvert ».
- **Migration 2 — éligibilité dérivée catégorie 2** : voir DEC-016 ci-dessus.
- **Gap RLS de Migration 1** : les policies `UPDATE` actuelles
  (`conversations_client_update_own_state`/`conversations_staff_update_own_state`,
  `...conversations_schema.sql:200-205`) ne restreignent aucune colonne — c'est précisément ce que
  DEC-013 (TO-DESIGN) fermera. Inscrit au ledger comme **DEC-021, statut `OPEN`**, dette de
  sécurité reliée à DEC-013, pas comme un défaut de Migration 1 en soi (Migration 1 a implémenté
  exactement son périmètre verrouillé, ce gap était signalé dès son commit).

---

## Règle de gouvernance permanente

Toute nouvelle décision d'architecture prise lors d'une migration future met à jour ce document
(§1 + ledger §2) **dans le même commit** que la migration concernée. Ce document est la référence
unique pour Claude Code et pour un futur développeur humain travaillant sur la messagerie KYNZA :
aucune de ces revues ne doit être rejouée depuis zéro pour une nouvelle fonctionnalité déjà
couverte ici — on lit l'ADR, on ne redébat pas une décision `LOCKED`.

---

## Verrouillage — audit final pré-verrouillage (2026-07-21)

Audit de falsification (22 vérifications : complétude vs dépôt, intégrité des preuves, cohérence
des statuts, ledger, invariants/contradictions, périmètre de verrouillage, autoportance) mené
contre le dépôt réel : migration `20260721160000_conversations_schema.sql`, les 5 fichiers de
précédent cités (`20260623120000_users_schema_rls_hardening.sql`,
`20260623240000_bookings_schema.sql`, `20260624060000_notifications_schema.sql`,
`20260717140000_device_tokens.sql`, `20260622182007_foundation.sql`), `20260630110100_phase4_maintenance.sql`,
et `docs/KYNZA_MESSAGING_ARCHITECTURE.md`.

**Résultat** : toutes les citations `fichier:ligne` vérifiées exactes (contenu réel à la ligne
citée conforme à ce que l'ADR affirme) ; tous les SQLSTATE cités sont sémantiquement corrects pour
le type de contrainte concerné et les noms de contrainte/index cités dans les messages d'erreur
correspondent exactement aux objets réellement committés ; DEC-012 (« zéro précédent de FK simple
nommée ») re-vérifié par recherche exhaustive du dépôt — confirmé, `CONSTRAINT fk_` n'apparaît nulle
part ailleurs dans `supabase/migrations/`. Aucune décision `LOCKED` trouvée fausse ou non prouvée.
Aucun `TO-DESIGN` trouvé déjà tranché ailleurs dans le dépôt (aucune migration postérieure au
21/07 n'existe). Aucune contradiction non expliquée entre ADR / Migration 1 / doc canonique — les
écarts entre le schéma esquissé en `docs/KYNZA_MESSAGING_ARCHITECTURE.md` §5.2 (FK unique, CHECK
unidirectionnelle, pas de trigger invariant 7) et le schéma réellement appliqué sont chacun
justifiés explicitement dans §1 (DEC-001 à DEC-006), pas un oubli.

**Corrections cléricales appliquées** :
1. **DEC-021 créée** (§1 + ledger §2 + `Partition de statut` + `Points spécifiques`) pour le gap
   RLS de Migration 1, qui n'avait qu'une mention narrative — statut `OPEN`, preuve
   `...conversations_schema.sql:200-205`, relié à DEC-013.
2. **DEC-011 corrigée** : « les 6 `COMMENT ON` » → « les 7 `COMMENT ON` » (compte réel vérifié par
   recherche exhaustive du fichier : 7 blocs `COMMENT ON`, lignes 211-230).
3. **Note GRANT différée** (`Notes ouvertes`) : déjà consignée depuis le commit `7c4f65e` — aucune
   action nécessaire, présence confirmée.
4. Aucun numéro de ligne périmé trouvé au-delà du point 2 — toutes les autres citations
   `fichier:ligne` du document correspondent exactement au contenu réel à ce tour.

**Résidu explicitement non re-vérifié dans cet audit** : les sondages en direct contre le projet
lié (`pg_constraint.confmatchtype='s'` pour DEC-003, `pg_roles.rolbypassrls` pour DEC-007) et
l'exécution effective des 12 tests (T1–T9, T6a/T6b, T-inv4, T-inv8) n'ont pas été rejoués dans cette
session (aucun accès direct à la base liée disponible ici). DEC-003 reste toutefois corroborée
indépendamment par le DDL lui-même : la FK composite (`...conversations_schema.sql:149-151`) ne
porte aucune clause `MATCH`, donc MATCH SIMPLE par défaut Postgres, sans besoin de sondage — la
preuve citée (sondage live) est donc surabondante, pas manquante. Les SQLSTATE/messages
d'erreur/noms de contrainte cités sont, eux, intégralement cohérents avec les objets réellement
committés (voir ci-dessus), ce qui corrobore fortement une exécution réelle sans la prouver de
façon indépendante dans cette session.

Aucun problème bloquant ni majeur trouvé. Le résidu est purement clérical (voir corrections
ci-dessus). **VERDICT : LOCK APPROVED.**
