# KYNZA Messaging — Definition of Done

Une fonctionnalité du domaine Messaging (table, trigger, policy, Edge Function, écran Flutter) n'est
**jamais** considérée terminée sur la seule base de "le code compile" ou "ça marche en local". Elle
doit satisfaire **tous** les points ci-dessous applicables à son type, avec preuve — pas une
déclaration. Cohérent avec le cycle Rule 8 (`docs/ADR_MESSAGING_FOUNDATION.md` §7) : preuves avant →
écriture → tests → rollback → cleanup → commit → documentation → validation → PORTE.

---

## Pour toute migration SQL (table, trigger, policy, contrainte)

- [ ] **Migration validée** — poussée via `supabase db push --linked` contre le projet lié réel
      (jamais `supabase config push`), sans erreur.
- [ ] **Restauration validée** — rollback rejoué dans un schéma miroir isolé (jamais sur la table de
      production qu'on vient de committer), ordre inverse vérifié.
- [ ] **Rollback qualifié explicitement en sécurité, pas seulement en schéma** — si la migration
      ferme un gap de sécurité (RLS, colonne, autorisation), la documentation du rollback doit dire
      explicitement quels gaps il rouvrirait s'il était rejoué en production (avec leur niveau de
      criticité s'il existe une matrice, ex. `docs/ADR_MESSAGING_FOUNDATION.md`, Correction 2/
      Migration 1.5) — ne jamais présenter "sûr pour le schéma" comme équivalent à "neutre en
      sécurité". Un rollback qui rouvre un gap `CRITIQUE` doit être traité comme une décision de
      sécurité (validation explicite requise), jamais comme un retour arrière technique routinier.
- [ ] **Tests SQL OK** — chaque contrainte/trigger a un test positif (accepté quand attendu) ET
      négatif (rejeté quand attendu), SQLSTATE + message capturés, rejoués contre la table
      **réellement appliquée**.
- [ ] **Tests RLS OK** — chaque policy testée sous chaque rôle concerné (`authenticated` avec
      chaque identité pertinente, `service_role`, et un rôle **non concerné** pour vérifier le
      rejet). Cas `BYPASSRLS` testé quand l'invariant doit lier `service_role` (DEC-007).
- [ ] **Cleanup vérifié à 0** — toute ligne de test insérée dans la vraie table est supprimée,
      `count(*)` post-nettoyage confirmé.
- [ ] **Aucune colonne hors catégorie** — pour `conversations` spécifiquement : `T-cols` passe
      (chaque colonne de `information_schema.columns` appartient à une catégorie connue de
      `protect_conversation_columns`, ADR §A.3).
- [ ] **Non-falsification de `updated_at` re-vérifiée** — toute migration qui ajoute, renomme, ou
      réordonne un trigger `BEFORE UPDATE` sur `conversations` doit rejouer `T-upd-forge-01` (ADR,
      Correction 1) : un utilisateur authentifié réel tente `UPDATE ... SET updated_at = '2020-01-01'`
      sur sa propre ligne — la valeur persistée doit rester `NOW()`, jamais la valeur forgée, sans
      erreur inattendue. Ce test est un test d'ordre de déclenchement, pas de configuration statique :
      il casse dès que l'ordre alphabétique des triggers (ou tout mécanisme qui en dépend) change.
- [ ] **Performances validées** — à l'échelle actuelle (pré-lancement), différée explicitement pour
      `EXPLAIN ANALYZE`/cardinalité (ADR §10) ; néanmoins, tout stream Realtime doit être borné
      (`.order().limit()`, ADR-0004) dès l'écriture, pas ajouté après coup.
- [ ] **Sécurité validée** — la migration a été relue contre la checklist adversariale de l'ADR §D
      (contournement RLS, contournement de trigger, colonne non protégée, escalade de privilège,
      race condition) — au minimum les items directement pertinents à ce qui est écrit.
- [ ] **Commit unique** — une migration, un domaine cohérent, un commit (jamais plusieurs
      changements sans rapport dans le même commit).
