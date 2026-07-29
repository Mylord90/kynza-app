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

## Convention — Statuts backend (documentaire, aucun DEC)

Cette convention verrouille le sens de chaque statut employé dans ce document et dans
`MESSAGING_API_CONTRACT.md`, pour empêcher qu'un futur lot n'emploie `SHIPPED` pour désigner du code
simplement écrit ou committé. Purement documentaire — ne crée, ne modifie, ne rouvre aucun DEC.

- **DRAFT** : code écrit, non revu, potentiellement incomplet.
- **MERGED** (ou "committé") : le code existe dans l'historique Git (`git log -- <chemin>` retourne au
  moins un commit) sur la branche de référence — ne garantit ni exécution ni accessibilité en
  production.
- **DEPLOYED** : en plus d'être `MERGED`, le code est actif sur l'infrastructure cible et invocable —
  pour une Edge Function, présente dans `supabase functions list` avec `status: ACTIVE` ; pour une
  migration SQL, présente dans `supabase migration list --linked` avec un timestamp distant identique
  au local.
- **SHIPPED** : réservé aux éléments à la fois `MERGED` **et** `DEPLOYED` **et** dont le comportement a
  été vérifié par une preuve d'exécution réelle (test réel contre production, ou trafic réel observé).

**Règle d'application, contraignante** : aucun document de ce domaine ne doit employer `SHIPPED` sans
que les trois conditions ci-dessus soient simultanément vraies et vérifiables par une commande, jamais
par une déclaration. En cas de doute sur le statut réel d'un élément, le statut le plus bas parmi les
preuves disponibles doit être affiché, jamais le plus favorable.

**Origine** : convention ajoutée après constat réel — `create-conversation` était étiqueté `SHIPPED`
dans `MESSAGING_API_CONTRACT.md` alors qu'il n'était ni committé (`git log --all -- supabase/functions/
create-conversation` vide avant ce commit) ni déployé (absent de `supabase functions list`).

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
| DEC-013 | `protect_conversation_columns` (garde par colonne, 7 catégories, refus par défaut) | **LOCKED, appliqué** | 2026-07-22 (design) / 2026-07-23 (implémenté, Migration 1.5) | Migration 1.5 (`20260723120000_conversations_hardening_1_5.sql`) | §"Revue de finalisation" §A ; preuve d'exécution `MESSAGING_TRACEABILITY_MATRIX.md:36` |
| DEC-014 | Trigger de compteurs `*_unread_count`/`last_message_*` (`SECURITY DEFINER` + `pg_trigger_depth()`) | **LOCKED, appliqué** | 2026-07-22 (design) / 2026-07-23 (implémenté, Migration 2, commit `d3c1d0f`) | Migration 2 (`20260723180000_messages_schema_migration_2.sql:338-364`) | §"Revue de finalisation" §A.4 ; preuve d'exécution `MESSAGING_TRACEABILITY_MATRIX.md:37` |
| DEC-015 | Règle de blocage (`blocked_by`/`blocked_at`) — autorité actuelle, pas identité figée | **LOCKED** | 2026-07-22 | Migration 1.5 (colonnes) + Edge Function Phase 2 | §"Revue de finalisation" §B/§C |
| DEC-016 | Éligibilité dérivée catégorie 2 (booking actif) | **LOCKED, appliqué** | 2026-07-22 (design) / 2026-07-23 (implémenté, Migration 2, commit `d3c1d0f`) | Migration 2 (`20260723180000_messages_schema_migration_2.sql:144-174`) | §"Revue de finalisation" §B.3 ; preuve d'exécution `MESSAGING_TRACEABILITY_MATRIX.md:39` |
| DEC-022 | Sous-requêtes `staff_id IN (...)` sans filtre `is_active`/`deleted_at` | **OPEN** | 2026-07-22 | Migration 1.5 | §"Revue de finalisation" §D.3 |
| DEC-023 | Aucune policy `UPDATE` owner/manager sur `conversations` | **OPEN** | 2026-07-22 | Migration 1.5 | §"Revue de finalisation" §D.2 |
| DEC-017 | Catégorie 3 (diffusion salon→N), `broadcast_*` | **OUT-OF-SCOPE** | — | mandat marketing séparé | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:466-520` |
| DEC-018 | `gift_cards`, attachement `gift_card` | **OUT-OF-SCOPE** | — | mandat produit financier séparé | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:482-496,856` |
| DEC-019 | Attachement `coupon` | **OUT-OF-SCOPE** | — | différé, cf. §11 doc canonique | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:857` |
| DEC-020 | `conversation_requests` (contact pré-réservation) | **OUT-OF-SCOPE** | — | mandat produit futur, priorité haute | `docs/KYNZA_MESSAGING_ARCHITECTURE.md:604-617` |
| DEC-021 | Gap RLS Migration 1 (policies `UPDATE` sans restriction de colonnes) | **OPEN** (dette sécurité) | 2026-07-21 | Migration 1 (gap) — fermeture avant Migration 2 | `...conversations_schema.sql:200-205` · lié à DEC-013 |
| DEC-024 | Réouverture face à `deleted_at` global — machine d'états `23505`→`UPDATE`→diagnostic, prédicat d'identité invariant — **portée étendue au chemin d'envoi (Lot 1.2)** | **LOCKED (design + amendement)** | 2026-07-28 | Lot 1.1 (`create-conversation`, MERGED, non déployé) + Lot 1.2 (`messages_participant_insert`, SQL en attente) | §"DEC-024 — Conversation administrativement supprimée" + §"Amendement — Extension de portée DEC-024" |

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
DEC-013, DEC-021, DEC-022, DEC-023 sont désormais **`LOCKED`** avec preuve réelle depuis Migration 1.5
(`20260723120000_conversations_hardening_1_5.sql`, 2026-07-23) — voir « Migration 1.5 —
Implémentation et clôture » plus bas dans ce document pour les tests réels, le rollback en schéma
miroir, et les statuts ledger mis à jour. Ils étaient `LOCKED (design)`/`OPEN` depuis le 2026-07-22
(revue de finalisation) ; cette phrase reste comme trace de transition, la source normative des
statuts actuels est la section Migration 1.5. DEC-014/015/016 restent respectivement
`LOCKED (design)`/`LOCKED`/`LOCKED (règle)`, inchangés — leur implémentation SQL reste Migration 2.

### TO-DESIGN — SUPERSEDED 2026-07-22

Cette sous-section est conservée telle quelle comme trace historique de l'état "avant conception" —
elle ne reflète plus le statut actuel. Voir « Revue de finalisation de la fondation — avant
Migration 2 » (fin de document) pour les décisions verrouillées qui la remplacent.

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

### OPEN (dette tracée, non bloquante pour ce verrouillage) — SUPERSEDED 2026-07-23

Cette sous-section est conservée telle quelle comme trace historique de l'état "avant Migration 1.5"
— elle ne reflète plus le statut actuel. DEC-021, DEC-022, DEC-023 sont **`LOCKED` (fermées)** depuis
Migration 1.5 (2026-07-23) — voir « Migration 1.5 — Implémentation et clôture » pour les preuves
réelles qui les remplacent.

**DEC-021 — Gap RLS Migration 1.** Policies `UPDATE` sans restriction de colonnes
(`...conversations_schema.sql:200-205`). Ne contredit aucune décision `LOCKED` — fermeture
**spécifiée** (pas encore implémentée) par DEC-013 depuis le 2026-07-22, voir §1/DEC-021, ledger §2,
et « Revue de finalisation » §A.3.

**DEC-022 — Sous-requêtes `staff_id IN (...)` sans filtre `is_active`/`deleted_at`** (Migration 1 +
brouillons `messages`). Découvert 2026-07-22. Voir « Revue de finalisation » §D.3.

**DEC-023 — Aucune policy `UPDATE` owner/manager sur `conversations`.** Découvert 2026-07-22. Voir
« Revue de finalisation » §D.2.

**Résidu non fermé par Migration 1.5, à traiter séparément avant Migration 2** : l'ajout de
`conversations` à `supabase_realtime` (§D.8, résidu #5) reste `OPEN` — exclu par choix de granularité
(voir en-tête de `20260723120000_conversations_hardening_1_5.sql`), ce n'est pas une `DEC`.

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

---

## Addendum post-lock — non normatif, traçabilité (revue du 2026-07-21)

Cet addendum est additif et ne modifie aucune décision, aucun statut, aucune preuve du corps
verrouillé ci-dessus (§1–§10, ledger §2). Il documente la provenance de chaque preuve et referme,
par re-sondage live contre le projet lié (`hhdkjfpgaklhrhfoxlhj`, rôle `postgres`, requêtes en
lecture seule ou transactions explicitement terminées par `ROLLBACK`, zéro ligne persistée —
`conversations` vérifiée à 0 avant et après), l'unique résidu de vérification laissé ouvert par le
rapport de verrouillage ci-dessus.

### Matrice de provenance des preuves

Légende : (a) test exécuté à la Migration 1 (`28a269c`) ; (b) test isolé rejoué à la finalisation
(`7c4f65e`) ; (c) sondage PostgreSQL live ; (d) lecture directe du DDL/dépôt committé ; (e)
précédent du dépôt appliqué ; (f) démonstration logique sans test.

| DEC | Preuve citée | Provenance | Rejouée au LOCK (`a6e3aee`) ? | Résidu de re-vérification |
|---|---|---|---|---|
| DEC-001 | `:147-148,211-212` · test T5 (`23503`) · précédent `notification_logs` | (a)+(d)+(e) | Non | Non — corroborable par lecture directe du DDL |
| DEC-002 | `:149-151,214-215` · tests T4/T9 | (a)+(d) | Non | Non — corroborable par DDL |
| DEC-003 | `pg_constraint.confmatchtype='s'` (sondage scratch) | (c)+(d) | Non | Non — **re-sondée live 2026-07-21** : `confmatchtype='s'` reconfirmé sur les deux FK (`fk_conversations_related_booking_simple`/`_composite`) ; corroborable en plus par l'absence de clause `MATCH` dans le DDL |
| DEC-004 | `:140-143,226-227` · tests T1/T2 (`23514`) | (a)+(d) | Non | Non — corroborable par DDL (CHECK biconditionnelle lisible telle quelle) |
| DEC-005 | `:144-146,229-230` · test T3 (`23514`) | (a)+(d) | Non | Non — corroborable par DDL |
| DEC-006 | `:165-179,223-224` · tests T6a/T6b (`P0001`) · précédent | (a)+(d)+(e) | Non | Non — **re-sondée live 2026-07-21** : `INSERT` sous `SET ROLE service_role` contre le salon soft-deleted réel `27db89d3-4590-4c4c-be45-b6dad01706a8` (toujours `deleted_at IS NOT NULL`) → `P0001`, message identique caractère pour caractère à celui cité ; transaction terminée sans persistance |
| DEC-007 | `pg_roles.rolbypassrls` · test T6b | (a)+(c) | Non | Non — **re-sondée live 2026-07-21** : `rolbypassrls=true` reconfirmé pour `postgres` et `service_role`, `false` pour `authenticated`/`anon` ; comportement T6b rejoué (voir DEC-006) |
| DEC-008 | `:106-107` | (d)+(f) | N/A (démonstration logique) | Non — preuve mathématique (sur-ensemble d'une PK), pas une exécution à rejouer |
| DEC-009 | `:154-157,217-221` · tests T7/T8 (`23505`) | (a)+(d) | Non | Non — **re-sondée live 2026-07-21** : `23505` reconfirmé sur les DEUX index — `uq_conversations_client_salon` (paire `salon_id`/`client_id` dupliquée) ET `uq_conversations_client_staff` (paire `staff_id`/`client_id` dupliquée, avec un booking réel satisfaisant la FK composite) ; transactions terminées sans persistance |
| DEC-010 | `:68-78,114-117,133,147-151` · `foundation.sql:37` | (d)+(e) | N/A | Non — absence de clause `ON DELETE`/`ON UPDATE` vérifiable par lecture |
| DEC-011 | `:211-230` (7 `COMMENT ON`) | (d) | N/A | Non — comptage vérifiable par lecture/recherche textuelle |
| DEC-012 | `:80-87` · précédents · recherche repo-wide | (d)+(e) | Non — mais **re-vérifiée par recherche textuelle 2026-07-21** (`CONSTRAINT fk_` : zéro autre résultat dans `supabase/migrations/`) | Non |
| DEC-013 | — (TO-DESIGN, non implémentée) | n/a | n/a | n/a — aucune preuve à rejouer, décision non prise |
| DEC-014 | — (TO-DESIGN, non implémentée) | n/a | n/a | n/a |
| DEC-015 | doc canonique §5.2 (non tranché) | (d) partielle — le doc canonique ne tranche pas la règle | n/a | n/a — statut `À CONFIRMER` correct en l'état |
| DEC-016 | idiome RLS précédent (`bookings_schema.sql:95`) | (e) | n/a (pas encore implémentée) | n/a |
| DEC-017 | doc canonique `:466-520` | (d) | n/a | Non |
| DEC-018 | doc canonique `:482-496,856` | (d) | n/a | Non |
| DEC-019 | doc canonique `:857` | (d) | n/a | Non |
| DEC-020 | doc canonique `:604-617` | (d) | n/a | Non |
| DEC-021 | `:200-205` (absence de restriction de colonnes) | (d) — preuve par absence | n/a (créée au lock, aucun test requis) | Non |

### Re-sondage — méthode et requêtes

Exécuté via `supabase db query --linked` (API de gestion, rôle `postgres`), aucune requête
destructive, chaque `INSERT` de test dans une transaction explicitement close par `ROLLBACK` (ou
avortée server-side par l'erreur attendue, ce qui a le même effet — aucune commande `COMMIT`
n'a été émise). `SELECT count(*) FROM public.conversations` confirmé à `0` avant le premier test
et après le dernier.

1. **DEC-003** : `SELECT conname, confmatchtype FROM pg_constraint WHERE conname LIKE
   'fk_conversations_related_booking%'` → `s` pour les deux contraintes.
2. **DEC-007** (sondage) : `SELECT rolname, rolbypassrls FROM pg_roles WHERE rolname IN
   ('service_role','postgres','authenticated','anon')` → `true`/`true`/`false`/`false`.
3. **DEC-006/007** (comportement) : `BEGIN; SET ROLE service_role; INSERT INTO
   public.conversations (salon_id, type, client_id) VALUES
   ('27db89d3-4590-4c4c-be45-b6dad01706a8', 'client_salon', <client réel>); ROLLBACK;` →
   `P0001: conversations.salon_id 27db89d3-4590-4c4c-be45-b6dad01706a8 is soft-deleted (invariant
   7): cannot open a conversation against an inactive salon`.
4. **DEC-009** (`uq_conversations_client_salon`) : deux `INSERT` identiques (même `salon_id`/
   `client_id`, `type='client_salon'`) dans une transaction → 2ᵉ rejeté, `23505`,
   `duplicate key value violates unique constraint "uq_conversations_client_salon"`.
5. **DEC-009** (`uq_conversations_client_staff`) : deux `INSERT` identiques référençant un booking
   réel existant (satisfaisant la FK composite DEC-002) dans une transaction → 2ᵉ rejeté, `23505`,
   `duplicate key value violates unique constraint "uq_conversations_client_staff"`.

### Conclusion de l'addendum

Les 4 décisions dont la preuve reposait sur un sondage/test de Migration 1 non rejoué au commit de
verrouillage (`a6e3aee`) — DEC-003, DEC-006, DEC-007, DEC-009 — sont désormais corroborées par une
exécution live indépendante, datée de cette revue, en plus de leur preuve d'origine. Aucune
divergence trouvée entre le comportement attendu (cité dans le corps verrouillé) et le comportement
observé. Aucune décision `LOCKED` n'est affectée ; cet addendum ne re-verrouille rien et n'ouvre
aucune nouvelle décision.

---

# Revue de finalisation de la fondation — avant Migration 2 (2026-07-22)

**Portée de cette revue** : fermer les deux bloquants signalés (`protect_conversation_columns`
incomplet, rotation des managers), traiter les 3 points fortement recommandés, finaliser DEC-015,
mener une revue de sécurité et une revue d'architecture volontairement hostiles ("casser son propre
design"), verrouiller DEC-013 à DEC-016, produire la checklist/matrice/DoD, et poser la feuille de
route à 5 phases. **Aucun SQL n'est appliqué dans cette revue** — toute contrainte/trigger/policy
ci-dessous est une **spécification verrouillée**, à implémenter dans la prochaine migration
(`Migration 1.5 — conversations hardening`, avant `Migration 2 — messages`, voir §J). Rien dans
cette section ne modifie une ligne du corps verrouillé ci-dessus (DEC-001 à DEC-012, DEC-021) — les
citations `fichier:ligne` de Migration 1 restent la référence factuelle ; cette section ajoute des
décisions nouvelles ou finalise des décisions déjà `TO-DESIGN`/`OPEN`.

## A — BLOQUANT 1 : partition exhaustive de `protect_conversation_columns`

### A.1 — Inventaire complet, preuve de complétude

`public.conversations` a **23 colonnes** (compte vérifié par lecture exhaustive de
`20260721160000_conversations_schema.sql:112-152`, la seule migration qui définit cette table).
Voici les 23, chacune assignée à **exactement une** des 7 catégories ci-dessous — aucune omise,
aucune dans deux catégories à la fois (vérifié par construction : chaque colonne n'apparaît qu'une
fois dans le tableau) :

| # | Colonne | Catégorie | Qui peut écrire |
|---|---|---|---|
| 1 | `id` | **A — IDENTITY_IMMUTABLE** | Personne (post-INSERT) |
| 2 | `salon_id` | A | Personne |
| 3 | `type` | A | Personne |
| 4 | `client_id` | A | Personne |
| 5 | `staff_id` | A | Personne |
| 6 | `related_booking_id` | A | Personne |
| 7 | `created_at` | A | Personne |
| 8 | `last_message_at` | **B — SYSTEM_COUNTERS** | Triggers système uniquement (imbriqué) ou `service_role` |
| 9 | `last_message_preview` | B | idem |
| 10 | `client_unread_count` | B | idem |
| 11 | `salon_unread_count` | B | idem |
| 12 | `client_pinned` | **C — CLIENT_OWN_SIDE** | Le client (`auth.uid() = client_id`) ou `service_role` |
| 13 | `client_archived` | C | idem |
| 14 | `client_deleted_at` | C | idem |
| 15 | `client_hidden_at` | **C' — CLIENT_HIDDEN (double écrivain)** | Le client, **ou** le trigger système (démasquage auto à l'arrivée d'un message) |
| 16 | `salon_pinned` | **D — SALON_OWN_SIDE** | Staff assigné actif, ou owner/manager du salon, ou `service_role` |
| 17 | `salon_archived` | D | idem |
| 18 | `salon_deleted_at` | D | idem |
| 19 | `salon_hidden_at` | **D' — SALON_HIDDEN (double écrivain)** | Staff/owner/manager, **ou** le trigger système (démasquage auto) |
| 20 | `blocked_by` | **E — BLOCK_STATE** | `service_role` uniquement (Edge Function `toggle-conversation-block`, voir DEC-015 §C) |
| 21 | `blocked_at` | E | idem |
| 22 | `deleted_at` | **F — ADMIN_GLOBAL** | `service_role` uniquement (futur flux RGPD/admin) |
| 23 | `updated_at` | **G — DÉLÉGUÉE** | Le trigger `conversations_updated_at` déjà en production (`...conversations_schema.sql:181-182`) — non réévalué ici |

**23/23 colonnes couvertes.** Aucune colonne "hors catégorie" n'existe dans ce tableau par
construction — c'est la preuve de complétude demandée : la liste ci-dessus a été obtenue par lecture
ligne à ligne du `CREATE TABLE` réel (`:112-152`), pas par mémoire ou supposition.

### A.2 — Pourquoi le brouillon existant (`KYNZA_MESSAGING_ARCHITECTURE.md:207-234`) est insuffisant

Le brouillon non verrouillé gèle `salon_*`/`client_*` par un simple `IF auth.uid() = OLD.client_id
THEN ... ELSE ...` (implicite : "pas le client ⇒ forcément le salon", jamais vérifié) et gèle
`blocked_by`/`blocked_at`/les compteurs **inconditionnellement**, ce qui les rend
**définitivement non modifiables par quiconque**, y compris `service_role` — un bug qui aurait
empêché toute future Edge Function de bloquer/débloquer ou de mettre à jour les compteurs. C'est
exactement le gap nommé mais non résolu dans `...conversations_schema.sql:89-96` ("SCOPE GAP,
FLAGGED NOT RESOLVED"). La Partie B.2 ci-dessous traite la racine de ce problème (ELSE implicite) ;
cette section en tire la conséquence structurelle : chaque catégorie doit avoir une condition
**positive et vérifiée**, jamais une condition par exclusion.

### A.3 — Mécanisme retenu : refus par défaut + garde-fou anti-dérive

**Design verrouillé** (spec, à implémenter en Migration 1.5) : pour chaque catégorie, une condition
positive explicite ; à la fin, un **filet de sécurité générique** qui diffe `NEW`/`OLD` via
`to_jsonb()` et rejette **toute colonne modifiée qui n'apparaît dans aucune des listes explicites
ci-dessus** — ceci couvre à la fois (a) toute colonne déjà nommée mais dont la condition positive a
échoué, et (b) toute colonne **future** ajoutée par une migration ultérieure sans que quiconque
n'ait mis à jour ce trigger.

**SUPERSEDED sur un point précis (2026-07-23)** : la ligne `is_system` du brouillon ci-dessous
(`auth.role() <> 'authenticated'`) a été testée pendant l'implémentation réelle de Migration 1.5 et
s'est révélée silencieusement permissive sous tout contexte sans JWT (`NULL <> 'authenticated'` vaut
`NULL`, traité comme `false` par `IF`). La version réellement committée utilise
`COALESCE(auth.role() <> 'authenticated', true)` — voir ADR, section « Migration 1.5 —
Implémentation et clôture » puis « Découverte critique pendant l'audit adversarial » pour le
raisonnement complet, y compris une seconde tentative (`current_user`) elle aussi testée et rejetée.
Le reste du brouillon ci-dessous (les 7 catégories, le filet anti-dérive) a été implémenté tel quel,
sans autre écart.

```sql
CREATE OR REPLACE FUNCTION public.protect_conversation_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  is_client     BOOLEAN := auth.uid() = OLD.client_id;
  is_salon_side BOOLEAN := EXISTS (
                    SELECT 1 FROM public.staff_profiles sp
                    WHERE sp.id = OLD.staff_id AND sp.user_id = auth.uid()
                      AND sp.is_active = true AND sp.deleted_at IS NULL
                  )
                  OR public.has_role(auth.uid(), 'owner', OLD.salon_id)
                  OR public.has_role(auth.uid(), 'manager', OLD.salon_id);
  nested        BOOLEAN := pg_trigger_depth() > 1;      -- voir DEC-014, §A.4
  is_system     BOOLEAN := auth.role() <> 'authenticated'; -- service_role / postgres
  drift_keys    TEXT[];