- [ ] **Documentation mise à jour** — `docs/KYNZA_MESSAGING_ARCHITECTURE.md` si le schéma diverge du
      brouillon canonique, avec justification (comme DEC-001 à DEC-006 l'ont fait pour Migration 1).
- [ ] **Synchronisation ADR** — `docs/ADR_MESSAGING_FOUNDATION.md` mis à jour **dans le même commit**
      que la migration : nouvelle décision numérotée (DEC-XXX), preuve `fichier:ligne` + test,
      statut ledger à jour (règle de gouvernance permanente déjà actée en fin de corps verrouillé).
- [ ] **Matrice de traçabilité mise à jour** — `docs/MESSAGING_TRACEABILITY_MATRIX.md`, la ligne
      concernée passe de `PLANNED`/`LOCKED (design)` à `LOCKED` avec les cases Trigger/Policy/Edge
      Function/Tests remplies.
- [ ] **Checklist mise à jour** — `docs/MESSAGING_FOUNDATION_CHECKLIST.md`, case cochée.

## Pour toute Edge Function

- [ ] Tous les points SQL ci-dessus applicables aux tables qu'elle touche.
- [ ] **Tests Edge Functions OK** — appelée réellement contre le projet lié (pas seulement une
      compilation Deno/TypeScript), cas positif ET négatif, y compris un cas d'autorisation refusée
      (ex. `toggle-conversation-block` appelé par un utilisateur sans autorité actuelle sur le
      salon).
- [ ] **Cas cross-salon testé** — pour toute fonction dont l'autorité dépend de `salon_id`, un appel
      qui prétend agir sur un autre salon que celui de la ligne ciblée doit être rejeté (ADR §D.6) —
      la fonction doit lire `salon_id` depuis la ligne réelle, jamais depuis un paramètre fourni par
      l'appelant.
- [ ] **Traçabilité `activity_logs`** — toute action de modération (bloquer/débloquer, signaler) écrit
      une ligne `activity_logs`, réutilisant le mécanisme existant (DEC-015 §C).
- [ ] Documentation/ADR/matrice/checklist mis à jour (mêmes exigences que ci-dessus).

## Pour toute table ajoutée à `supabase_realtime` (Postgres Changes)

Ne jamais se contenter d'écrire "la RLS fonctionne" comme critère — la RLS d'un `SELECT` classique et
le filtrage appliqué aux événements Postgres Changes sont deux mécanismes distincts qui doivent être
vérifiés séparément, empiriquement, contre le service Realtime réel (pas seulement par lecture de
policy).

- [ ] **`T-realtime-softdelete-rls`** (scénario complet, obligatoire dès Migration 2/`messages`,
      avant toute UI Flutter ne s'appuyant sur le stream) : les événements `UPDATE` utilisés pour la
      suppression logicielle d'un message (ex. `messages.client_deleted_at`/`salon_deleted_at`, futur
      pattern par-partie miroir de `conversations`) continuent-ils à respecter la RLS dans Postgres
      Changes, pas seulement dans un `SELECT` direct ?
      **Scénario, entièrement décrit** :
      1. Une conversation existe entre un client C et un salon/staff S, avec au moins un message M
         envoyé par C.
      2. Deux abonnements Realtime (Postgres Changes, websocket réel — pas une requête SQL simulée)
         sont ouverts sur `messages` : un authentifié comme C (participant légitime), un authentifié
         comme U, un utilisateur totalement tiers, non participant à cette conversation (autre client,
         ou staff d'un autre salon).
      3. C exécute l'`UPDATE` de suppression logicielle sur M (`client_deleted_at = now()`, jamais un
         `DELETE`, cohérent avec le domaine soft-delete-only, DEC-010).
      4. **Assertion positive** : l'abonnement de C reçoit l'événement `UPDATE` pour M.
      5. **Assertion négative, celle qui compte réellement** : l'abonnement de U ne reçoit **aucun**
         événement pour M — ni l'`UPDATE` complet, ni une version tronquée/redacted. Une fuite ici
         signifierait que Postgres Changes diffuse un changement à un abonné dont la RLS `SELECT`
         propre (`messages_participant_select`) lui aurait refusé l'accès à cette ligne par une requête
         directe — un canal de fuite parallèle à la RLS documentée, pas couvert par un test SQL classique.
      6. Répéter le scénario pour le cas "conversation bloquée" (DEC-015) : un tiers ne doit recevoir
         aucun événement sur les messages d'un fil bloqué auquel il n'est pas partie, et l'action de
         blocage elle-même (`UPDATE conversations` sur `blocked_by`/`blocked_at`) ne doit être visible
         qu'aux parties réelles de la conversation, jamais diffusée plus largement.
      7. Répéter pour le côté owner/manager (`conversations_owner_manager_select`) : un owner/manager
         d'un salon différent de celui de la conversation ne doit recevoir aucun événement.
      **Preuve exigée** : capture réelle des événements reçus par chaque abonnement (payload ou absence
      de payload), pas une inspection de policy — le test doit prouver un comportement réseau observé,
      pas seulement une configuration lue.
- [ ] `ALTER PUBLICATION supabase_realtime ADD TABLE ...` vérifié par requête directe
      (`pg_publication_tables`), jamais supposé à partir de la lecture d'un fichier de migration (ADR
      §D.8 — précédent d'un bug déjà vécu sur ce projet : écran utilisant `.stream()` sans que la
      table ne soit dans la publication, aucune erreur, silence total).

## Pour toute vue/écran Flutter du domaine Messaging

- [ ] **Analyse Flutter OK** — `flutter analyze` sans erreur nouvelle sur les fichiers touchés.
- [ ] Tests widget/unitaires pertinents passent, y compris (si applicable) `T-local-01` (réconciliation
      écho local / ligne serveur, ADR §B.1).
- [ ] **UX validée manuellement** — golden path ET cas limite testés dans l'app réelle (pas
      seulement les tests automatisés), conformément à la règle générale de ce projet pour tout
      changement UI/frontend.
- [ ] Offline testé explicitement : envoi en mode avion, reconnexion, vérification qu'il n'existe
      **aucun doublon** de message affiché après réconciliation.
- [ ] Aucune régression sur le badge non-lu agrégé (`SUM(*_unread_count)`, pas de nouveau système de
      comptage introduit — décision anti-inflation déjà actée).
- [ ] Documentation/ADR (si une décision d'architecture Flutter est prise)/matrice/checklist mis à
      jour.

## Critère global — avant de déclarer "Prêt pour la production" (checklist §"Prêt pour la
production")

- [ ] Aucun résidu de sévérité "Élevée" encore `OPEN` dans l'ADR (section Résidus).
- [ ] `supabase_realtime` contient `conversations` ET `messages` (vérifié par requête directe, pas
      par lecture de migration — ADR §D.8, précédent d'un bug déjà vécu sur ce projet).
- [ ] Manuels d'exploitation rédigés pour au moins : litige bloqué/débloqué (appui sur
      `activity_logs`), signalement de message.
- [ ] Monitoring/alertes en place pour : volume de messages, taux de blocage, latence Realtime.
- [ ] Revue de sécurité (ADR §D) rejouée contre l'implémentation **réelle**, pas seulement la
      conception — chaque finding fermé ou explicitement accepté comme résidu documenté.