BEGIN
  -- A — IDENTITY_IMMUTABLE : invariant, aucune exception de rôle (comme le trigger invariant 7 / DEC-006).
  IF NEW.id IS DISTINCT FROM OLD.id OR NEW.salon_id IS DISTINCT FROM OLD.salon_id
     OR NEW.type IS DISTINCT FROM OLD.type OR NEW.client_id IS DISTINCT FROM OLD.client_id
     OR NEW.staff_id IS DISTINCT FROM OLD.staff_id
     OR NEW.related_booking_id IS DISTINCT FROM OLD.related_booking_id
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'conversations: identity columns are immutable (id/salon_id/type/client_id/staff_id/related_booking_id/created_at)';
  END IF;

  -- B — SYSTEM_COUNTERS : seul un trigger imbriqué (bump/reset, tout rôle) ou service_role écrit.
  IF (NEW.last_message_at IS DISTINCT FROM OLD.last_message_at
      OR NEW.last_message_preview IS DISTINCT FROM OLD.last_message_preview
      OR NEW.client_unread_count IS DISTINCT FROM OLD.client_unread_count
      OR NEW.salon_unread_count IS DISTINCT FROM OLD.salon_unread_count)
     AND NOT (nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: last_message_*/*_unread_count are system-managed only';
  END IF;

  -- E — BLOCK_STATE : service_role uniquement (jamais un UPDATE authenticated direct — DEC-015).
  IF (NEW.blocked_by IS DISTINCT FROM OLD.blocked_by OR NEW.blocked_at IS DISTINCT FROM OLD.blocked_at)
     AND NOT is_system THEN
    RAISE EXCEPTION 'conversations: blocked_by/blocked_at are writable only via toggle-conversation-block (service_role)';
  END IF;

  -- F — ADMIN_GLOBAL : service_role uniquement (futur flux RGPD/admin).
  IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at AND NOT is_system THEN
    RAISE EXCEPTION 'conversations: deleted_at (global) is writable only by an administrative/GDPR flow';
  END IF;

  -- C / C' — CLIENT_OWN_SIDE.
  IF (NEW.client_pinned IS DISTINCT FROM OLD.client_pinned
      OR NEW.client_archived IS DISTINCT FROM OLD.client_archived
      OR NEW.client_deleted_at IS DISTINCT FROM OLD.client_deleted_at)
     AND NOT (is_client OR is_system) THEN
    RAISE EXCEPTION 'conversations: client_pinned/client_archived/client_deleted_at are client-only';
  END IF;
  IF NEW.client_hidden_at IS DISTINCT FROM OLD.client_hidden_at
     AND NOT (is_client OR nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: client_hidden_at is client-only or system auto-unhide';
  END IF;

  -- D / D' — SALON_OWN_SIDE.
  IF (NEW.salon_pinned IS DISTINCT FROM OLD.salon_pinned
      OR NEW.salon_archived IS DISTINCT FROM OLD.salon_archived
      OR NEW.salon_deleted_at IS DISTINCT FROM OLD.salon_deleted_at)
     AND NOT (is_salon_side OR is_system) THEN
    RAISE EXCEPTION 'conversations: salon_pinned/salon_archived/salon_deleted_at require current salon-side authority';
  END IF;
  IF NEW.salon_hidden_at IS DISTINCT FROM OLD.salon_hidden_at
     AND NOT (is_salon_side OR nested OR is_system) THEN
    RAISE EXCEPTION 'conversations: salon_hidden_at requires current salon-side authority or system auto-unhide';
  END IF;

  -- Filet de sécurité anti-dérive : toute colonne modifiée hors de la liste connue (y compris une
  -- colonne future ajoutée par une migration qui aurait oublié de mettre à jour ce trigger) échoue
  -- bruyamment au lieu d'être silencieusement autorisée. C'est le mécanisme "refus par défaut".
  SELECT array_agg(n.key) INTO drift_keys
  FROM jsonb_each(to_jsonb(NEW)) n JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
  WHERE n.value IS DISTINCT FROM o.value
    AND n.key NOT IN (
      'id','salon_id','type','client_id','staff_id','related_booking_id','created_at',
      'last_message_at','last_message_preview','client_unread_count','salon_unread_count',
      'blocked_by','blocked_at','deleted_at',
      'client_pinned','client_archived','client_deleted_at','client_hidden_at',
      'salon_pinned','salon_archived','salon_deleted_at','salon_hidden_at',
      'updated_at'
    );
  IF drift_keys IS NOT NULL THEN
    RAISE EXCEPTION 'protect_conversation_columns: uncategorized column(s) % changed — this is schema drift, categorize before allowing this write', drift_keys;
  END IF;

  RETURN NEW;
END; $$;

REVOKE EXECUTE ON FUNCTION public.protect_conversation_columns() FROM authenticated, anon, public;
CREATE TRIGGER trg_protect_conversation_columns BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.protect_conversation_columns();
```

**Pourquoi une future migration ne peut pas créer de colonne orpheline** : le filet `to_jsonb` diffe
dynamiquement *toutes* les colonnes réelles de la table, pas une liste figée de noms attendus. Une
colonne ajoutée par `ALTER TABLE conversations ADD COLUMN foo ...` et jamais catégorisée devient
**immuable par défaut** (aucune branche positive ne la couvre) et, à la première tentative d'écriture
par quiconque, déclenche `RAISE EXCEPTION` avec le nom de la colonne en clair — jamais un passage
silencieux. C'est un échec bruyant en production au pire, jamais une brèche silencieuse.

**Garde-fou persistant complémentaire (statique, avant même une écriture réelle)** : un test dédié
(`T-cols`, voir DoD/checklist) compare `information_schema.columns` de `conversations` à une liste
figée maintenue dans le test lui-même. Toute colonne ajoutée fait échouer `T-cols` en revue/CI,
**avant** qu'une écriture réelle ne déclenche le filet ci-dessus — les deux mécanismes sont
volontairement redondants (le test attrape la dérive tôt ; le trigger l'attrape même si le test a
été oublié).

### A.4 — Pourquoi `pg_trigger_depth()` et pas seulement `auth.role()`

C'est la résolution de la note "non résolue" de `...conversations_schema.sql:89-96` et du ledger
(DEC-013/DEC-014, interaction). `auth.role()` reflète le JWT de la requête HTTP, **pas** qui exécute
concrètement l'`UPDATE` en cours : quand un client authentifié fait `INSERT INTO messages`, le
trigger `trg_bump_conversation_on_message` (Migration 2, `AFTER INSERT`) exécute lui-même un
`UPDATE conversations ...` — et `auth.role()` retourne toujours `'authenticated'` à ce moment (même
transaction, même JWT), pas `'service_role'`. Un garde `auth.role() = 'authenticated'` seul
**rejetterait donc la propre écriture légitime du trigger de compteurs** (exactement l'effondrement
prédit dans `:93-96`).

`pg_trigger_depth()` résout ceci en distinguant l'exécution par **profondeur d'appel**, pas par
identité de rôle : `0` hors de tout trigger, `1` quand l'`UPDATE` est le déclencheur direct d'un
trigger (cas d'un `UPDATE` client direct sur `conversations`), `≥2` quand cet `UPDATE` a lui-même été
émis **depuis l'intérieur** d'un autre trigger (le cas du bump, émis depuis
`trg_bump_conversation_on_message`, lui-même à la profondeur 1 sur `messages`). Cette valeur est une
propriété du moteur d'exécution — **non falsifiable côté client**, aucune requête SQL ne peut la
manipuler directement.

Les deux gardes sont donc complémentaires, pas redondants :
- `auth.role() <> 'authenticated'` isole les appels `service_role` — un contexte de credential
  **différent** (clé service, jamais le JWT utilisateur), utilisé par les Edge Functions.
- `pg_trigger_depth() > 1` isole les écritures **internes au même contexte de requête** qu'un client
  authentifié a légitimement déclenchées (le bump), sans exempter un `UPDATE` direct que ce même
  client tenterait d'exécuter lui-même sur les mêmes colonnes.

**Conséquence pour DEC-014** : `bump_conversation_on_message`/`reset_unread_on_read` doivent être
`SECURITY DEFINER` (comme `check_conversation_salon_active`, pattern §6) — pas pour contourner
`protect_conversation_columns` (qui les laisse déjà passer via `pg_trigger_depth()`), mais pour
contourner le **gap RLS D.2** ci-dessous (owner/manager n'ont aujourd'hui aucune policy `UPDATE` sur
`conversations`, donc un message envoyé par un owner/manager sur `client_salon` ferait échouer le
bump trigger sous RLS invoker).

**Ordre de déclenchement vérifié, aucun conflit** : `conversations` porte déjà `conversations_updated_at`
(`...conversations_schema.sql:181-182`) en plus du futur `trg_protect_conversation_columns`, deux
triggers `BEFORE UPDATE`. Postgres déclenche les triggers du même événement par ordre alphabétique de
nom : `conversations_updated_at` (préfixe `c`) précède `trg_protect_conversation_columns` (préfixe
`t`) — `updated_at` est donc déjà positionné à `NOW()` par le premier avant que le second ne s'exécute,
et le second ne touche jamais `updated_at` (Catégorie G, déléguée, explicitement exclue de la liste
diffée). Aucune dépendance d'ordre fragile.

---

## B — BLOQUANT 2 : rotation des managers

### B.1 — Démonstration du problème

Le modèle naïf envisagé ("seul `blocked_by = auth.uid()` peut débloquer") lie l'autorité de
déblocage à une **identité figée au moment du blocage**, pas à une **autorité actuelle**. Scénarios
concrets où ce modèle casse :

1. **Départ du manager bloqueur** : manager M bloque une conversation `client_staff`, puis quitte le
   salon (rôle réassigné hors `manager`/`owner` dans `public.users.role`, ou compte soft-supprimé —
   `deleted_at`). `has_role(M, 'manager', salon_id)` redevient `false` immédiatement (vérifié par
   lecture de `has_role`, `20260623120000_users_schema_rls_hardening.sql:34-43` : la fonction relit
   `users.role`/`users.deleted_at` en direct à chaque appel, jamais un JWT figé). Sous le modèle
   naïf, **aucun** autre manager/owner ne peut lever le blocage : `blocked_by` reste égal à l'UUID de
   M, un utilisateur qui n'a plus aucune autorité sur le salon — blocage définitif, y compris si un
   nouveau manager est embauché le lendemain.
2. **Salon multi-managers, un seul a bloqué** : un second manager, actif, légitime, ne peut pas
   débloquer une conversation qu'il n'a pas personnellement bloquée — la règle naïve punit la
   collaboration, pas seulement le départ.
3. **Rotation du staff assigné** (`client_staff`) : si le blocage était autorisé côté staff assigné
   plutôt que côté manager, le même problème se pose pour `staff_id` — le staff assigné quitte,
   `staff_profiles.is_active` passe à `false`, plus personne ne peut débloquer ce fil précis même si
   l'owner du salon veut réactiver la conversation.
4. **Blocage côté client** : si c'est le client qui bloque (`blocked_by = client_id`), il n'y a **pas**
   de problème de rotation analogue — un client est une personne physique, pas un rôle organisationnel
   tournant ; seul lui doit pouvoir lever son propre blocage (autonomie de l'utilisateur, §C).

### B.2 — Solutions comparées

| Option | Description | Avantages | Inconvénients | Verdict |
|---|---|---|---|---|
| **A — Identité figée** (`blocked_by = auth.uid()`) | Modèle naïf initialement envisagé | Trivial à écrire | Blocage définitif sur départ (§B.1) — inacceptable en SaaS multi-salons avec rotation de personnel | **Rejeté** |
| **B — Autorité actuelle par rôle** | Déblocage autorisé par `has_role()`/staff actif **courant**, pas par égalité d'identité avec `blocked_by` | Aucun schéma supplémentaire (dérive de `blocked_by = client_id` vs. non, déjà présent) ; réutilise `has_role()` déjà éprouvé (DEC pattern existant, aucune nouvelle primitive) ; auto-cicatrisant (un nouveau manager hérite automatiquement de l'autorité) | Nécessite qu'un Edge Function porte la logique d'autorisation (pas exprimable en RLS pure, car dynamique par appelant + doit connaître "quel côté a bloqué") | **Retenu** |
| **C — Double contrôle** (2 managers doivent confirmer) | Dual-control avant déblocage | Réduit le risque d'un déblocage abusif unilatéral | Sur-ingénierie pour l'échelle actuelle (mono-owner fréquent) ; aucune exigence du cahier des charges ; friction UX non justifiée | **Rejeté** (anti-inflation) |
| **D — Expiration automatique** | Un blocage expire après N jours | Filet de sécurité passif | Change la sémantique produit (un blocage n'est plus définitif par défaut) sans résoudre le cas où le blocage doit être levé plus tôt qu'N jours | **Rejeté** comme substitut ; envisageable comme feature séparée future, hors mandat |
| **E — Override support/admin** | Rôle plateforme (hors salon) peut forcer le déblocage | Couvre le cas extrême "plus aucun owner/manager actif" | Un salon actif a toujours au moins un `owner` par construction produit (sinon rien d'autre ne fonctionnerait non plus) — scénario hors du domaine messagerie | **Hors mandat** ; noté comme filet de sécurité générique déjà couvert par les procédures d'admin existantes du produit, pas une décision messagerie |

### B.3 — Décision retenue

**Option B**, verrouillée comme partie de DEC-015 (§C ci-dessous). Autorisation de déblocage
recalculée **au moment de l'appel**, jamais mémorisée :

- Si `blocked_by = client_id` (blocage côté client) → seul `auth.uid() = client_id` peut lever.
- Sinon (blocage côté salon — `blocked_by` référence un owner/manager/staff) → **tout** owner ou
  manager actuel de `salon_id` (`has_role(auth.uid(), 'owner'/'manager', salon_id)`), ou le membre du
  staff actuellement assigné et actif (`staff_id` correspond, `is_active = true`, `deleted_at IS
  NULL`), peut lever — indépendamment de qui a posé le blocage à l'origine.

**Compatibilité avec l'architecture existante, démontrée** : `has_role()` est déjà le mécanisme
utilisé par 6 policies RLS existantes (`conversations_owner_manager_select`,
`staff_services`, `salons`, `activity_logs`, etc.) — aucune nouvelle primitive introduite. Le
paramètre `_salon_id` de `has_role()` scope déjà chaque appel à un salon précis — un owner du Salon A
ne peut pas satisfaire `has_role(uid, 'manager', salon_B)` (vérifié par lecture de la fonction,
`:34-43` : le `WHERE` filtre `u.salon_id = _salon_id`) — donc aucune fuite cross-salon possible par
construction, pas seulement par convention (voir aussi finding D.3 ci-dessous, qui impose que
l'Edge Function relise `conversations.salon_id` de la ligne ciblée, jamais un `salon_id` fourni par
le client). Aucune décision `LOCKED` n'est touchée : `blocked_by`/`blocked_at` restent des colonnes
existantes de Migration 1 (`:133-134`), rien ne change dans leur type, contrainte, ou FK — seule
l'autorité **applicative** (Edge Function, jamais implémentée jusqu'ici) est désormais spécifiée.

---

## Partie B (points fortement recommandés)

### B.1 — `is_local` (côté Flutter, pas une colonne DB)

**Pourquoi obligatoire.** `messages.client_message_id` (DEC futur, `messages` §5.3 du doc canonique)
garantit la déduplication **côté serveur** — un renvoi de la file offline (`MutationOutboxService`,
précédent réel : `lib/core/services/mutation_outbox_service.dart`) avec le même id ne crée jamais
deux lignes en base. Mais entre l'instant où l'utilisateur appuie sur "Envoyer" et l'instant où le
serveur confirme (latence réseau, file offline non vidée, app tuée avant confirmation), l'UI doit
afficher un message qui **n'existe pas encore côté serveur** — c'est l'écho optimiste, déjà le
comportement implicite de tout écran de chat. `is_local: true` est le champ, sur le **modèle Hive/
cache local** (jamais une colonne `public.messages`), qui distingue explicitement une ligne
"écho local non confirmé" d'une ligne "confirmée par le serveur, reçue via le stream Realtime borné
(ADR-0004) ou un fetch".

**Risques si absent** :
1. **Doublon visuel** : l'écho local ET la ligne serveur (arrivée via Realtime après confirmation)
   s'affichent simultanément comme deux bulles distinctes tant que rien ne les réconcilie par
   `client_message_id` — sans `is_local`, il n'y a pas de signal explicite pour déclencher cette
   réconciliation au niveau du provider d'affichage.
2. **Message fantôme après crash** : si l'app est tuée avant que `OfflineSyncCoordinator` ne vide la
   file, une ligne locale non marquée reste indiscernable d'un message réellement envoyé au
   redémarrage — l'utilisateur croit un message envoyé alors qu'il ne l'a jamais quitté l'appareil.
3. **État "lu/livré" mensonger** : un statut `sent`/`delivered` affiché sur un écho local avant
   confirmation server-side donnerait une fausse impression de succès de livraison.

**Invariant documentaire** (à consigner dans `lib/features/messaging/` au moment de l'implémentation
Flutter, Phase 4) : *"Un message avec `is_local = true` n'est jamais une source de vérité pour l'état
de livraison (`status`), n'est jamais compté dans les badges non-lus, et doit être remplacé
(jamais dupliqué) par sa ligne serveur dès que celle-ci arrive, identifiée par
`client_message_id` — jamais par correspondance de contenu."*

**Test dédié requis** (Phase 3/4, Flutter+intégration) : `T-local-01` — insérer un message via
l'outbox en mode avion (pas de réseau), vérifier `is_local = true` et rendu "en cours d'envoi" ;
reconnecter, laisser `OfflineSyncCoordinator` vider la file, vérifier qu'il existe **exactement une**
bulle affichée post-confirmation (pas deux), et que l'écho local a bien été remplacé (pas ajouté).

### B.2 — Suppression des `ELSE` implicites

**Principe retenu, appliqué partout dans cette revue** : toute branche qui déduit une catégorie
"par exclusion" (*"si ce n'est pas X, alors c'est forcément Y"*) est remplacée par une vérification
**positive** de chaque catégorie, avec un résidu qui **échoue bruyamment** plutôt que de retomber
sur une hypothèse implicite.

**Application 1 — `protect_conversation_columns` (§A.3)** : le brouillon original (`IF auth.uid() =
OLD.client_id THEN ... ELSE ...`) est remplacé par `is_client`/`is_salon_side` **tous deux vérifiés
positivement** (le second via `staff_profiles` actif + `has_role`), et le filet `to_jsonb` final
échoue explicitement sur toute colonne non couverte — il n'existe plus de branche qui écrit "par
défaut" sur une simple absence de correspondance à la catégorie précédente.

**Application 2 — `bump_conversation_on_message` (doc canonique `:403-410`)** : les `CASE WHEN
NEW.sender_id <> client_id THEN ... ELSE ...` supposent implicitement que "l'expéditeur n'est pas le
client ⇒ l'expéditeur est forcément côté salon". **Analyse de sûreté** : cette hypothèse est
actuellement vraie **par construction**, pas par accident — `messages_participant_insert` (doc
canonique `:358-374`) n'admet que 3 cas exhaustifs et mutuellement exclusifs pour `sender_id =
auth.uid()` : le client, le staff assigné (`client_staff`), ou owner/manager (`client_salon`) —
c'est une énumération explicite au niveau RLS, pas une supposition. Le `CASE` binaire du trigger de
comptage est donc une simplification **sûre aujourd'hui**, mais fragile si `messages_participant_insert`
change un jour sans que ce trigger ne soit revu en miroir. **Décision** : documenter ce couplage par
un commentaire protecteur explicite sur `bump_conversation_on_message` au moment de son écriture
(Migration 2) — *"Ce CASE binaire dépend de l'exhaustivité à 3 branches de
messages_participant_insert ; toute 4ᵉ catégorie d'expéditeur (ex. modérateur plateforme) doit
d'abord réviser ce trigger, sinon il compte incorrectement."* — pas un changement de code
supplémentaire à ce tour (aucune 4ᵉ catégorie n'existe), mais un garde-fou textuel pour un futur
lecteur, cohérent avec la convention §8 déjà en vigueur.

**Application 3 — contre-exemple déjà conforme** : `chk_staff_type` (DEC-004) est cité ici comme le
patron correct déjà en production — une CHECK **biconditionnelle** (`type='client_salon' AND
staff_id IS NULL) OR (type='client_staff' AND staff_id IS NOT NULL)`), aucune branche déduite par
exclusion. Aucune modification nécessaire, cité comme référence.

### B.3 — Clarification DEC-016

**Ce qui est déjà décidé (verrouillé par cette revue, §F)** : la règle elle-même — un message n'est
insérable dans un fil `client_staff` que si `bookings.status NOT IN ('cancelled','no_show')` pour le
`related_booking_id` cité, lu **à la volée** dans la policy RLS d'`INSERT` de `messages` (idiome déjà
en production, `20260623240000_bookings_schema.sql:95`), sans colonne dupliquée, sans trigger sur
`bookings`.

**Ce qui reste à implémenter** : la clause RLS elle-même, ajoutée à `messages_participant_insert`
(doc canonique `:358-374`) au moment de la Migration 2 — aucun SQL écrit dans cette revue.

**Ce qui dépend des Edge Functions** : **rien**, et c'est une distinction à ne jamais perdre — DEC-016
gate l'insertion d'un message dans une conversation **déjà ouverte** ; l'éligibilité de **création**
d'une conversation (règle anti-spam, historique de réservation, §6 du doc canonique) est un contrôle
**différent**, porté par `create-conversation` (`service_role`), qui ne revérifie jamais DEC-016 (une
conversation déjà ouverte reste ouverte même si le booking cité devient `cancelled` — seul l'envoi de
**nouveaux** messages est bloqué, pas la lecture de l'historique ni l'existence du fil). Ne jamais
fusionner ces deux contrôles dans une revue future.

**Ce qui dépend des migrations** : uniquement Migration 2 (`messages`) — aucune migration
intermédiaire requise, DEC-016 n'a pas de dépendance sur Migration 1.5 (`protect_conversation_columns`).

**Gap connexe découvert pendant cette clarification, non résolu ici** : l'invariant 7 (salon actif,
DEC-006) ne s'applique qu'à l'**ouverture** d'une conversation (`BEFORE INSERT` sur `conversations`),
jamais à l'envoi de messages dans une conversation `client_salon` déjà ouverte dont le salon devient
soft-supprimé **après coup**. Contrairement à DEC-016 (qui a un mécanisme désigné), ce cas n'a
**aucune règle décidée** — noté comme risque résiduel §Résidus, à trancher explicitement à la
conception RLS de Migration 2, pas silencieusement oublié.

---

## C — Finalisation DEC-015 (règle de blocage)

**Analyse par angle, telle que demandée :**

- **UX** : le blocage est un **mute asymétrique de l'écriture**, pas un effacement — l'historique
  reste visible des deux côtés (`messages_participant_select` ne filtre jamais sur `blocked_by`),
  seul un nouvel `INSERT` est refusé (`c.blocked_by IS NULL`, doc canonique `:364`). Alternative
  rejetée : masquer entièrement le fil au blocage — romprait la capacité du salon/support à consulter
  l'historique en cas de litige (voir angle "client d'assistance" ci-dessous).
- **Modération** : aucune modération automatique par IA (contrainte explicite du cahier des
  charges, déjà respectée — `docs/KYNZA_MESSAGING_ARCHITECTURE.md:591`) ; le blocage est une action
  humaine, binaire, réversible par une autorité **actuelle** (§B.3), jamais un algorithme de
  détection.
- **Sécurité** : asymétrie délibérée — le salon **ne peut jamais** lever un blocage posé par le
  client (`blocked_by = client_id` ⇒ seul le client lève). Un salon qui pourrait annuler la
  protection choisie par un client rendrait le blocage inutile comme mécanisme de protection de la
  partie la plus vulnérable dans une relation asymétrique client/entreprise. C'est une décision de
  sécurité produit, pas seulement technique.
- **Client d'assistance / exploitation** : aucune table d'historique dédiée (décision anti-inflation
  déjà actée, `:590`) — l'audit d'un différend "qui a bloqué, quand, pourquoi" s'appuie sur
  `activity_logs`, table déjà en production et déjà le mécanisme retenu pour ce type de traçabilité
  (`logs_self_insert_safe`, `20260623120000_users_schema_rls_hardening.sql:14-16`). **Exigence
  nouvelle, verrouillée ici** : la future Edge Function `toggle-conversation-block` DOIT écrire une
  ligne `activity_logs` à chaque bascule (bloqué/débloqué), réutilisant le mécanisme existant, n'en
  créant aucun nouveau — ajouté au DoD (§I) et à la checklist (§G).
- **SaaS multi-salons / propriétaires multiples** : `has_role(_uid, _role, _salon_id)` scope
  strictement par `salon_id` (§B.3) — aucune fuite d'autorité de blocage d'un salon vers un autre par
  construction. Un utilisateur avec un rôle `owner` sur 2 salons distincts (cas réel du modèle de
  données `users.salon_id` unique par ligne — nécessiterait en réalité une ligne `users` par salon
  géré, hors du périmètre de cette revue) n'obtient jamais d'autorité croisée.
- **Rotation du personnel** : résolu par §B (Option B) — c'est la raison d'être de cette section.

**Décision finale, verrouillée** : le modèle §B.3 (autorité actuelle, pas identité figée), avec
`blocked_by`/`blocked_at` en Catégorie E (§A.1, `service_role` uniquement via
`toggle-conversation-block`), traçabilité via `activity_logs` (existant, réutilisé). Aucune
alternative de la comparaison §B.2 n'offre un meilleur équilibre UX/sécurité/exploitation sans
introduire soit un risque de blocage permanent (Option A), soit une complexité non justifiée par le
cahier des charges (Option C/D).

---

## D — Revue de sécurité (recherche volontaire de failles)

Méthode : relecture adversariale de Migration 1 (déjà en production) + des brouillons `messages`/
RLS du doc canonique + de la spec §A/§B/§C ci-dessus, en cherchant activement contournements RLS,
contournements de trigger, colonnes non protégées, incohérences, escalades de privilège, races.

### D.1 — `protect_conversation_columns` : conflit d'ordre avec le trigger de compteurs — **résolu** (§A.4)
Déjà traité : `pg_trigger_depth()` + `auth.role()` combinés. Statut : **fermé par conception**, à
prouver empiriquement à l'implémentation (test `T-depth-01`, DoD).

### D.2 — **NOUVEAU, DEC-023** : aucune policy `UPDATE` owner/manager sur `conversations` — bloque structurellement le côté salon d'un fil `client_salon`
**Constat, preuve directe** : Migration 1 (`...conversations_schema.sql:200-205`) ne définit que
`conversations_client_update_own_state` (`client_id = auth.uid()`) et
`conversations_staff_update_own_state` (`staff_id IN (staff_profiles...)`). Pour un `client_salon`
(`staff_id IS NULL`, imposé par `chk_staff_type`, DEC-004), la policy staff ne peut **jamais**
matcher (`NULL IN (...)` n'est jamais vrai). **Conséquence** : aucun owner/manager ne peut
aujourd'hui exécuter le moindre `UPDATE` sur une conversation `client_salon` — ni directement
(épingler/archiver), ni indirectement (le futur bump trigger, s'il tourne en `SECURITY INVOKER`,
échouerait aussi sous RLS pour un message envoyé par un owner/manager). C'est un gap **produit**
autant que sécurité : la boîte de réception partagée du salon (le cas d'usage `client_salon`
principal) serait inutilisable pour épingler/archiver/masquer côté salon.
**Statut** : `OPEN`, tracé comme **DEC-023**, fermé par une nouvelle policy à ajouter en
Migration 1.5 :
```sql
CREATE POLICY "conversations_owner_manager_update_own_state" ON public.conversations
  FOR UPDATE USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );
```
Le filtrage colonne-par-colonne réel reste porté par `protect_conversation_columns` (§A.3) — cette
policy ne fait que rendre la ligne atteignable pour l'owner/manager, exactement le même partage des
responsabilités RLS-ligne / trigger-colonne déjà établi par DEC-013.
**Ne contredit aucune décision LOCKED** : Migration 1 n'a jamais prétendu couvrir la protection de
colonnes/l'accès en écriture complet (signalé dès `28a269c`, voir DEC-021) — ceci est une extension
additive, pas une correction d'une garantie déjà verrouillée.

### D.3 — **NOUVEAU, DEC-022** : sous-requêtes `staff_id IN (...)` sans filtre `is_active`/`deleted_at` — gap de rotation, distinct de DEC-015
**Constat, preuve directe** : `staff_profiles` porte `is_active BOOLEAN` et `deleted_at TIMESTAMPTZ`
(`20260623220000_staff_management.sql:15,21`), utilisés ailleurs pour filtrer le personnel actif
(`idx_staff_salon ... WHERE deleted_at IS NULL AND is_active = true`, `:23-25`). Or **toutes** les
occurrences de `staff_id IN (SELECT id FROM staff_profiles WHERE user_id = auth.uid())` dans la
messagerie — `conversations_staff_select`/`conversations_staff_update_own_state` (Migration 1,
`LOCKED`, `...conversations_schema.sql:189-192,203-205`) et les brouillons `messages_participant_*`
(doc canonique `:344-386`) — omettent `AND is_active = true AND deleted_at IS NULL`.
**Conséquence** : un membre du staff désactivé ou retiré du salon **conserve un accès complet et
permanent** à ses conversations `client_staff` — lecture, envoi de messages, épinglage/archivage —
indéfiniment après son départ. C'est la même classe de bug que le BLOQUANT 2 (autorité figée plutôt
qu'actuelle), mais sur l'accès **de base**, pas seulement sur le déblocage — plus grave.
**Statut** : `OPEN`, tracé comme **DEC-022**. Ne peut pas être corrigé en éditant Migration 1
(verrouillée, appliquée en production) — fermeture par une migration de remédiation dédiée
(Migration 1.5, avec DEC-013/DEC-023) qui `DROP POLICY` + recrée les 2 policies concernées avec le
filtre ajouté ; les brouillons `messages` intègrent le filtre correct dès leur écriture en
Migration 2, jamais le patron non filtré. **Priorité** : à traiter dans la même migration que
DEC-013/DEC-023, avant Migration 2 — sinon Migration 2 reproduirait le même bug par copier-coller du
patron existant.

### D.4 — Race condition TOCTOU sur `blocked_by IS NULL` (messages_participant_insert)
**Scénario** : sous isolation `READ COMMITTED` (défaut Postgres/Supabase), si un `UPDATE
conversations SET blocked_by = ...` et un `INSERT INTO messages` concurrent démarrent tous deux avant
que l'un des deux ne committe, l'`INSERT` peut voir `blocked_by IS NULL` (snapshot pris avant le
commit du blocage) et réussir, alors que le blocage est déjà "en cours" du point de vue horloge murale.
**Sévérité** : faible — fenêtre de course de quelques millisecondes, un seul message au pire peut
"passer" juste avant qu'un blocage ne devienne effectif pour tous les messages suivants ; aucune
lecture non autorisée, aucune escalade de privilège, juste un message envoyé à la limite temporelle
du blocage. **Décision** : documenté comme risque résiduel accepté (§Résidus), pas bloquant pour
Migration 2 — cohérent avec le calibrage d'échelle déjà acté en §10 (pas d'optimisation/durcissement
prématuré sur un cas à fenêtre étroite et impact limité). Envisageable via `SELECT ... FOR UPDATE` sur
la ligne `conversations` dans la policy si un incident réel le justifie un jour — pas avant.

### D.5 — Concurrence sur les compteurs (`client_unread_count`/`salon_unread_count`) — **vérifié sûr**
Deux messages concurrents dans la même conversation déclenchent deux exécutions de
`bump_conversation_on_message`, chacune un `UPDATE ... SET client_unread_count = client_unread_count
+ 1 ...` — un incrément relatif en une seule commande, jamais un `SELECT` puis `UPDATE` séparés côté
application. Le verrou de ligne Postgres sur `UPDATE` sérialise les deux écritures automatiquement ;
aucune perte de mise à jour possible. Vérifié par lecture du mécanisme (doc canonique `:397-420`),
aucun changement requis.

### D.6 — Portée cross-salon de la future Edge Function `toggle-conversation-block`
**Exigence de conception, verrouillée pour l'implémentation (Phase 2)** : l'Edge Function DOIT lire
`salon_id`/`staff_id`/`client_id` depuis la ligne `conversations` ciblée (via son `id`, en
`service_role`), **jamais** accepter un `salon_id` fourni par l'appelant pour l'évaluation
d'autorité — sinon un manager du Salon A pourrait forger une requête prétendant agir sur le Salon B.
Ajouté au DoD (§I) comme cas de test obligatoire ("tentative de déblocage cross-salon rejetée").

### D.7 — Aucun contournement de colonne via `UPDATE` partiel
Vérifié : Postgres fournit toujours la ligne `NEW` complète à un trigger `BEFORE UPDATE`, même pour un
`UPDATE` qui ne nomme qu'une colonne dans son `SET` — les colonnes non nommées conservent leur valeur
`OLD` automatiquement, avant même que le trigger ne s'exécute. Aucun vecteur de contournement par
`UPDATE` partiel du filet `to_jsonb` (§A.3) : il diffe la ligne complète, peu importe quelles
colonnes le `SET` du client nommait explicitement.

### D.8 — Publication Realtime : `conversations`/`messages` pas encore ajoutées
**Constat, preuve directe** : `supabase_realtime` ne contient aujourd'hui que `services`, `bookings`,
`staff_profiles` (`20260624040000_enable_realtime_publication.sql:16-18`) — **ni `conversations` ni
`messages`**. C'est exactement le bug déjà rencontré une fois sur ce projet ("chaque écran Phase 2
qui utilise `.stream()` ne reçoit silencieusement aucune mise à jour tant que la table n'est pas
ajoutée à la publication", même fichier `:4-13`). **Action requise, non une décision d'architecture**
mais une étape d'exécution obligatoire : `ALTER PUBLICATION supabase_realtime ADD TABLE
public.conversations; ... ADD TABLE public.messages;` doit faire partie de Migration 1.5/Migration 2 —
ajouté explicitly au DoD et à la checklist pour ne pas répéter l'incident.

---

## E — Revue d'architecture globale

Contrôle de cohérence entre l'ADR verrouillé, Migration 1 réellement appliquée, Supabase/PostgreSQL,
Realtime, les futures Edge Functions, les futures tables `messages`/`message_reports`/`device_tokens`.

- **Vs. ADR verrouillé (§1-§10)** : aucune décision `LOCKED` (DEC-001 à DEC-012, DEC-021) modifiée.
  DEC-013/014/015/016 étaient `TO-DESIGN`/`À CONFIRMER` — cette revue les ferme dans le cadre prévu
  par le §9 (roadmap officielle : "Revue de conception dédiée" entre Migration 1 et Migration 2).
- **Vs. Migration 1 réellement appliquée** : DEC-022/DEC-023 sont des gaps **découverts** dans du SQL
  déjà en production — traités comme `OPEN` (patron déjà établi par DEC-021), jamais comme une
  réécriture rétroactive de Migration 1.
- **Vs. Supabase/PostgreSQL** : `pg_trigger_depth()` (§A.4), `to_jsonb()` diff (§A.3), et
  `SECURITY DEFINER`/`REVOKE`/`search_path` (pattern §6 déjà validé) sont tous des mécanismes
  Postgres natifs standards, aucune fonctionnalité exotique, aucune dépendance à une extension non
  déjà active.
- **Vs. Realtime** : le futur stream de `messages` par conversation doit suivre ADR-0004
  (`.order('created_at', ascending: false).limit(N)`, jamais un stream non borné sur une table qui
  grossit par clé) — cohérent, aucune contradiction, mais **doit être appliqué dès l'écriture de
  Migration 2/Phase 4**, pas découvert après coup comme la publication (§D.8). Rappel explicite ajouté
  au DoD.
- **Vs. futures Edge Functions** : `create-conversation` (règle anti-spam, §6 doc canonique) et
  `toggle-conversation-block` (§B/§C) sont désormais les deux seules fonctions dont l'autorité
  n'est **pas** exprimable en CHECK/FK/RLS pure (cohérent avec §5, "Convention de mécanisme" — la
  colonne "Edge Function" du tableau §4 gagne une seconde croix légitime, pas une régression du
  principe qui en limitait le nombre).
- **Vs. futurs `messages`/`message_reports`** : DEC-016 (§B.3 ci-dessus) est cohérent avec le schéma
  `messages` déjà esquissé (doc canonique `:269-292`) — aucune colonne supplémentaire requise sur
  `messages` pour l'exprimer (lecture à la volée de `bookings.status`).
- **Vs. `device_tokens`** : table déjà en production (`20260717140000_device_tokens.sql`), aucune
  interaction avec `protect_conversation_columns`/DEC-015 — domaines disjoints, confirmé par absence
  de toute référence croisée dans le schéma `conversations`.

**Aucune contradiction non expliquée trouvée.** Les deux gaps découverts (DEC-022, DEC-023) sont des
omissions de portée dans du SQL déjà écrit, pas des contradictions entre documents.

---

## F — Verrouillage DEC-013 à DEC-016 + nouvelles décisions

| ID | Décision | Statut | Date | Migration | Preuve |
|---|---|---|---|---|---|
| DEC-013 | `protect_conversation_columns` — partition 7 catégories, refus par défaut, filet anti-dérive `to_jsonb` | **LOCKED (design)** | 2026-07-22 | Migration 1.5 (spec ci-dessus, SQL non appliqué) | §A.1-A.3 ; source : `...conversations_schema.sql:89-101,112-152` |
| DEC-014 | Trigger de compteurs — `SECURITY DEFINER` + garde combiné `auth.role()`/`pg_trigger_depth()` côté DEC-013 | **LOCKED (design)** | 2026-07-22 | Migration 2 (`messages`) | §A.4 ; source : doc canonique `:397-420` |
| DEC-015 | Règle de blocage — autorité actuelle (Option B), `blocked_by`/`blocked_at` en Catégorie E, traçabilité `activity_logs` | **LOCKED** | 2026-07-22 | Migration 1.5 (colonnes déjà en Migration 1) + Edge Function `toggle-conversation-block` (Phase 2) | §B.2-B.3, §C |
| DEC-016 | Éligibilité catégorie 2 — RLS à la volée sur `bookings.status`, distincte de l'éligibilité de création | **LOCKED (règle)**, SQL en Migration 2 | 2026-07-22 | Migration 2 (`messages`) | §B.3 (Partie B) ; précédent `20260623240000_bookings_schema.sql:95` |
| DEC-022 | Sous-requêtes `staff_id IN (...)` sans filtre `is_active`/`deleted_at` (Migration 1 + brouillons `messages`) | **OPEN** — dette de sécurité, fermeture en Migration 1.5 | 2026-07-22 | Migration 1.5 | §D.3 |
| DEC-023 | Aucune policy `UPDATE` owner/manager sur `conversations` | **OPEN** — gap fonctionnel+sécurité, fermeture en Migration 1.5 | 2026-07-22 | Migration 1.5 | §D.2 |

**DEC-021 (gap RLS Migration 1, ledger §2)** : statut inchangé `OPEN` jusqu'à l'implémentation réelle
de Migration 1.5 — cette revue **spécifie** sa fermeture (§A.3, DEC-013) mais ne l'implémente pas.
Passera à `LOCKED`/fermé seulement quand Migration 1.5 sera écrite, testée (cycle Rule 8 complet,
§7) et committée.

**Aucune décision verrouillée par un test réel dans ce tour** : DEC-013 à DEC-016, DEC-022, DEC-023
sont verrouillées comme **conception**, pas comme implémentation — cohérent avec la contrainte
explicite de ce tour ("aucune implémentation SQL"). Leur statut passera de "LOCKED (design)" à
"LOCKED" simple (avec preuve `fichier:ligne` + tests réels, comme DEC-001 à DEC-012) au commit de
Migration 1.5.

---

## Résidus — risques non fermés, explicitement listés

| # | Risque | Sévérité | Statut |
|---|---|---|---|
| 1 | DEC-022 (staff désactivé garde l'accès) | Élevée si non fermée avant Migration 2 | **FERMÉ** — Migration 1.5 (`20260723120000_conversations_hardening_1_5.sql`) appliquée, revalidé `supabase migration list --linked` (timestamp distant identique au local) ; preuve `MESSAGING_TRACEABILITY_MATRIX.md:48` |
| 2 | DEC-023 (owner/manager sans policy UPDATE sur `conversations`) | Élevée (bloque un cas d'usage produit central) | **FERMÉ** — même migration, même revalidation ; preuve `MESSAGING_TRACEABILITY_MATRIX.md:49` |
| 3 | Salon soft-supprimé **après** ouverture d'un fil `client_salon` — invariant 7 ne couvre que l'ouverture, pas l'envoi continu (§B.3, gap connexe DEC-016) | Moyenne | **FERMÉ** — "décision 3", Migration 2 (`20260723180000_messages_schema_migration_2.sql:167-172`) |
| 4 | TOCTOU sur `blocked_by IS NULL` (§D.4) | Faible | Accepté, documenté, non bloquant — inchangé |
| 5 | Publication Realtime non mise à jour tant que Migration 1.5/2 ne l'ajoute pas explicitement (§D.8) | Élevée si oubliée (récidive d'un bug déjà vécu) | **FERMÉ** — Migration 2 (`:393-394`) |
| 6 | Ticket RGPD déjà noté (DEC-010, hérité) — purge `conversations`/`messages` avant cascade `auth.users` | Moyenne, différée | Inchangé, hérité, non aggravé par cette revue |
| 7 | `messages_participant_insert` n'exclut pas `conversations.deleted_at IS NOT NULL` — DEC-024 non étendu au chemin d'envoi | Moyenne — pas de fuite cross-tenant, contourne une érasure administrative déjà actée | **Gouvernance fermée** (amendement DEC-024 ci-dessous) — **SQL en attente**, Lot 1.2, prochain commit |

Résidus 1, 2, 3 et 5 sont désormais fermés, prouvés par migration réellement appliquée (pas par
déclaration documentaire). Résidus 4 et 6 restent ouverts sans changement. Résidu 7 est nouveau,
sa gouvernance est close par cet amendement ; sa fermeture SQL reste un commit distinct (Rule 8).

---

## J — Feuille de route à 5 phases (aucun SQL écrit ici)

### Phase 1 — Fondation SQL
1. **Migration 1.5 — `conversations` hardening** (avant `messages`) : `protect_conversation_columns`
   (DEC-013, §A.3), policy `conversations_owner_manager_update_own_state` (DEC-023, §D.2),
   correction des 2 policies `staff_id IN (...)` existantes pour ajouter `is_active`/`deleted_at`
   (DEC-022, §D.3), ajout de `conversations` à `supabase_realtime` (§D.8). Cycle Rule 8 complet
   (§7) : preuves avant, écriture, push, tests réels (y compris `T-cols`, `T-depth-01`, tentative
   d'écriture directe par un staff désactivé → doit échouer), rollback vérifié, cleanup, commit
   unique, PORTE.
2. **Migration 2 — `messages`** : schéma (doc canonique `:269-292`), RLS avec DEC-016 intégré dès
   l'écriture (pas ajouté après coup), `client_message_id`/dédup, ajout à `supabase_realtime`.
3. **Migration 3 — `message_reports`**.
4. **Migration 4 — `device_tokens` raccord** (table déjà en production, raccordement seulement).
5. Triggers : `bump_conversation_on_message`/`reset_unread_on_read`, `SECURITY DEFINER` (§A.4),
   avec le commentaire protecteur du couplage à `messages_participant_insert` (§B.2, Application 2).
6. Contraintes/tests/rollback : même cycle Rule 8 que Migration 1, par table, par commit.

### Phase 2 — Fonctions de bord (Edge Functions)
`create-conversation` (éligibilité anti-spam, §6 doc canonique — inchangé par cette revue),
`send-message-push` (miroir `_shared/fcm.ts`), `toggle-conversation-block` (**nouvelle**, §B/§C/§D.6
— autorité actuelle, lecture `salon_id` depuis la ligne ciblée jamais depuis l'appelant, écriture
`activity_logs`), `archive`/`débloquer` (couverts par RLS directe + `protect_conversation_columns`,
pas d'Edge Function dédiée nécessaire — seule l'action de blocage/déblocage exige `service_role`),
`mark-read` (RLS directe, `messages_recipient_mark_read`, doc canonique `:376-386` — pas d'Edge
Function), `report` (nouvelle, écrit `message_reports`), notifications (réutilise `_shared/fcm.ts` +
`notification_templates` existants, D2 : la messagerie ne duplique jamais `notification_logs`),
téléchargements/pièces jointes (Supabase Storage, pattern à calquer sur l'existant, non détaillé ici
— hors périmètre gouvernance).

### Phase 3 — Tests complets
RLS (chaque policy, positif ET négatif, y compris DEC-022/023 après fermeture) ; charge/concurrence
(D.4, D.5 rejoués empiriquement, pas seulement raisonnés) ; sécurité (rejouer §D dans son ensemble
contre la base réellement appliquée, comme l'addendum post-lock l'a fait pour Migration 1) ;
performance (différée à l'échelle réelle, cohérent avec §10 — pas avant données de production
significatives) ; Realtime (vérifier la publication + le bornage ADR-0004 empiriquement, pas
seulement par lecture de config).

### Phase 4 — Interfaces Flutter
`lib/features/messaging/` (domain/data/application/presentation, calqué sur `reviews/`) : Client,
Salon/Inbox, Chat, Recherche, Pièces jointes, Notifications (badge agrégé §5.4 doc canonique, pas de
`NavBadgeNotifier` global — cohérent avec l'avertissement déjà en place), États (`is_local`, §B.1),
UX (blocage/déblocage, épingler/archiver/masquer/supprimer, §5.2 doc canonique), offline
(`MutationOutboxService`/`OfflineSyncCoordinator`, backoff déjà planifié doc canonique `:116`).

### Phase 5 — Production
Surveillance/logs/observabilité (réutiliser les mécanismes déjà établis dans
`docs/KYNZA_BACKEND_MAINTENANCE_HANDBOOK.md`, pas un second système) ; métriques/alertes (volumes de
messages, taux de blocage, latence Realtime) ; documentation (ADR déjà à jour par cette revue,
checklist/matrice/DoD §G/H/I) ; manuels d'exploitation (procédure support pour un litige
bloqué/débloqué, s'appuyant sur `activity_logs`, §C) ; assurance qualité finale avant lancement.

**Chaque item de chaque phase suit Rule 8 individuellement** (annonce → preuves avant → validation →
implémentation → preuves après → commit → PORTE) — ce roadmap est un découpage de portée, pas un
engagement d'exécution automatique.

---

## Recommandation finale

**Verdict : GO pour démarrer Migration 1.5, PAS ENCORE pour Migration 2.**

Les deux bloquants (§A, §B) sont fermés **au niveau conception** avec un mécanisme concret, testable,
et compatible avec l'architecture verrouillée. Les 3 points fortement recommandés (Partie B) sont
traités. DEC-015 est finalisée (§C). La revue de sécurité (§D) a trouvé 2 gaps réels et non triviaux
dans du SQL **déjà en production** (DEC-022, DEC-023) — c'est le résultat attendu d'un audit
adversarial sérieux, pas un signe d'échec de cette revue. Aucun des deux ne contredit une décision
`LOCKED` ; les deux sont additifs et se ferment dans la même migration que DEC-013.

**Condition de passage à Migration 2** : Migration 1.5 doit être écrite, testée (cycle Rule 8
complet), committée — fermant concrètement DEC-013, DEC-021, DEC-022, DEC-023 avec preuves réelles
(pas seulement la spec ci-dessus) — avant qu'une seule ligne de SQL `messages` ne soit écrite. C'est
la même discipline que celle qui a produit Migration 1 : preuves avant, jamais après.

---

# Corrections pré-Migration 1.5 (2026-07-23)

Cinq corrections exigées avant toute ligne de SQL de Migration 1.5, dans cet ordre. Aucune ne
modifie une décision `LOCKED` du corps ci-dessus (DEC-001 à DEC-012, DEC-021) ni les décisions
`LOCKED (design)`/`OPEN` de la revue de finalisation (DEC-013 à DEC-016, DEC-022, DEC-023) — elles
précisent, testent ou documentent, jamais ne redébattent.

## Correction 1 — Remplacement du test `updated_at`

**Ce qui était insuffisant** : la seule preuve d'ordre existant avant ce tour (§A.4, "Ordre de
déclenchement vérifié") est une **démonstration logique** (ordre alphabétique des noms de trigger,
`conversations_updated_at` < `trg_protect_conversation_columns`) — jamais une exécution réelle contre
une identité `authenticated` réelle tentant volontairement la falsification. Une preuve d'ordre n'est
pas une preuve de résistance à une attaque : elle montre que le trigger ne produit pas de faux
positif (il ne bloque pas une écriture légitime), pas qu'une tentative malveillante échoue.

**Nouveau test réel, exécuté** (`T-upd-forge-01`, contre `hhdkjfpgaklhrhfoxlhj`, transaction
`BEGIN...ROLLBACK`, aucune persistance) : un utilisateur authentifié réel (le client titulaire de la
ligne, `auth.uid()`/`auth.role()` simulés via `set_config('request.jwt.claim.sub'/'role', ..., true)`
sous le rôle `authenticated`, jamais `postgres`/`service_role`) exécute directement :

```sql
UPDATE conversations SET updated_at = '2020-01-01' WHERE id = <sa_propre_ligne>;
```

**Résultat réel obtenu** : `forged_value_persisted = false`, `is_now = true`, **aucune erreur levée**
(pas de `RAISE EXCEPTION`, pas de rejet RLS — la ligne est bien la sienne, le `WITH CHECK` de
`conversations_client_update_own_state` passe). La valeur réellement persistée est
`2026-07-23 06:23:19.280955+00` (capturée à l'exécution), jamais `2020-01-01`. Le mécanisme réel :
`conversations_updated_at` (Migration 1, préexistant, non modifié) écrase inconditionnellement
`NEW.updated_at = NOW()` avant même que `trg_protect_conversation_columns` ne s'exécute ;
`updated_at` (Catégorie G) est explicitement exclu de la liste diffée par le filet anti-dérive du
second trigger (`...conversations_hardening_1_5.sql`, liste `NOT IN (...)`), donc ce dernier ne
soulève jamais d'exception sur cette colonne — les deux triggers sont non-antagonistes par
construction, pas seulement par ordre alphabétique.

**Pourquoi ce test casse si l'ordre des triggers change un jour** : si un futur trigger
`BEFORE UPDATE` est ajouté sur `conversations` avec un nom alphabétiquement antérieur à
`conversations_updated_at` (ex. `aaa_something`) et qu'il réintroduit une écriture de `updated_at`
dérivée d'une valeur cliente avant que `conversations_updated_at` ne s'exécute, alors ce test échouera
immédiatement à la ré-exécution (`is_now` deviendrait `false` ou `forged_value_persisted` deviendrait
`true`) — il n'est donc pas un test statique de configuration mais un test **comportemental** rejoué
à chaque migration future touchant les triggers de cette table (ajouté à la Definition of Done,
voir plus bas, et à la checklist).

**Conséquence documentaire** : ce test remplace toute mention antérieure d'un "test updated_at" qui
ne visait que l'absence de faux positif ; il est la preuve citée pour DEC-013/DEC-021 ci-dessous
concernant `updated_at` spécifiquement.

## Correction 2 — Le rollback n'est plus présenté comme neutre en sécurité

**Constat** : Rule 8 (§7) et la Definition of Done exigent un rollback "sûr pour le schéma" — vrai et
inchangé pour Migration 1.5 (aucune perte de donnée, aucune contrainte/FK cassée : le rollback ne
touche que des objets trigger/fonction/policy, jamais une colonne ni une ligne). Mais "sûr pour le
schéma" a été, jusqu'ici, lu implicitement comme "neutre" — une confusion dangereuse pour une
migration dont l'unique objet est de fermer des gaps de sécurité (DEC-021/022/023).

**Correction explicite, à retenir pour toute décision future de rollback sur ce domaine** : annuler
Migration 1.5 (`DROP TRIGGER trg_protect_conversation_columns`, restauration des deux policies
`staff_*` sans filtre `is_active`/`deleted_at`, suppression de
`conversations_owner_manager_update_own_state`) **rouvre simultanément** :
- **DEC-021** (falsification de colonne par un client/staff déjà partie à la conversation) — dont le
  sous-cas `blocked_by`/`blocked_at` est classé **CRITIQUE** ci-dessous (Correction 3) parce qu'il
  défait un mécanisme de protection délibérément asymétrique (§C) ;
- **DEC-022** (accès lecture+écriture permanent d'un ex-membre du staff désactivé/retiré) ;
- une régression **produit** sur DEC-023 (plus aucun owner/manager ne peut gérer la boîte de
  réception partagée d'un fil `client_salon`) — celle-ci n'est pas une régression de sécurité, mais ne
  doit pas être confondue avec les deux précédentes lors d'une décision de rollback.

**Règle retenue** : un rollback de Migration 1.5 (ou de toute migration future qui ferme un gap de
sécurité) doit être traité comme une **décision de sécurité**, avec le même niveau de validation
qu'une désactivation délibérée d'un contrôle de sécurité — jamais comme un simple retour arrière
technique "sans risque parce que le schéma reste cohérent". Le schéma reste cohérent ; la posture de
sécurité, elle, régresse au niveau pré-Migration-1.5. Cette nuance est ajoutée à la Definition of
Done (section rollback) et au commentaire de rollback vérifié ci-dessous (§Preuves Migration 1.5).

## Correction 3 — Matrice de criticité des politiques orphelines

"Orpheline" ici désigne une policy RLS (ou l'absence totale de policy pour une opération) qui, avant
Migration 1.5, laissait une autorité non bornée là où elle aurait dû l'être — par colonne (DEC-021),
par état d'éligibilité actuelle (DEC-022), ou par absence complète de policy (DEC-023). Toutes ne
présentent pas le même risque ; les regrouper sous un seul niveau masquerait que certaines sont des
failles de sécurité actives et d'autres de simples trous fonctionnels sans exposition.

| # | Politique / gap (état pré-Migration 1.5) | Catégorie de risque | Niveau | Justification |
|---|---|---|---|---|
| 1 | `conversations_client_update_own_state` / `conversations_staff_update_own_state` — `blocked_by`/`blocked_at` falsifiables directement (sous-cas de DEC-021) | Intégrité — contournement d'un contrôle de sécurité | **CRITIQUE** | Défait DEC-015/§C : l'asymétrie du blocage (seul le client peut lever son propre blocage, jamais le salon) n'est une protection réelle que si `blocked_by`/`blocked_at` sont hors d'atteinte d'un `UPDATE` direct. Avant Migration 1.5, **le salon pouvait forger `blocked_by = NULL` pour effacer un blocage posé par le client** (ou l'inverse) via un simple `UPDATE` sur sa propre ligne — annulant la garantie même que le mécanisme prétend offrir à la partie la plus vulnérable. Exploitable par toute partie déjà légitimement associée à la ligne (pas un tiers anonyme), sans élévation de privilège requise — juste l'absence de garde. |
| 1bis | mêmes policies — **colonnes d'identité** (`salon_id`/`type`/`staff_id`/`related_booking_id`) falsifiables (sous-cas de DEC-021, trouvé pendant l'audit adversarial de cette revue, absent de la première version de cette matrice) | **Confidentialité + intégrité — fuite cross-tenant potentielle** | **CRITIQUE** | Preuve directe : le `WITH CHECK` de `conversations_client_update_own_state` (Migration 1) ne revérifiait que `client_id = auth.uid()` — aucune contrainte de table (CHECK/FK) n'exige que `salon_id` reste le salon d'origine, seulement qu'il référence *un* salon actif quelconque. Avant Migration 1.5, un client pouvait exécuter `UPDATE conversations SET salon_id = <salon quelconque> WHERE id = <sa propre ligne>` et réussir — réassignant sa conversation à un salon avec lequel il n'a **aucune relation**, ce qui la rend visible via `conversations_owner_manager_select` au owner/manager de ce salon tiers : une fuite de contenu de conversation vers un tenant complètement étranger, jamais consenti par personne. Classé au même niveau que le rang 1 (pas au-dessus) car, comme lui, l'attaquant doit déjà être une partie légitime de la ligne de départ. **Fermé** par la Catégorie A (IDENTITY_IMMUTABLE, aucune exception de rôle) de `protect_conversation_columns` — testé positivement en Migration 1.5 sur `salon_id` spécifiquement (pas seulement `client_id`), voir §Preuves Migration 1.5. |
| 2 | mêmes policies — `last_message_at`/`last_message_preview`/`client_unread_count`/`salon_unread_count` falsifiables (DEC-021) | Intégrité — falsification d'état système | **HAUT** | Une partie peut se donner l'apparence d'avoir reçu/lu des messages qu'elle n'a jamais reçus (ou l'inverse), ou effacer l'aperçu affiché à l'autre partie sans qu'aucun message n'ait réellement été échangé. Pas de fuite de données tierces, pas de franchissement de tenant, mais une corruption directe d'un signal sur lequel l'autre partie ET l'UI se fient (badge non lu). |
| 3 | mêmes policies — colonnes du **côté adverse** (`salon_pinned`/`salon_archived`/`salon_hidden_at`/`salon_deleted_at` par un client, et symétriquement `client_*` par un staff) (DEC-021) | Intégrité — corruption de l'état privé de l'autre partie | **HAUT** | Une partie peut manipuler l'état d'archivage/épinglage/masquage que l'AUTRE partie voit sur son propre écran (ex. un client force `salon_archived = false` pour qu'un fil reste visible dans la boîte du salon contre la volonté du salon). Bornée à la ligne où l'attaquant est déjà légitimement partie ; pas de fuite cross-tenant. |
| 4 | `conversations_staff_select` sans `is_active`/`deleted_at` (DEC-022, lecture) | **Confidentialité** — accès en lecture persistant d'un ex-employé | **HAUT** | Un membre du staff désactivé ou retiré du salon conserve un accès en LECTURE indéfini à l'historique de conversations (contenu potentiellement sensible côté client) — c'est une exposition de données à une personne qui n'a plus d'autorité légitime, sans borne de temps. Plus grave qu'un gap d'écriture pure (rang 5) parce qu'une fuite de lecture n'est jamais réversible une fois consultée. |
| 5 | `conversations_staff_update_own_state` sans `is_active`/`deleted_at` (DEC-022, écriture) | Intégrité — action persistante d'un ex-employé | **MOYEN** | Le même ex-employé peut aussi épingler/archiver/masquer ces fils indéfiniment — gênant pour l'exploitation du salon, mais ne divulgue aucune donnée nouvelle et ne touche que des colonnes de métadonnées UX, jamais le contenu ni l'identité des parties. |
| 6 | Absence totale de policy `UPDATE` owner/manager (DEC-023) | Disponibilité / produit — **pas une exposition de sécurité** | **FAIBLE** | RLS est *default-deny* : l'absence de policy ne fuite rien et ne corrompt rien, elle rend simplement un cas d'usage légitime (boîte de réception partagée) inutilisable. Classé bas uniquement du point de vue sécurité — noté explicitement pour ne pas être confondu avec un blocage produit critique (qui, lui, est réel et documenté ailleurs, ADR §D.2). La policy ajoutée en Migration 1.5 pour le fermer a elle-même été testée pour ne pas introduire de risque cross-salon (`T-dec023-neg`, preuve ci-dessous) — un gap FAIBLE fermé par une policy mal scopée aurait pu réintroduire un risque HAUT/CRITIQUE ; ce n'est empiriquement pas le cas ici. |

**Lecture de la matrice** : les niveaux 1, 1bis, 2, 3 sont fermés par `trg_protect_conversation_columns`
(DEC-013), qui ferme DEC-021 dans son ensemble ; les niveaux 4-5 sont fermés par le filtre
`is_active`/`deleted_at` ajouté aux deux policies `staff_*` (DEC-022) ; le niveau 6 est fermé par la
nouvelle policy `conversations_owner_manager_update_own_state` (DEC-023). Voir §Preuves Migration 1.5
ci-dessous pour l'exécution réelle de chaque fermeture.

## Correction 4 — Arbitrage DEC-014 : abandon du drapeau `current_setting()`/`set_config()`

**Contexte** : avant de retenir `pg_trigger_depth()` seul (§A.4) comme mécanisme distinguant une
écriture système imbriquée (le futur trigger de compteurs, DEC-014) d'une écriture cliente directe,
une alternative a été envisagée puis abandonnée : un **drapeau de session explicite**, posé par le
trigger de compteurs lui-même juste avant son `UPDATE` interne
(`SELECT set_config('kynza.internal_write', 'true', true);`), et lu par
`protect_conversation_columns` via `current_setting('kynza.internal_write', true) = 'true'` à la
place de (ou en plus de) `pg_trigger_depth() > 1`.

**Pourquoi cette option a été abandonnée — quatre raisons, dans l'ordre de gravité décroissante** :

1. **Un drapeau est un état déclaratif, falsifiable par construction ; `pg_trigger_depth()` est un
   fait calculé par le moteur, non falsifiable.** Un GUC personnalisé (`kynza.*`) n'est protégé par
   aucun mécanisme de permission dédié dans PostgreSQL — quiconque peut exécuter
   `SELECT set_config(...)` peut le poser, y compris depuis un contexte qu'on croyait exclu. Le
   drapeau ne prouve jamais que l'écriture provient réellement du trigger de compteurs ; il prouve
   seulement que **quelqu'un, quelque part, a affirmé** que c'était le cas — exactement la classe de
   garantie que §5 de cet ADR exclut explicitement pour tout ce qui doit lier `service_role`
   ("Une Edge Function ... ne garantit pas ... parce qu'elle ... peut contenir un bug"). Un drapeau de
   session est une auto-déclaration, pas une propriété structurelle. `pg_trigger_depth()` n'a
   *aucune* commande SQL capable de le fixer directement — c'est une lecture pure de la pile d'appel
   réelle du moteur PL/pgSQL, déjà établi comme non falsifiable côté client (§A.4).
2. **Risque de fuite de portée (« scope leak »)**, propre au fonctionnement des poolers de connexion
   utilisés par Supabase (mode transaction). Même avec `is_local = true` (portée transaction, reset
   automatique au `COMMIT`/`ROLLBACK`), un développeur futur copiant ce patron avec `is_local = false`
   par erreur (ou oubliant de le désactiver après un chemin d'erreur qui saute l'`UPDATE`
   attendu) ferait persister le drapeau au niveau de la **connexion physique**, pas de la requête
   logique — sur une connexion réutilisée par le pooler pour une requête authentifiée totalement
   différente, cela désactiverait silencieusement `protect_conversation_columns` pour cette requête
   sans rapport. `pg_trigger_depth()` ne peut pas fuir de cette façon : il retombe à `0`
   automatiquement dès que la pile d'appel PL/pgSQL se dépile, aucune étape de nettoyage requise.
3. **Charge de discipline reportée sur chaque future migration.** Un drapeau exige que *chaque*
   futur trigger interne légitime (bump, reset, et tout ce qui sera écrit après) se souvienne de le
   poser avant son écriture et de le lever après (ou compte sur `is_local` pour le faire à sa place,
   ce qui réintroduit le point 2 au moindre écart du patron). `pg_trigger_depth()` ne demande aucune
   discipline équivalente : la profondeur est vraie automatiquement pour *tout* trigger qui s'exécute
   au-dessus d'un autre, sans action de la part de l'auteur du trigger.
4. **Aucun gain réel par rapport à `pg_trigger_depth()` pour le cas d'usage réel identifié** — le
   scénario que le drapeau prétendait mieux couvrir (distinguer "quel trigger précisément" a émis
   l'écriture, pas seulement "un trigger quelconque au-dessus") n'est pas un besoin réel de DEC-013 :
   la fonction n'a jamais eu besoin de savoir *lequel* trigger est à l'origine de l'imbrication, 
   seulement *qu'il y en a un*. Le drapeau aurait résolu un problème plus précis que celui posé.

**Risques acceptés en retenant `pg_trigger_depth()` seul** :
- `pg_trigger_depth() > 1` ne peut débloquer, dans la fonction telle qu'écrite, que les catégories
  B (compteurs/`last_message_*`) et les colonnes `*_hidden_at` (démasquage auto) — **jamais**
  l'identité (Catégorie A, aucune exception de rôle), **jamais** `blocked_by`/`blocked_at`
  (Catégorie E, `is_system` strict requis), **jamais** `deleted_at` (Catégorie F, `is_system` strict
  requis). C'est une défense en profondeur déjà présente dans le code de Migration 1.5 : même si
  `pg_trigger_depth()` était un jour trompé par un chemin d'appel imprévu, les colonnes les plus
  sensibles resteraient hors de portée du seul critère `nested`.
- Risque résiduel explicitement accepté, **non prouvé, marqué hypothèse** : *"tout futur trigger ou
  fonction `SECURITY INVOKER` appelable par un client authentifié qui exécuterait un `UPDATE` imbriqué
  sur `conversations` depuis l'intérieur d'un autre trigger, sans être le trigger de compteurs
  légitime, serait à tort laissé passer sur les colonnes B/`*_hidden_at` par le seul critère
  `nested`."* Cette hypothèse est aujourd'hui **vraie par absence** : aucune fonction
  `SECURITY INVOKER` appelable par `authenticated` n'exécute de `UPDATE` imbriqué sur `conversations`
  (vérifié par lecture exhaustive de ce dépôt au 2026-07-23 — seuls les deux triggers déjà cités
  existent sur cette table). **Cette hypothèse doit être ré-examinée explicitement** à chaque
  migration future qui ajoute un trigger sur `conversations` ou une routine imbriquée capable
  d'`UPDATE` cette table — ajouté au DoD et à la checklist comme item de revue obligatoire, pas
  silencieusement supposé toujours vrai.
- **Ce qui rend la simplification correcte aujourd'hui** : l'hypothèse ci-dessus, plus le fait que
  Migration 1.5 elle-même n'introduit aucun trigger/fonction imbriqué capable d'`UPDATE`
  `conversations` autre que les deux déjà en production (`conversations_updated_at`,
  `trg_check_conversation_salon_active`, ni l'un ni l'autre n'écrivant les colonnes B/`*_hidden_at`)
  — donc `nested` est aujourd'hui toujours `false` en pratique tant que Migration 2 n'existe pas, ce
  qui rend la branche `nested` actuellement **inerte, jamais encore empruntée**, et donc non testable
  empiriquement avant Migration 2 (voir `T-depth-01`, toujours planifié, jamais exécuté — noté
  explicitement `NON PROUVÉ` ci-dessous, pas faussement présenté comme testé).

**Traçabilité** : cet arbitrage est désormais la référence normative pour DEC-014 — toute
réintroduction future d'un mécanisme de drapeau de session pour ce domaine doit d'abord relire cette
section et réfuter explicitement les quatre raisons ci-dessus, pas seulement proposer une variante.

---

# Migration 1.5 — Implémentation et clôture (2026-07-23)

**Fichier** : `supabase/migrations/20260723120000_conversations_hardening_1_5.sql`. Poussé via
`supabase db push --linked` contre le projet réellement lié (`hhdkjfpgaklhrhfoxlhj`), sans erreur.
Ferme **exactement** DEC-013, DEC-021, DEC-022, DEC-023 — aucune autre décision touchée, aucune ligne
concernant `messages`, aucune Edge Function, aucune interface Flutter.

**Exclu délibérément de cette migration** (voir en-tête du fichier) : l'ajout de `conversations` à
`supabase_realtime` (résidu §D.8 #5) — ce n'est pas une décision (`DEC-XXX`), c'est une action
d'infrastructure distincte (délivrance d'événements, pas schéma/RLS/trigger) avec sa propre forme de
preuve (`pg_publication_tables`, pas SQLSTATE). Reste `OPEN`, tracé séparément dans la checklist —
Migration 2 ne doit pas supposer que le canal Realtime est déjà branché tant que ce commit séparé
n'est pas fait.

## Preuves réelles — avant

Sondées contre `hhdkjfpgaklhrhfoxlhj` avant l'écriture du fichier (lecture seule, aucune mutation) :
- `information_schema.columns` : 23/23 colonnes de `conversations` confirmées, liste exacte identique
  à celle citée §A.1.
- `pg_trigger` sur `conversations` (pré-migration) : exactement `{conversations_updated_at,
  trg_check_conversation_salon_active}` — confirme l'ordre alphabétique cité §A.4 avant l'ajout du
  troisième trigger.
- `pg_policies` sur `conversations` (pré-migration) : exactement les 5 policies de Migration 1
  (`conversations_client_select`, `conversations_owner_manager_select`, `conversations_staff_select`,
  `conversations_client_update_own_state`, `conversations_staff_update_own_state`) — confirme
  l'absence totale de policy `UPDATE` owner/manager (DEC-023) et l'absence de filtre
  `is_active`/`deleted_at` sur les deux policies `staff_*` (DEC-022), telles que décrites §D.2/§D.3.
- `staff_profiles` : colonnes `is_active`/`deleted_at`/`user_id`/`id` confirmées présentes.
- `has_role()` : définition relue, confirme le scope strict par `_salon_id` déjà cité §B.3/§D.2.
- `pg_roles.rolbypassrls` : `authenticated=false`, `service_role=true`, `postgres=true` — inchangé
  depuis l'addendum post-lock, reconfirmé.
- Fixtures réelles identifiées pour les tests (production, `hhdkjfpgaklhrhfoxlhj`) : un salon actif
  (`SalonBeauteQA`), son owner, un client réel, deux profils staff actifs de ce salon, un booking réel
  `completed` liant ce client à un de ces staff sur ce salon (satisfait la FK composite DEC-002 sans
  fixture synthétique). Identifiants exacts conservés dans l'historique de session, pas republiés ici
  (aucune valeur n'est un secret, mais aucune n'a d'utilité documentaire au-delà de la preuve
  elle-même).

## Preuves réelles — après (tests, tous contre la table réellement appliquée)

Chaque test ci-dessous a été exécuté dans une transaction `BEGIN...ROLLBACK` (sauf le triptyque de
rollback en schéma miroir, isolé par construction) — zéro ligne persistée, confirmé par
`count(*) = 0` sur les identifiants de test avant et après l'ensemble de la session de preuve.

| Test | Rôle simulé | Action | SQLSTATE / résultat | Conforme à |
|---|---|---|---|---|
| `T-cols` | — (lecture) | `information_schema.columns` post-migration | 23/23 colonnes, liste identique à l'attendu | DEC-013 (préalable statique) |
| `T-upd-forge-01` | `authenticated` (client, propre ligne) | `UPDATE ... SET updated_at = '2020-01-01'` | Aucune erreur ; `forged_value_persisted=false`, `is_now=true` | Correction 1 |
| `T-drift-09` | `postgres` (DDL transactionnel) | `ALTER TABLE ADD COLUMN zz_test_drift` puis `UPDATE` de cette colonne | `P0001`, `uncategorized column(s) {zz_test_drift} changed` ; colonne absente après `ROLLBACK` (confirmé) | DEC-013 §A.3, filet anti-dérive |
| `T-cat-A` | `service_role` | `UPDATE ... SET client_id = ...` | `P0001`, `identity columns are immutable (...)` | DEC-013 Catégorie A (aucune exception de rôle) |
| `T-cat-A-salon` | `authenticated` (client, propre ligne) | `UPDATE ... SET salon_id = <autre salon réel>` | `P0001`, `identity columns are immutable (...)` | DEC-013 Catégorie A, matrice rang **1bis** (CRITIQUE, fuite cross-tenant) fermée |
| `T-cat-B-neg` | `authenticated` (client) | `UPDATE ... SET client_unread_count = 99` | `P0001`, `last_message_*/*_unread_count are system-managed only` | DEC-013 Catégorie B |
| `T-cat-E-neg` | `authenticated` (client) | `UPDATE ... SET blocked_by = ..., blocked_at = now()` | `P0001`, `blocked_by/blocked_at are writable only via toggle-conversation-block (service_role)` | DEC-013 Catégorie E, matrice de criticité rang 1 (CRITIQUE) fermée |
| `T-cat-E-pos` | `service_role` | même `UPDATE` que ci-dessus | Accepté, `block_set=true` | DEC-013 Catégorie E, `is_system` laisse passer |
| `T-cat-C-pos` | `authenticated` (client, propre ligne) | `UPDATE ... SET client_pinned = true` | Accepté, `client_pinned=true` | DEC-013 Catégorie C |
| `T-cat-D-neg` | `authenticated` (client) | `UPDATE ... SET salon_pinned = true` (côté adverse) | `P0001`, `salon_pinned/salon_archived/salon_deleted_at require current salon-side authority` | DEC-013 Catégorie D, matrice rang 3 fermée |
| `T-dec023-pos` | `authenticated` (owner du salon de la ligne) | `UPDATE ... SET salon_pinned = true` sur `client_salon` | Accepté, `salon_pinned=true` | DEC-023, matrice rang 6 fermée |
| `T-dec023-neg` | `authenticated` (owner d'un **autre** salon) | même `UPDATE` sur une ligne d'un salon différent (fixture transitoire, triggers non liés au domaine désactivés le temps du test, `ROLLBACK` derrière) | `rows_updated = 0` (RLS ne matche pas — aucune fuite cross-salon) | DEC-023, scope `has_role()` par `salon_id` reconfirmé empiriquement |
| `T-dec022-neg-select` | `authenticated` (staff désactivé dans la transaction) | `SELECT` sur sa propre conversation `client_staff` | `visible_rows = 0` | DEC-022 lecture, matrice rang 4 fermée |
| `T-dec022-neg-update` | idem | `UPDATE ... SET salon_pinned = true` | `rows_updated = 0` | DEC-022 écriture, matrice rang 5 fermée |
| `T-dec022-pos` (régression) | `authenticated` (staff **actif**, même fixture hors désactivation) | `SELECT` + `UPDATE ... SET salon_pinned = true` | `visible_rows=1`, `rows_updated=1` | Non-régression : le filtre ne bloque pas un staff toujours actif |
| `T-cat-F-neg` | `authenticated` (client) | `UPDATE ... SET deleted_at = now()` | `P0001`, `deleted_at (global) is writable only by an administrative/GDPR flow` | DEC-013 Catégorie F |
| `T-cat-F-pos` | `service_role` | même `UPDATE` | Accepté, `admin_delete_set=true` | DEC-013 Catégorie F, `is_system` laisse passer |
| `T-cat-null-context` | connexion directe, **aucun** GUC JWT posé (`postgres` brut) | `UPDATE ... SET blocked_by = ...` | Accepté, `allowed_as_null_context=true` | Preuve directe de l'hypothèse "NULL = contexte système" (voir finding ci-dessous) |

**Explicitement non testé, marqué hypothèse (voir Correction 4)** : la branche `nested` (
`pg_trigger_depth() > 1`) de `protect_conversation_columns` — aucun trigger imbriqué n'existe encore
sur `conversations` avant Migration 2 (`bump_conversation_on_message`). `T-depth-01` reste planifié,
non exécuté, non fermé par ce commit — cité fidèlement comme tel dans la checklist/DoD, jamais
présenté comme prouvé.

## Découverte critique pendant l'audit adversarial — deux mécanismes essayés et rejetés pour `is_system`

Conformément au mode de travail ("chercher activement les contradictions, ne jamais chercher à
confirmer, documenter toute découverte"), la relecture adversariale de ce commit — **avant** de le
committer — a trouvé un défaut réel dans la première version déployée de `protect_conversation_columns`,
puis dans sa première tentative de correction. Les deux tentatives ont été testées, cassées, et
documentées ici pour qu'aucun futur lecteur ne les réintroduise sans relire cette section en entier.

**Version 1 (celle décrite §A.3, reprise telle quelle de la conception verrouillée du 2026-07-22)** :
`is_system BOOLEAN := auth.role() <> 'authenticated';`. Défaut trouvé par sondage direct (pas par
test négatif applicatif) : sous une connexion directe sans contexte JWT (`SET LOCAL ROLE service_role`
sans poser `request.jwt.claim.role`), `auth.role()` retourne `NULL` — confirmé empiriquement
(`SELECT auth.role()` → `NULL` sous ce contexte). En logique à trois valeurs PL/pgSQL,
`NULL <> 'authenticated'` vaut `NULL`, et `IF NULL THEN` se comporte comme `false` (n'exécute jamais
le `RAISE`) — la colonne est donc laissée passer, mais **`is_system` n'a jamais été prouvé vrai**,
seulement laissé indéterminé avec un effet de bord permissif. Le "refus par défaut" revendiqué par
DEC-013 (§A.3) était, sur ce cas précis, un **laissez-passer par accident**, pas une décision positive.

**Version 2 (première tentative de correction, rejetée après test)** :
`is_system BOOLEAN := current_user IN ('service_role', 'postgres');` — remplace le GUC par le rôle
Postgres effectif, en écho au précédent `SET ROLE service_role` de T6b (Migration 1). **Testé et
cassé immédiatement** : `protect_conversation_columns` est `SECURITY DEFINER` — à l'intérieur d'une
fonction `SECURITY DEFINER`, `current_user` devient le **propriétaire de la fonction** (ici `postgres`,
le rôle qui l'a créée), **pour toute la durée de l'appel**, quel que soit l'appelant réel. Preuve
directe, fonction de diagnostic jetable (`zz_debug_current_user()`, `SECURITY DEFINER`, créée puis
détruite dans la même session de preuve) : `outside_definer = 'authenticated'`,
`inside_definer = 'postgres'`, **dans le même appel**. Conséquence si cette version 2 avait été
committée : `is_system` aurait été vrai **pour absolument tout appelant**, désactivant intégralement
les catégories B/C/D/E/F — une régression bien plus grave que le défaut de la version 1 (qui, lui,
n'affectait qu'un cas d'usage hors trafic PostgREST réel). Cette version n'a jamais été committée en
git ; elle n'a existé que dans le fichier de migration non commité et sur la base réellement liée
pendant la fenêtre de test — corrigée avant tout commit.

**Version 3 — retenue, déployée, testée** :
`is_system BOOLEAN := COALESCE(auth.role() <> 'authenticated', true);`. Reste basée sur le GUC
`auth.role()` (immunisé contre le changement de rôle induit par `SECURITY DEFINER`, à la différence
de `current_user`/`session_user`) mais rend explicite, via `COALESCE`, le choix qui était auparavant
un effet de bord accidentel : un contexte sans JWT (`NULL`) est **délibérément** traité comme système.
Testé positivement (`T-cat-null-context` ci-dessus) et négativement (toutes les catégories B/D/E/F
re-testées sous un contexte `authenticated` avec JWT posé, ci-dessus) : comportement identique à
l'intention originale de la version 1 pour tous les cas réels, mais désormais **prouvé**, pas déduit
d'un accident de logique ternaire.

**Hypothèse explicite retenue avec la version 3, marquée comme telle** : *"aucun utilisateur final
authentifié ne peut jamais atteindre cette table via une connexion Postgres directe qui contournerait
la pose des claims JWT par PostgREST/Data API — vrai aujourd'hui (le seul chemin d'accès des rôles
`anon`/`authenticated` passe par PostgREST, qui pose toujours `request.jwt.claims`), à réexaminer
explicitement si cette architecture change (ex. exposition future d'une connexion Postgres directe à
du code côté client)."* Non prouvée de façon exhaustive (aucune preuve négative absolue n'est
possible pour une hypothèse d'architecture), mais corroborée par lecture du mécanisme PostgREST déjà
en production pour ce projet et par l'absence de toute connexion directe exposée à un rôle
`anon`/`authenticated` dans ce dépôt.

**Ne pas confondre avec Correction 4** : Correction 4 rejette un **nouveau** GUC ad hoc
(`kynza.internal_write`) au motif qu'il introduirait une falsifiabilité et une charge de discipline
qui n'existent pas aujourd'hui. `auth.role()`/`auth.uid()` ne sont pas ce cas — ce sont les primitives
déjà posées exclusivement par PostgREST à partir d'un JWT vérifié, déjà la base de **toute** policy
RLS de ce dépôt (si elles étaient falsifiables par un client, chaque policy RLS existante serait déjà
compromise, pas seulement ce trigger) ; les réutiliser ici n'introduit aucun risque nouveau. Le seul
défaut réel trouvé est leur comportement sous une connexion qui ne passe PAS par PostgREST (`NULL`),
un angle mort différent de celui que Correction 4 traite (falsification par un appelant qui, lui,
passe bien par la voie applicative normale). Les deux sections restent cohérentes, pas
contradictoires — mais un futur lecteur qui les lirait vite pourrait croire l'inverse, d'où cette
clarification explicite.

## Rollback — vérifié en schéma miroir isolé, jamais sur la production

Rejoué dans un schéma scratch dédié `zz_conv15_rollback_check` (jamais sur `public.conversations`),
en trois étapes séquentielles, chacune vérifiée par requête réelle avant de passer à la suivante :
1. **Baseline** (forme pré-Migration 1.5, table miroir `LIKE public.conversations INCLUDING ALL`) :
   2 policies (`conversations_staff_select`/`_update_own_state`, sans filtre), 0 trigger de garde de
   colonnes — confirmé par `pg_policies`/`pg_trigger`.
2. **Forward** (forme Migration 1.5 rejouée à l'identique) : 3 policies (les 2 précédentes filtrées +
   `conversations_owner_manager_update_own_state`), 1 trigger — confirmé.
3. **Rollback** (ordre inverse : `DROP TRIGGER` → `DROP FUNCTION` → `DROP POLICY` owner/manager →
   `DROP`+`CREATE` des 2 policies `staff_*` dans leur forme originale non filtrée) : résultat final
   **texte-pour-texte identique** à l'état 1 (`qual` des deux policies comparé littéralement, égal),
   0 trigger — confirmé. Schéma scratch ensuite détruit (`DROP SCHEMA ... CASCADE`), confirmé absent
   de `information_schema.schemata`.

**Nuance de sécurité (Correction 2), rappelée ici où elle s'applique concrètement** : ce rollback est
**structurellement sûr** (aucune perte de donnée, prouvé ci-dessus) mais **rouvrirait, en production,
les gaps CRITIQUE/HAUT de la matrice de criticité (Correction 3)** s'il était rejoué sur la vraie
table. Il n'a été rejoué qu'en miroir, jamais en production, précisément pour cette raison.

## Cleanup — vérifié à 0

`count(*) = 0` confirmé, après l'ensemble des tests, sur : lignes `conversations` de test (préfixe
d'identifiant synthétique dédié), lignes `salons` de test (fixture transitoire du test cross-salon),
`staff_profiles.is_active` du profil temporairement désactivé restauré à `true`, schéma
`zz_conv15_rollback_check` absent. Aucune trace résiduelle dans la base réelle.

## Statuts mis à jour (DEC-013, DEC-021, DEC-022, DEC-023 → `LOCKED`)

| ID | Ancien statut | Nouveau statut | Preuve réelle |
|---|---|---|---|
| DEC-013 | `LOCKED (design)` | **`LOCKED`** | `...conversations_hardening_1_5.sql` (fonction + trigger, `is_system` en version 3 finale — voir « Découverte critique pendant l'audit adversarial » pour les 2 versions rejetées) ; tests `T-cols`, `T-upd-forge-01`, `T-drift-09`, `T-cat-A`, `T-cat-A-salon`, `T-cat-B-neg/pos`, `T-cat-E-neg/pos`, `T-cat-C-pos`, `T-cat-D-neg`, `T-cat-F-neg/pos`, `T-cat-null-context` |
| DEC-021 | `OPEN` | **`LOCKED` (fermé)** | Fermé comme conséquence directe de DEC-013 — mêmes tests, en particulier `T-cat-E-neg` (rang CRITIQUE de la matrice) |
| DEC-022 | `OPEN` | **`LOCKED` (fermé)** | `...conversations_hardening_1_5.sql` (`DROP`+`CREATE POLICY` des 2 policies `staff_*`) ; tests `T-dec022-neg-select`, `T-dec022-neg-update`, `T-dec022-pos` |
| DEC-023 | `OPEN` | **`LOCKED` (fermé)** | `...conversations_hardening_1_5.sql` (nouvelle policy) ; tests `T-dec023-pos`, `T-dec023-neg` |

**Ledger §2 — lignes mises à jour** (remplacent les lignes DEC-013/021/022/023 précédentes) :

| ID | Décision | Statut | Date | Migration | Preuve |
|---|---|---|---|---|---|
| DEC-013 | `protect_conversation_columns` (7 catégories, refus par défaut, filet anti-dérive) | **LOCKED** | 2026-07-23 | Migration 1.5 (`20260723120000_conversations_hardening_1_5.sql`) | Tests `T-cols`, `T-upd-forge-01`, `T-drift-09`, `T-cat-*` (ci-dessus) |
| DEC-021 | Gap RLS Migration 1 (UPDATE sans restriction de colonnes) | **LOCKED (fermé)** | 2026-07-23 | Migration 1.5 | Fermé par DEC-013, mêmes tests |
| DEC-022 | Sous-requêtes `staff_id IN (...)` sans `is_active`/`deleted_at` | **LOCKED (fermé)** | 2026-07-23 | Migration 1.5 | `T-dec022-neg-select`, `T-dec022-neg-update`, `T-dec022-pos` |
| DEC-023 | Policy `UPDATE` owner/manager sur `conversations` | **LOCKED (fermé)** | 2026-07-23 | Migration 1.5 | `T-dec023-pos`, `T-dec023-neg` |

**Aucune autre ligne du ledger n'est modifiée.** DEC-014/015/016 restent respectivement
`LOCKED (design)`/`LOCKED`/`LOCKED (règle)` — inchangées, leur implémentation reste Migration 2.

## Condition de passage à Migration 2 — désormais satisfaite pour sa part Migration 1.5

Le verdict de la revue de finalisation ("GO pour démarrer Migration 1.5, PAS ENCORE pour
Migration 2") est mis à jour : **Migration 1.5 est maintenant écrite, testée (cycle Rule 8 complet),
committée** — DEC-013, DEC-021, DEC-022, DEC-023 fermées avec preuve réelle, pas seulement la spec.
Reste `OPEN`, non couvert par ce commit, avant que Migration 2 ne commence : l'ajout de
`conversations` à `supabase_realtime` (résidu #5, exclu de Migration 1.5 par choix de granularité —
voir en-tête de la migration), et bien entendu tout ce qui est Migration 2 elle-même (schéma
`messages`, DEC-016 en RLS, `client_message_id`, triggers de compteurs DEC-014).

---

# Feuille de route à 5 phases — plan d'exécution verrouillé (2026-07-23)

> **SUPERSEDED (2026-07-23) PAR `docs/MESSAGING_ROADMAP.md`.** Cette section reste dans l'ADR pour
> l'historique (elle a réellement gouverné Migration 2) mais n'est plus la référence d'exécution :
> `docs/MESSAGING_ROADMAP.md` la remplace avec 6 phases (une phase "Notifications" a été isolée de
> l'ancienne Phase 2/Sécurité, pour la raison documentée dans ce nouveau fichier) et
> `docs/MESSAGING_EXECUTION_PLAN.md` la détaille en lots. Aucune décision `DEC-XXX` de cette section
> n'est invalidée par ce remplacement — seul l'**ordonnancement d'exécution** change de document.

**Aucun SQL dans cette section.** Cette feuille de route remplace, en la détaillant, l'esquisse §J
(2026-07-22) — elle n'invalide rien de §J, elle explicite le contenu de chaque phase avec la liste
exhaustive demandée. Elle sert de **référence pour les prochains cycles Rule 8**, pas d'engagement
d'exécution automatique : chaque item de chaque phase, au moment où il sera implémenté, suivra
individuellement le cycle complet (annonce → preuves avant → écriture → tests → rollback → cleanup →
commit unique → documentation → PORTE), exactement comme Migration 1 et Migration 1.5 l'ont fait.
Aucune phase n'est commencée par la production de cette feuille de route.

## Phase 1 — Infrastructure des messages

**Objet** : Migration 2 (`messages`), la seule table restant à créer pour la fondation transactionnelle
(après elle : Migration 3 `message_reports`, Migration 4 raccord `device_tokens`).

- **Tables** : `public.messages` (schéma déjà esquissé, doc canonique `KYNZA_MESSAGING_ARCHITECTURE.md:269-292`) — colonnes d'identité (`id`, `conversation_id`, `sender_id`, `created_at`), contenu (`body`, `attachment JSONB` discriminé), état (`status`, `client_message_id` pour la dédup offline), soft-delete par partie (miroir du patron déjà en place sur `conversations`).
- **Contraintes** : FK `conversation_id → conversations(id)` (`NO ACTION`, cohérent avec DEC-010) ; FK `sender_id → users(id)` ; `CHECK` sur `status` ; `UNIQUE` sur `client_message_id` scé par conversation (`uq_message_client_dedup`, dédup offline — voir Partie B.1 de la revue de finalisation, `is_local`).
- **Déclencheurs** : `bump_conversation_on_message`/`reset_unread_on_read` (DEC-014, `SECURITY DEFINER`, garde `pg_trigger_depth()`/`auth.role()` combiné — voir Correction 4 pour l'arbitrage déjà tranché) ; commentaire protecteur explicite sur le couplage à `messages_participant_insert` (revue de finalisation, Partie B.2, Application 2).
- **Index** : sur `(conversation_id, created_at DESC)` pour le stream borné (ADR-0004), sur `client_message_id` pour la dédup.
- **Politiques** : `messages_participant_select`/`_insert`/`_recipient_mark_read` — DEC-016 (booking actif) intégré **dès l'écriture**, jamais ajouté après coup ; filtre `is_active`/`deleted_at` sur toute sous-requête `staff_id IN (...)` **dès le départ** (ne jamais reproduire le patron non filtré de Migration 1, voir le commentaire protecteur déjà posé sur `conversations_staff_select`, Migration 1.5).
- **Temps réel** : `ALTER PUBLICATION supabase_realtime ADD TABLE public.messages` (et, si pas encore fait à ce stade, `public.conversations` — résidu #5) ; stream borné (`.order('created_at', ascending: false).limit(N)`, ADR-0004) dès l'écriture du repository Flutter, jamais découvert après coup.
- **Compteurs** : `client_unread_count`/`salon_unread_count`/`last_message_at`/`last_message_preview` sur `conversations`, déjà protégés par catégorie B de `protect_conversation_columns` (Migration 1.5) — le trigger de compteurs de `messages` est le seul écrivain légitime (imbriqué), déjà anticipé par `nested` dans la fonction existante.

## Phase 2 — Logique métier backend (Edge Functions)

Chaque fonction est un **orchestrateur**, jamais une garantie d'intégrité (§5 de cet ADR) — toute
règle exprimable en CHECK/FK/RLS/Trigger doit déjà être portée par la base avant que la fonction ne
soit écrite ; la fonction ne revérifie jamais ce que la base garantit déjà (tableau "qui garantit
quoi", §4).

| Fonction | Rôle | Garantie déjà portée par la base (ne pas dupliquer) | Ce que la fonction ajoute réellement |
|---|---|---|---|
| `créer_une_conversation` (`create-conversation`) | Ouvre une conversation | Invariant 7 (salon actif), chk_staff_type/chk_staff_requires_booking, FK simple/composite, index uniques anti-doublon | Éligibilité anti-spam (historique de réservation) — seule logique non modélisable en contrainte (§4, unique croix "Edge Function" jusqu'à Migration 1.5) |
| `envoyer_message` (`send-message`, ou RLS directe si aucune orchestration nécessaire) | Insère un message | RLS `messages_participant_insert` (appartenance + DEC-016 booking actif), dédup `client_message_id` | Notification push (voir ligne notifications), potentiellement rien d'autre si l'`INSERT` peut être direct côté client sous RLS |
| `modifier_message` | Édite un message existant | RLS propriétaire (`sender_id = auth.uid()`), fenêtre d'édition si le produit en définit une (à trancher au design de Migration 2, pas ici) | Logique de fenêtre temporelle si retenue |
| `supprimer_message` | Soft-delete d'un message par son auteur | RLS propriétaire, colonnes de suppression par partie (miroir `conversations`) | Rien si un simple `UPDATE` sous RLS suffit — à confirmer au design |
| `marquer_comme_lu` (`mark-read`) | Reset des compteurs non lus | RLS `messages_recipient_mark_read` (doc canonique `:376-386`) | Probablement rien — RLS directe suffit, pas d'Edge Function dédiée (cohérent avec §J existant) |
| `archive`/`épingle`/`cache` (pin/archive/hide) | Bascule d'état UX par partie | RLS `conversations_*_update_own_state` + `protect_conversation_columns` Catégories C/C'/D/D' (déjà en production, Migration 1.5) | Rien — écriture directe sous RLS, déjà entièrement couverte |
| `bloc` (`toggle-conversation-block`) | Bascule `blocked_by`/`blocked_at` | Colonnes en Catégorie E (`service_role` uniquement, Migration 1.5) | **Toute** la logique d'autorité (DEC-015 §B.3 : autorité actuelle, jamais figée), lecture de `salon_id` depuis la ligne ciblée (jamais depuis l'appelant, §D.6), écriture `activity_logs` (§C) |
| `rapport` (`report-message`) | Signale un message | RLS insertion `message_reports` (Migration 3) par participant | Peut-être rien de plus que l'`INSERT` sous RLS — à confirmer au design de Migration 3 |
| `télécharger` (pièces jointes) | Upload/accès Supabase Storage | Policies Storage à calquer sur l'existant | Génération d'URL signée si nécessaire, validation de type/taille |
| `notifications` | Push à l'envoi d'un message | `notification_templates`/`_shared/fcm.ts` déjà en production (D2 — jamais dupliquer `notification_logs`) | Le seul contenu réellement nouveau : le template et le routage propres à la messagerie |

## Phase 3 — Temps réel

- **Temps réel (transport)** : Postgres Changes sur `conversations`/`messages`, bornage ADR-0004,
  vérifié empiriquement (pas seulement par lecture de `pg_publication_tables`) — voir Correction 5 du
  DoD pour le scénario complet (`T-realtime-softdelete-rls`), qui couvre spécifiquement la RLS des
  événements `UPDATE` de suppression logicielle, pas seulement le `SELECT` initial.
- **Dactylographie (typing indicator)** : mécanisme Realtime Broadcast (pas Postgres Changes — aucune
  colonne DB dédiée, état éphémère non persisté) ; à spécifier au design de Phase 3, aucune décision
  prise ici.
- **Présence** : Realtime Presence (en ligne/hors ligne par utilisateur dans une conversation) — même
  remarque, éphémère, pas de colonne DB.
- **Ack (accusé de réception)** : distinct de "lu" (`marquer_comme_lu`) — à définir si le produit exige
  un état "livré" séparé de "lu" ; sinon, `status` de `messages` suffit (pas de nouvelle colonne sans
  besoin prouvé, cohérent avec la discipline anti-inflation déjà appliquée à ce domaine).
- **Non lu** : badge agrégé `SUM(*_unread_count)` déjà décidé (anti-inflation, pas de nouvelle table
  `user_message_badges`) — aucune décision à reprendre ici.
- **Synchronisation** : `MutationOutboxService`/`OfflineSyncCoordinator` (précédent réel du dépôt,
  `lib/core/services/mutation_outbox_service.dart`), backoff déjà planifié (doc canonique `:116`).
- **Résolution de conflits** : dédup serveur par `client_message_id` (jamais par correspondance de
  contenu) est le mécanisme déjà retenu (Partie B.1 de la revue de finalisation) — pas de résolution
  de conflit bidirectionnelle nécessaire pour de simples envois de message (pas d'édition concurrente
  multi-auteur sur la même ligne, `sender_id` est fixe).

## Phase 4 — Interface utilisateur Flutter

`lib/features/messaging/` (domain/data/application/presentation, calqué sur `reviews/` — précédent
déjà établi dans ce dépôt) :

- **Liste des conversations** : Inbox client, Inbox salon (boîte partagée owner/manager + staff, déjà
  rendue accessible en écriture par DEC-023).
- **Chat** : écran de fil, stream borné (ADR-0004).
- **Compositeur** : saisie + pièces jointes, `is_local` pour l'écho optimiste (Partie B.1) — jamais une
  source de vérité pour `status`, jamais compté dans les badges non lus, remplacé (jamais dupliqué) par
  la ligne serveur via `client_message_id`.
- **Images / Documents / Audio** : Supabase Storage, modèle `attachment JSONB` discriminé, re-fetch
  séparé de `promotions` à l'affichage (jamais une jointure SQL sur le stream, doc canonique
  `:314-333`).
- **Recherche** : à spécifier (full-text sur `messages.body` ou délégué à un service externe — aucune
  décision prise ici).
- **Archives** : état `*_archived` déjà en base (Migration 1), écriture déjà couverte RLS+trigger.
- **Blocage** : UX de bascule appelant `toggle-conversation-block`, affichage asymétrique (le salon ne
  voit jamais l'option de lever un blocage posé par le client, §C).
- **Signalement** : UX appelant `report-message`.
- **Notifications** : badge agrégé, pas de `NavBadgeNotifier` global (cohérent avec l'avertissement déjà
  en place dans ce dépôt).
- **Sensible** *(contenu à traiter avec prudence UX — pas de modération automatique par IA, contrainte
  déjà actée §C : "aucune modération automatique... le blocage est une action humaine")* : écrans de
  confirmation pour bloquer/signaler, jamais de détection automatique de contenu.
- **Mode sombre** : cohérence avec le design system existant du dépôt, aucune décision spécifique à la
  messagerie.

## Phase 5 — Validation finale

- **Audit de sécurité** : rejeu intégral de l'ADR §D (revue de sécurité adversariale) contre
  l'implémentation **réelle** de Migration 2/3/4 — pas seulement la conception, comme cela a été fait
  pour Migration 1.5 dans cette même session (voir « Découverte critique pendant l'audit adversarial »
  : un rejeu sérieux trouve des défauts réels, ce n'est pas un échec du processus).
- **Audit RLS** : chaque policy testée sous chaque rôle concerné, positif ET négatif, y compris les cas
  cross-salon et les cas de rotation de personnel (patron déjà établi par DEC-022/023).
- **Audit en temps réel** : `T-realtime-softdelete-rls` (Correction 5, DoD) exécuté réellement contre le
  service Realtime, pas simulé.
- **Performance d'audit** : différée à l'échelle réelle (ADR §10) — à exécuter une fois des données de
  production significatives accumulées, jamais comme prématuré sur des tables quasi vides.
- **Tests de charge** : idem, différés à l'échelle réelle.
- **Tests fonctionnels** : golden path ET cas limites dans l'app réelle (règle générale déjà en place
  pour tout changement UI/frontend de ce projet).
- **RGPD** : le ticket déjà ouvert (DEC-010) — purge `conversations`/`messages` avant toute cascade
  `auth.users` — doit être fermé par le premier flux d'effacement construit, pas oublié parce que
  "aucun flux RGPD n'existe encore".
- **Définition de la fin** : `docs/MESSAGING_DEFINITION_OF_DONE.md` satisfaite pour chaque feature,
  `docs/MESSAGING_TRACEABILITY_MATRIX.md` à jour, aucun résidu de sévérité "Élevée" encore `OPEN` dans
  la section Résidus de cet ADR.
- **Production de validation** : manuels d'exploitation rédigés (litige bloqué/débloqué, signalement),
  monitoring/alertes en place (volume de messages, taux de blocage, latence Realtime) — avant, jamais
  après, le lancement.

**Rappel de gouvernance** : chaque item ci-dessus, au moment de son implémentation, met à jour cet ADR
(§1 + ledger §2) **dans le même commit** que le SQL/code concerné — la règle de gouvernance permanente
déjà énoncée en fin du corps verrouillé de ce document s'applique identiquement à cette feuille de
route.

---

# Migration 2 — Implémentation et clôture (2026-07-23)

**Fichier** : `supabase/migrations/20260723180000_messages_schema_migration_2.sql`. Poussé via
`supabase db push --linked` contre le projet réellement lié (`hhdkjfpgaklhrhfoxlhj`), sans erreur.
Ferme DEC-014 et DEC-016 (implémentation, après leur verrouillage "design"/"règle" du 2026-07-22),
crée `public.messages`, et ferme le résidu §D.8 pour sa part `messages` (l'ajout de `conversations`
avait déjà été fait dans ce même fichier, puisque Migration 1.5 l'avait délibérément exclu). Aucune
ligne concernant `message_reports` (Migration 3) ou une Edge Function (Phase 2).

## Revue adversariale avant écriture — 5 décisions/corrections prises avant la première ligne de SQL

Conformément au mode de travail ("chercher à casser la conception avant d'écrire"), la relecture du
brouillon `messages` (doc canonique §5.3) et de la feuille de route à 5 phases a trouvé 5 points
réels avant qu'aucun SQL ne soit écrit — 3 nécessitaient un arbitrage produit (soumis à validation
explicite, jamais deviné), 2 étaient des applications mécaniques de précédents déjà `LOCKED`
(DEC-022/023) que le brouillon avait simplement omis d'appliquer à `messages` :

1. **Modèle de suppression logicielle — arbitrage demandé et tranché.** Le doc canonique §5.3 (SQL
   réel) ne définit qu'un `deleted_at` unique ; la feuille de route à 5 phases (§Phase 1) décrit
   littéralement "suppression logicielle par partie (miroir du patron conversations)", qui a 2
   colonnes (`client_deleted_at`/`salon_deleted_at`). Contradiction réelle entre les deux textes,
   jamais tranchée avant ce commit. **Décision retenue (validée explicitement)** : `deleted_at`
   unique, suppression par l'auteur seulement ("delete for everyone") — correspond au SQL du doc
   canonique tel quel, aucun besoin produit "delete for me" par message documenté nulle part.
2. **Édition de message — arbitrage demandé et tranché.** Le doc canonique lui-même punt
   ("`modifier_message`... fenêtre d'édition si le produit en définit une — à trancher au design de
   Migration 2, pas ici") et ne définit aucune colonne `edited_at`/`is_edited`. **Décision retenue
   (validée explicitement)** : l'édition est différée entièrement, hors périmètre de Migration 2 —
   V1 n'expose que envoi + suppression logicielle. Une migration future ajoutera la colonne et la
   règle de fenêtre le jour où le produit la spécifie.
3. **Résidu #3 de l'ADR (salon soft-supprimé après ouverture d'un fil `client_salon`) — arbitrage
   demandé et tranché.** Explicitement listé "non tranché, à décider explicitement à la conception
   RLS de Migration 2" (contrairement au résidu TOCTOU §D.4, pré-accepté). **Décision retenue
   (validée explicitement)** : `messages_participant_insert` revérifie `salons.deleted_at IS NULL`
   à chaque envoi pour `client_salon`, symétrique à DEC-016 (`bookings.status`) pour `client_staff` —
   jamais seulement à l'ouverture (invariant 7/DEC-006 ne couvrait que l'ouverture).
4. **`messages_recipient_mark_read` (brouillon) — application mécanique de DEC-022, pas une nouvelle
   décision.** Le brouillon omettait le filtre `is_active`/`deleted_at` sur la sous-requête
   `staff_id IN (...)` alors que le commentaire protecteur posé sur `conversations_staff_select`
   (Migration 1.5) exigeait explicitement "que ce filtre soit écrit dès le départ... y compris
   `messages_participant_select` (Migration 2)". Corrigé dans l'écriture initiale, jamais
   non-filtré-puis-corrigé.
5. **`messages_recipient_mark_read`/`messages_participant_select` — asymétrie owner/manager, trouvée
   par relecture de la propre première version de ce fichier, pas du brouillon du doc canonique.**
   Première version écrite de `messages_participant_select` gatait la clause owner/manager par
   `c.type = 'client_salon'`, alors que la "Note volontaire" du doc canonique (après §5.3) accorde
   explicitement à owner/manager une **supervision en lecture seule** sur `client_staff` aussi
   ("owner/manager gardent une supervision en lecture seule"). Corrigée avant tout test — voir le
   commentaire protecteur posé sur la policy dans le fichier lui-même. `messages_recipient_mark_read`,
   à l'inverse, gate correctement owner/manager à `client_salon` (l'écriture reste staff-only sur
   `client_staff`, cohérent avec "supervision en lecture seule").

**Une 6ᵉ découverte, structurelle, a motivé un nouveau mécanisme (`protect_message_columns`), pas une
décision produit** : une policy `UPDATE` nue `sender_id = auth.uid()` (nécessaire pour le
soft-delete par l'auteur) n'a, par construction RLS Postgres (plusieurs policies permissives pour la
même commande combinent leurs `WITH CHECK` par OR), aucune restriction de colonne propre — un
`UPDATE` passant la ligne via cette policy pourrait réécrire `conversation_id`/`status`/`is_flagged`
tant que `sender_id` reste inchangé. C'est exactement la classe de faille DEC-021 (accessibilité de
ligne sans restriction de colonne), déjà fermée une fois sur `conversations` par
`protect_conversation_columns` — `protect_message_columns` est le même mécanisme, appliqué à
`messages` dès sa première ligne de SQL plutôt que découvert dans une revue de finalisation
ultérieure. Elle ferme aussi une faille plus petite trouvée en l'écrivant : `read_at` ne doit jamais
être une valeur client de confiance (un destinataire pourrait sinon réécrire l'horodatage d'un
message déjà lu sans jamais passer par une vraie transition non-lu→lu) — gelé à `OLD` puis avancé
uniquement par la fonction elle-même, même posture que `sync_email_verified`
(`20260623120000_users_schema_rls_hardening.sql`).

## Preuves réelles — avant

Sondées contre `hhdkjfpgaklhrhfoxlhj` avant l'écriture du fichier (lecture seule, aucune mutation) :
`to_regclass('public.messages')` = `NULL` (table absente) ; 23/23 colonnes/policies/triggers de
`conversations` identiques à l'état de sortie de Migration 1.5 (6 policies, 3 triggers, aucune
dérive) ; `supabase_realtime` = `{bookings, notification_logs, owner_journey_progress,
proxipay_sessions, services, staff_profiles}` (ni `conversations` ni `messages`) ; `has_role()`,
`update_updated_at()`, `check_conversation_salon_active()` relus ; `bookings_status_check` = exactement
`{pending_payment, confirmed, in_progress, completed, cancelled, no_show}` (confirme l'idiome
`NOT IN ('cancelled','no_show')` de DEC-016) ; `staff_profiles`/`salons` colonnes confirmées.

## Preuves réelles — après (36 tests réels, tous contre production, `BEGIN...ROLLBACK`)

Exécutés en une seule transaction contre `hhdkjfpgaklhrhfoxlhj` (migration appliquée + fixtures
jetables + tous les tests + `ROLLBACK` final) — 36/36 passés, zéro ligne persistée, confirmé par
requête après coup (`SELECT count(*) FROM public.messages` = 0 post-déploiement réel). Catégories
couvertes : participation/RLS `INSERT` (client, staff actif, étranger rejeté), DEC-016 (client ET
staff bloqués symétriquement une fois le booking annulé), DEC-022 (staff désactivé perd l'accès
d'envoi même avec un booking actif), boîte partagée `client_salon` (owner et manager peuvent
envoyer), décision 3 (envoi accepté salon actif, rejeté après soft-delete du salon — avec un
deuxième owner réel propriétaire du second salon, pas le même compte que le premier), `blocked_by`
(bloque l'envoi indépendamment de DEC-016/décision 3), dédup `uq_message_client_dedup`, visibilité
`SELECT` (étranger = 0 lignes, supervision owner = toutes les lignes y compris `client_staff`),
`messages_recipient_mark_read` (owner ne peut PAS marquer lu un message `client_staff` — prouvé par
`rows_updated=0`, pas par exception, RLS `UPDATE` filtre silencieusement ; staff assigné peut ;
l'expéditeur ne peut jamais marquer son propre message lu), `read_at` forcé serveur (jamais la valeur
client, y compris tentative de réécriture sur un message déjà lu), `protect_message_columns`
(identité immuable y compris tentative de réassignation cross-conversation, édition de `body` bloquée
— décision 2 — `is_flagged` protégé, soft-delete par l'auteur accepté, par un non-auteur rejeté),
filet anti-dérive (colonne `zz_future_test_col` ajoutée puis rejetée en écriture, retirée), DEC-014
(`bump_conversation_on_message` incrémente le bon compteur + aperçu, `reset_unread_on_read`
décrémente sur transition lue), publication `supabase_realtime` (les deux tables présentes après
migration).

**Note de méthode, pour un futur lecteur qui rejouerait ces tests** : contrairement à un `INSERT` qui
échoue par exception SQL sous RLS, un `UPDATE`/`DELETE` dont la ligne ne satisfait `USING` d'aucune
policy applicable est silencieusement exclu (`rows_updated = 0`, aucune erreur) — les probes
`messages_recipient_mark_read`/soft-delete ci-dessus vérifient explicitement `rowCount === 0`, pas
seulement l'absence d'exception (une première version de ce test avait cette confusion exacte,
corrigée avant que les résultats ne soient considérés probants).

**Explicitement non (re)testé, hérité de Migration 1.5** : la branche `nested` de
`protect_conversation_columns` (`T-depth-01`) est désormais empruntable pour de vrai — DEC-014 vient
de créer le premier trigger imbriqué (`trg_bump_conversation_on_message`) qui écrit sur
`conversations` depuis l'intérieur d'un autre trigger — et le test ci-dessus ("DEC-014:
bump_conversation_on_message correctly incremented...") est la preuve empirique que `nested` fonctionne
réellement, pas seulement en conception. `T-depth-01` peut donc passer de "planifié, jamais exécuté"
à fermé par ce commit.

## Rollback — vérifié en transaction réelle (UP puis DOWN), jamais appliqué durablement

Contrairement à Migration 1.5 (qui altérait une table déjà en production et vérifiait son rollback en
schéma miroir), `messages` est une table neuve sans dépendant — le rollback a donc été vérifié
directement (`BEGIN` ; SQL de la migration ; `DROP TABLE`/`DROP FUNCTION`/`ALTER PUBLICATION ... DROP
TABLE` en ordre inverse ; `ROLLBACK` final, jamais de `COMMIT`) : `to_regclass('public.messages')` →
`NULL`, les 3 fonctions (`protect_message_columns`, `bump_conversation_on_message`,
`reset_unread_on_read`) → `to_regprocedure(...)` `NULL`, publication sans `conversations`/`messages`,
`conversations` elle-même retrouvée avec ses 23 colonnes inchangées (aucune interaction). Script DOWN :

```sql
ALTER PUBLICATION supabase_realtime DROP TABLE public.messages;
ALTER PUBLICATION supabase_realtime DROP TABLE public.conversations;
DROP TABLE IF EXISTS public.messages;
DROP FUNCTION IF EXISTS public.reset_unread_on_read();
DROP FUNCTION IF EXISTS public.bump_conversation_on_message();
DROP FUNCTION IF EXISTS public.protect_message_columns();
```

## Cleanup — vérifié à 0

Les 36 tests + le test de rollback ont chacun tourné dans une transaction rendue à `ROLLBACK` —
`SELECT count(*) FROM public.messages` = 0 confirmé après le déploiement réel (aucune ligne de test
n'a fui dans la table de production). `public.users`/`public.salons`/`public.staff_profiles`/
`public.bookings`/`public.services`/`public.conversations` inchangés (contraintes/triggers désactivés
puis rétablis par le même `ROLLBACK`, jamais par une restauration manuelle).

## Statuts mis à jour (DEC-014, DEC-016 → `LOCKED`)

| ID | Ancien statut | Nouveau statut | Preuve réelle |
|---|---|---|---|
| DEC-014 | `LOCKED (design)` | **`LOCKED`** | `trg_bump_conversation_on_message`/`trg_reset_unread_on_read` (`SECURITY DEFINER`) ; test "DEC-014: bump_conversation_on_message correctly incremented..." + "reset_unread_on_read decremented..." ; `T-depth-01` fermé (voir note ci-dessus) |
| DEC-016 | `LOCKED (règle)`, SQL en Migration 2 | **`LOCKED`** | `messages_participant_insert` (clause booking-actif) ; tests "DEC-016: client cannot send..."/"DEC-016: assigned staff cannot send... (symmetric)" |

**Nouvelles décisions verrouillées par ce commit** (hors ledger DEC — décisions de conception locales
à `messages`, pas des `DEC-XXX` du corps verrouillé) : modèle de suppression (deleted_at unique,
point 1 ci-dessus), édition différée (point 2), garde salon-actif pour `client_salon` (point 3,
symétrique à DEC-016), `protect_message_columns` (mécanisme, point 6).

**Aucune autre ligne du ledger n'est modifiée.** DEC-015 reste `LOCKED` (Migration 1.5 pour les
colonnes, Edge Function `toggle-conversation-block` toujours Phase 2, non commencée).

## Condition de passage à Phase 2 (Edge Functions) — pas encore ouverte par ce commit

Ce commit ferme intégralement la Phase 1 de la feuille de route à 5 phases (Migration 2). Rien dans
Phase 2 (Edge Functions), Phase 3 (temps réel applicatif), Phase 4 (Flutter) ou Phase 5 (validation
globale) n'est commencé — conformément à la Règle 8 ("ne jamais fusionner deux phases, ne jamais
anticiper une phase suivante"). Le prochain tour, gated sur l'accord explicite de l'utilisateur,
ouvrira soit Migration 3 (`message_reports`), soit directement Phase 2 (Edge Functions) — à trancher
au moment venu, pas anticipé ici.

> **Note (2026-07-23, post-réorganisation)** : la numérotation "Phase 2/3/4/5" ci-dessus est celle de
> l'ancienne feuille de route (désormais `SUPERSEDED`, voir plus haut). La suite réelle des travaux
> suit désormais `docs/MESSAGING_ROADMAP.md` (6 phases) et `docs/MESSAGING_EXECUTION_PLAN.md` (lots).
> Ce paragraphe reste inchangé comme trace historique de l'état au moment du commit `d3c1d0f`.

---

# Gouvernance d'exécution post-fondation (2026-07-23)

**Contexte** : à partir de ce point, la fondation transactionnelle du domaine Messaging
(Migrations 1, 1.5, 2 — DEC-001 à DEC-023) est considérée **stabilisée**. Le travail entre dans une
phase de **Product Delivery** (`docs/MESSAGING_ROADMAP.md`, `docs/MESSAGING_EXECUTION_PLAN.md`,
`docs/MESSAGING_API_CONTRACT.md`) — livraison incrémentale phase par phase, lot par lot, chacun fermé
par son propre cycle Rule 8.

**Règle normative, permanente à partir de cette date** :

1. **Plus aucune revue générale d'architecture n'est ouverte par défaut.** Le socle (structure des
   tables `conversations`/`messages`, RLS de base, triggers de garde de colonnes, ledger DEC-001 à
   DEC-023) n'est plus remis en question à l'occasion de chaque nouveau lot.
2. **Seules 4 revues restent autorisées pendant l'exécution des phases** (détail et checklist dans
   `docs/MESSAGING_DEFINITION_OF_DONE.md`, section "Gouvernance de revue") :
   - revue du lot/phase courante (périmètre respecté, pas de dérive vers un domaine voisin) ;
   - revue sécurité (checklist §D de cet ADR, rejouée contre ce qui est réellement écrit) ;
   - revue performance (mesure contre du trafic réel, jamais anticipation — §10) ;
   - revue rollback (DOWN testé pour toute migration/Edge Function du lot).
3. **Une revue d'architecture générale ne se rouvre que sur preuve réelle d'une contradiction
   démontrée** — le même standard déjà appliqué pour fermer DEC-022/DEC-023 (lecture directe du SQL
   réellement en production, jamais une supposition ni une préférence de conception). Concrètement :
   un test qui casse un invariant documenté, ou un comportement Postgres/Supabase mesuré différent de
   ce que cet ADR affirme, justifie une réouverture ciblée sur le point précis en contradiction —
   jamais une remise à plat générale du domaine.
4. **Toute nouvelle décision prise à l'intérieur d'un lot** (ex. fenêtre d'édition, schéma de mute,
   clé de rate-limiting) reste documentée au même endroit et avec la même rigueur que Migration 2 —
   preuve avant, jamais par supposition — mais **n'est pas** une "décision LOCKED du corps de l'ADR"
   au sens où DEC-001 à DEC-023 le sont : c'est une décision de lot, versionnée dans
   `docs/MESSAGING_EXECUTION_PLAN.md`/`docs/MESSAGING_API_CONTRACT.md`, qui suit le cycle Rule 8 du
   lot qui la contient.

**Ce que cette règle ne change pas** : le cycle Rule 8 complet (annonce → preuves avant → écriture →
tests → rollback → cleanup → commit unique → documentation → PORTE) reste obligatoire pour **chaque**
lot — cette section restreint la **portée** des revues (plus de revue générale), pas leur
**rigueur** (preuves réelles toujours exigées).

---

## Amendement — Mécanique de réouverture (DEC-009), préparation Lot 1.1

**Protocole d'amendement** : aucune substance de DEC-009 n'est modifiée ici — le principe reste
exactement "réouverture, pas recréation" (`ADR:120`), preuves T7/T8 inchangées. Ce qui suit rend
explicite la **mécanique d'exécution** que DEC-009 énonçait au niveau du principe mais ne décrivait
pas au niveau du comportement de `create-conversation` — trou trouvé, pas deviné, lors de la
préparation du dossier technique Lot 1.1 (DEC-009 ne parle que du `deleted_at` **global**,
"réservé à un effacement administratif/RGPD futur", et dit explicitement que le retrait par partie
`client_deleted_at`/`salon_deleted_at` est "hors du prédicat de ces index" — donc hors de ce que
DEC-009 tranche).

**Comportement officiel de `create-conversation` en cas de conflit `23505`** :
- La fonction renvoie toujours la conversation existante — jamais une nouvelle ligne (DEC-009).
- Elle remet à `NULL`, **côté appelant uniquement** (le client — seul appelant autorisé en V1, voir
  `docs/MESSAGING_API_CONTRACT.md` §1.1 "Périmètre V1") :
  - `client_deleted_at`
  - `client_hidden_at`
- Elle ne touche **jamais** :
  - `salon_deleted_at`
  - `salon_hidden_at`

**Propriétés de cette remise à `NULL`, faisant partie intégrante du comportement officiel** (pas une
amélioration optionnelle — son absence laisserait une conversation "réouverte" au sens de l'unicité
mais invisible pour le client dans toute liste filtrant sur ces colonnes) :
- **Idempotente** : rejouée N fois, même état final, jamais d'erreur si déjà `NULL`.
- **Limitée au côté appelant** : jamais le côté salon — cohérent avec l'asymétrie déjà établie
  ailleurs dans ce domaine (DEC-015 §C, asymétrie du blocage).
- **Indépendante de l'état précédent** : `UPDATE` inconditionnel de ces deux colonnes vers `NULL`,
  pas une lecture-puis-décision conditionnelle.

**Mécanisme technique déjà en place, aucune nouvelle protection requise** : `client_deleted_at`
(Catégorie C) et `client_hidden_at` (Catégorie C') de `protect_conversation_columns`
(`20260723120000_conversations_hardening_1_5.sql:146-155`) acceptent déjà une écriture `is_system`
(`service_role`) — le chemin que `create-conversation` emprunte par construction. Aucune modification
de `protect_conversation_columns` n'est nécessaire pour ce comportement.

## DEC-024 — Conversation administrativement supprimée : machine d'états de réouverture

**Énoncé** : une conversation portant `deleted_at IS NOT NULL` (global) est **définitivement
irrécupérable** par `create-conversation`. La fonction ne la réouvre jamais, quelle que soit la paire
identifiante fournie. La recherche/réouverture qui suit un conflit `23505` doit porter le prédicat
`AND deleted_at IS NULL`, à la fois dans l'`UPDATE` de réouverture et dans le `SELECT` diagnostique
qui le suit en cas de zéro ligne (voir machine d'états ci-dessous) — un seul et même prédicat
d'identité partagé par les deux statements, jamais reconstruit indépendamment.

**Raison** : `deleted_at` global est réservé à un effacement administratif/RGPD (Catégorie F,
`protect_conversation_columns`, `20260723120000_conversations_hardening_1_5.sql:140-143`) — un acte
d'autorité supérieure au client, jamais un geste utilisateur ordinaire (`client_deleted_at`/
`client_hidden_at` couvrent déjà ce cas, hors du périmètre de ce DEC). La laisser réouvrable par un
simple appel client contredirait la sémantique de l'effacement administratif et créerait un canal de
contournement d'une future obligation légale, sans qu'aucun texte ne l'ait jamais autorisé.

**Re-vérification (2026-07-28)** : aucun flux V1 ne peut écrire `conversations.deleted_at`.
`grep -r "conversations" supabase/functions/` → zéro résultat, aucune Edge Function existante ne
référence cette table. Aucune policy RLS `UPDATE`/`DELETE` `authenticated` ne peut passer la
Catégorie F (`is_system` requis). Preuve empirique déjà rejouée : test **T-cat-F-neg**, un
`authenticated` tentant `UPDATE ... SET deleted_at = now()` → `P0001` (`ADR:1615`). Le cas décrit par
ce DEC reste donc théorique tant qu'aucun flux RGPD n'est codé — ce DEC ferme le comportement par
avance, pas en réaction à un incident déjà survenu.

**Décision HTTP** : `403 { error: "conversation_erased" }` — jamais `410`. Justifié par le contrat
existant, pas par préférence : toutes les réponses déjà documentées pour cette opération
(`403 not_eligible`, `422 invalid_type`) expriment un refus métier motivé (appelant authentifié,
requête valide, action refusée) — famille HTTP `403 Forbidden`. `410 Gone` suppose un identifiant de
ressource déjà connu de l'appelant devenu invalide ; ici l'appelant ne fournit jamais
`conversationId`, seulement une paire d'identité — il ne redemande pas une ressource connue, il tente
une action métier. `error` distinct de `not_eligible` : ce cas n'est pas une question d'éligibilité
(le client a un historique de réservation valide) mais une érasure administrative déjà actée — un
code distinct évite qu'un futur écran Flutter affiche le même message pour deux causes sans rapport.

**Prédicat de diagnostic — règle d'identité invariante** (élevée en règle d'architecture, applicable
à toute future opération de récupération après conflit d'unicité dans ce domaine, pas seulement
`create-conversation`) : **toute opération de récupération après un `23505` doit reconstruire
exactement le même prédicat métier que celui ayant provoqué le conflit** — même `type`, mêmes
colonnes d'identité que l'index unique concerné (`salon_id`+`client_id` pour
`uq_conversations_client_salon`, `staff_id`+`client_id` pour `uq_conversations_client_staff`), jamais
un prédicat plus large, jamais un prédicat différent. Objectif : empêcher qu'un bug de reconstruction
d'identité (ex. un `staff_id` dont le `salon_id` a divergé entre l'ouverture et la tentative
courante, cf. tour d'analyse précédent) soit interprété à tort comme une conversation administrativement
effacée. Le `SELECT` diagnostique ne sert **jamais** à décider d'une écriture — uniquement à
classifier l'erreur une fois l'`UPDATE` déjà exécuté et retourné zéro ligne.

**Machine d'états complète, `23505` → réponse HTTP** :

```
UPDATE conversations
  SET client_deleted_at = NULL, client_hidden_at = NULL
  WHERE <prédicat d'identité — même type, mêmes colonnes que l'index unique concerné>
    AND deleted_at IS NULL
  RETURNING *

Cas A — 1 ligne retournée
  → 200 { conversationId, event: "conversation_reopened" }

Cas B, C, D — 0 ligne retournée
  ↓
  SELECT 1 FROM conversations
    WHERE <EXACTEMENT le même prédicat d'identité que l'UPDATE ci-dessus, sans le filtre deleted_at>
  (diagnostic seul — ne pilote jamais une écriture)
  ↓
  Cas B — ligne trouvée ET deleted_at IS NOT NULL
    → 403 { error: "conversation_erased" }
    (comportement officiel de ce DEC : irrécupérable, point final)

  Cas C — ligne trouvée ET deleted_at IS NULL
    → 500 { error: "unexpected_state" }
    Justification : l'UPDATE aurait dû matcher cette ligne (même prédicat, deleted_at déjà NULL) —
    sa non-sélection ne peut venir que d'un bug de reconstruction du prédicat d'identité entre
    l'INSERT ayant provoqué le 23505 et cet UPDATE (ex. valeur mal recalculée, mismatch de type).
    Ne jamais reclasser silencieusement en cas B : un mismatch d'identité n'est pas une érasure.

  Cas D — aucune ligne trouvée
    → 500 { error: "unexpected_state" }
    Justification : le 23505 prouve qu'une ligne satisfaisant l'index unique existait quelques
    millisecondes plus tôt ; son absence au diagnostic ne peut s'expliquer que par l'absence de tout
    code émettant un DELETE physique sur cette table aujourd'hui (soft-delete only, aucune policy
    DELETE) — donc une situation qui ne devrait jamais se produire avec le code actuel du dépôt,
    logguée comme telle plutôt que supposée impossible sans preuve.
```

**Conséquence** : Test B de la matrice de tests (conversation `deleted_at IS NOT NULL` → tentative de
réouverture) est désormais figeable sans branche alternative — issue unique : `403 conversation_erased`,
aucune colonne modifiée, aucune réouverture. `MESSAGING_API_CONTRACT.md` §1.1 doit lister ce code et
ce champ `error` (voir mise à jour du contrat, même commit).

**Ticket QA différé (non exécuté, non implémenté — préparation de travail futur uniquement)** :
staff transféré de salon entre l'ouverture et la réouverture d'un fil `client_staff`.
- **Objectif** : prouver empiriquement, pas seulement par lecture du code, que la réouverture
  `client_staff` continue de fonctionner après un changement de `staff_profiles.salon_id`.
- **Justification** : `staff_profiles.salon_id` n'est pas gelé au niveau schéma (aucun trigger
  d'immutabilité sur cette table — confirmé par grep lors du tour d'analyse précédant l'implémentation ;
  voir aussi `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql`, qui documente un cas
  réel de modification de cette colonne). Le prédicat d'identité de la branche `client_staff`
  (`staff_id`+`client_id`+`type`, jamais `salon_id`) a été choisi précisément pour rester correct dans
  ce scénario — ce ticket est la preuve d'exécution qui manque encore à ce choix.
- **Scénario** : `client_staff` ouvert (staff au salon A) → `staff_profiles.salon_id` du praticien cité
  passe du salon A à un salon B → tentative de réouverture de la même paire (même `staff_id`, même
  `client_id`) → la réouverture doit toujours aboutir à `200 conversation_reopened`, sur la bonne ligne.
- **Résultat attendu** : le prédicat `WHERE staff_id = :staff_id AND client_id = :client_id AND type =
  'client_staff' AND deleted_at IS NULL` continue de matcher exactement 1 ligne — aucun filtre parasite
  sur `salon_id` ne doit jamais être ajouté à ce prédicat, sous peine de zéro-ligne fantôme (`500
  unexpected_state`, Cas C) alors que la conversation existe réellement.
- **Lien avec DEC-024** : ce ticket teste la même mécanique de réouverture (`UPDATE` atomique, prédicat
  d'identité invariant) que DEC-024 spécifie — un cas supplémentaire de sa matrice, pas une règle
  nouvelle.
- **Lien avec le risque historique du prédicat d'identité** : ce risque a été identifié (pas deviné)
  lors du tour d'analyse précédant l'écriture de `create-conversation` — "Piège à ne PAS ajouter :
  `AND salon_id = :salon_id` sur la branche `client_staff`... ce filtre supplémentaire produirait un
  zéro-ligne fantôme". Le code livré respecte déjà cette règle (`identityColumn`/`identityValue` de
  `supabase/functions/create-conversation/index.ts` n'utilisent jamais `salon_id` sur cette branche) ;
  ce ticket est la preuve d'exécution encore manquante, pas une correction de code.

## Amendement — Extension de portée DEC-024 (chemin d'envoi, préparation Lot 1.2)

**Protocole d'amendement** : aucune substance de DEC-024 n'est modifiée ici — le principe reste
exactement "une conversation `deleted_at IS NOT NULL` est définitivement irrécupérable", énoncé et
machine d'états de réouverture inchangés. Ce qui suit étend le **périmètre d'application** de ce
principe, jusqu'ici limité par l'énoncé original au seul mécanisme connu à l'époque de sa rédaction
(`create-conversation`), à un second mécanisme d'écriture sur le même domaine
(`messages_participant_insert`) — trou trouvé, pas deviné, lors de la préparation du dossier technique
Lot 1.2 : `messages_participant_insert` (`20260723180000_messages_schema_migration_2.sql:144-174`) ne
vérifie `conversations.deleted_at` nulle part ; absence prouvée de tout garde-fou indirect — aucun
trigger `BEFORE INSERT` sur `messages`, la FK `conversation_id` ne vérifie que l'existence de la ligne
jamais son état, aucun CHECK, aucune autre policy, aucune Edge Function.

**Portée étendue, énoncée explicitement** : une conversation portant `conversations.deleted_at IS NOT
NULL` est définitivement irrécupérable — **aussi bien à l'ouverture (`create-conversation`) qu'à
l'envoi d'un nouveau message (`messages_participant_insert`)**. Aucun message ne doit pouvoir être
inséré dans une conversation dont `deleted_at IS NOT NULL`, quel que soit par ailleurs le statut de
participation, de blocage, ou d'éligibilité DEC-016/décision 3 de l'appelant.

**Raison de l'extension** : le principe d'irrécupérabilité concerne l'état de la **conversation
elle-même** (une érasure administrative/RGPD), pas un mécanisme d'écriture particulier. Le limiter au
seul chemin d'ouverture laisserait le chemin d'envoi contourner silencieusement une érasure déjà
actée — un participant légitime resterait libre d'écrire indéfiniment dans une conversation que
l'autorité administrative a explicitement déclarée irrécupérable.

**Ce que cette extension implique pour l'implémentation (spécification, SQL en attente d'un commit
distinct — Rule 8)** : `messages_participant_insert` devra porter, au même titre que ses clauses
DEC-016/décision 3/`blocked_by` déjà existantes, une clause supplémentaire `AND c.deleted_at IS NULL`
— placée au même niveau que `c.blocked_by IS NULL`, inconditionnelle (s'applique aux deux types de
conversation, contrairement aux clauses DEC-016/décision 3 qui sont chacune conditionnées à un seul
type). Aucune autre policy, aucune autre table.

**Conséquence sur le contrat** : `MESSAGING_API_CONTRACT.md` §2.1 énumère désormais cette contrainte
parmi les "Contraintes métier" de `sendMessage`, au même rang que DEC-016/décision 3/`blocked_by`.

**Pourquoi ceci est un amendement de portée et non un nouveau DEC** : un nouveau DEC répondrait à une
question métier non tranchée. Ici, la question est déjà tranchée par DEC-024 lui-même — seule sa
**couverture d'application** était incomplète. Précédent direct, même figure procédurale : l'amendement
"Mécanique de réouverture (DEC-009)" n'a jamais créé de DEC-009bis.

## Règle d'architecture — Séparation DEC-016 / éligibilité `create-conversation`, préparation Lot 1.1

**Rappel, déjà verrouillé, non modifié ici** (§B.3, `ADR:1055-1061`) : DEC-016 gate l'envoi de
**nouveaux messages** dans un fil `client_staff` déjà ouvert ; `create-conversation` gate uniquement
l'**ouverture** du fil, sur l'historique de réservation, sans filtre de statut. Ces deux contrôles
sont intentionnellement disjoints et ne doivent **jamais** être fusionnés. Cette section l'élève
explicitement au rang de règle d'architecture (pas seulement une clarification technique) parce que
le risque concret dépasse la seule confusion backend : c'est une **régression d'UX Flutter** si
l'écran de fil, une fois construit, ne respecte pas la même séparation.

**Règle contraignante pour toute future implémentation Flutter de ce domaine** :
- Flutter ne doit **jamais** proposer une action d'ouverture de conversation ("Contacter ce
  praticien" ou équivalent) à partir d'un booking dont le statut est `cancelled` ou `no_show` — ce
  filtre est une responsabilité de **présentation** (le CTA ne doit pas exister pour un booking déjà
  annulé), **distincte** de DEC-016 (protège l'envoi dans un fil déjà ouvert) et distincte de
  l'éligibilité de `create-conversation` (qui n'exclut pas les bookings annulés pour l'**ouverture**
  — booking existant, peu importe le statut).
- `create-conversation` ne revérifie **volontairement jamais** DEC-016 — confirmé §B.3, non modifié.
- Trois niveaux disjoints et intentionnels : filtre de présentation Flutter (CTA) / éligibilité
  d'ouverture `create-conversation` / éligibilité d'envoi `messages_participant_insert` (DEC-016).
  **Aucun développeur futur, backend ou Flutter, ne doit fusionner ces trois contrôles en un seul.**
