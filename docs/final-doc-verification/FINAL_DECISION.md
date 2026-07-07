# Final Documentary Verification — Final Decision

**Date**: 2026-07-07. Backed by `P0_VERIFICATION.md`, `P1_VERIFICATION.md`, `BODY_LIMIT_AUDIT.md` —
every claim below cites the specific document, line, commit, or live command that proves it.

---

## 1. Le P0 existe-t-il réellement ?

**Il a existé, et son mécanisme reste correctement documenté — mais il n'est plus ouvert
aujourd'hui.** P0-1 (`staff_profiles_public_select` exposant `invitation_token`) est réel dans son
historique (trouvé Cert v1/CP6, re-confirmé Cert v2/CP3, toujours ouvert au moment de
`KYNZA_FINAL_ENGINEERING_CERTIFICATION.md:179-182`, 2026-07-06 07:09). Il a été déployé en
production 21 minutes plus tard (`docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md`, 07:30) et
**re-vérifié en direct aujourd'hui** par ce document (`P0_VERIFICATION.md`) : `pg_policies` ne
contient plus `staff_profiles_public_select`, et l'exploit exact du Master Matrix retourne
désormais `[]` à un appel anonyme non authentifié. **Le seul document qui affirme encore qu'il est
ouvert (`MASTER_ISSUES_MATRIX.md`) est resté figé depuis 2026-07-04** et n'a jamais été mis à jour
après le déploiement — ce n'est pas une réouverture réelle, c'est un document jamais retouché.

## 2. Les 7 P1 existent-ils réellement ?

**Non, pas tels que cités.** Sur les 7 éléments P1 que la Final Certification du P2-5 ECR a comptés
comme ouverts (P1-1, P1-2, P1-4, P1-5, P1-6, P1-7, P1-8) :
- **3 sont en réalité fermés**, vérifiés en direct aujourd'hui : P1-1 (`salon_id` désormais épinglé
  dans `pg_policies.with_check`, requête directe), P1-2 (87/87 migrations appliquées, `supabase
  migration list --linked`), P1-5 (7 runs GitHub Actions réels, requête directe à l'API GitHub).
  Les trois sont "fermés mais oubliés" dans `MASTER_ISSUES_MATRIX.md`, jamais retouché depuis
  2026-07-04.
- **4 restent réellement ouverts** — P1-4 (keystore Android), P1-6 (contenu légal), P1-7 (iOS),
  P1-8 (formulaire Play Store) — mais **aucun n'est de la dette d'ingénierie** : les quatre sont
  reclassés "External Go-Live Dependency" par
  `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (lignes 50/52/53/54), une action externe
  ou métier, pas un gap technique restant à coder.

**Chiffre réel et vérifié aujourd'hui : 0 P0 ouvert, 4 P1 ouverts — tous de catégorie External
Dependency, aucun de catégorie Engineering.**

## 3. Le Master Inventory est-il cohérent (avec les documents sources qu'il est censé refléter) ?

**Non — trois incohérences distinctes et concrètes, chacune prouvée, pas supposée :**

1. **Deux documents différents portent le nom "Master Inventory"** sans se référencer l'un
   l'autre : `docs/remediation/MASTER_ISSUES_MATRIX.md` (figé au 2026-07-04) et
   `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (activement maintenu jusqu'au
   2026-07-06 13:45, explicitement désigné "Master Inventory" par
   `KYNZA_FINAL_ENGINEERING_CERTIFICATION.md:8-11,63`). Le P2-5 ECR a mis à jour le premier en le
   traitant comme LE Master Inventory, sans jamais consulter le second — c'est directement la
   cause de la contradiction que cette session a été chargée d'investiguer.
2. **Collision d'identifiant réelle, introduite par le P2-5 ECR** : la session P2-5 ECR (2026-07-07,
   commit `44ce828`) a ajouté un nouvel élément **"P2-22"** dans `MASTER_ISSUES_MATRIX.md` (le
   plafond plateforme pour les corps de requête volumineux). Mais **`P2-22` existe déjà** dans
   `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:81` — un problème **entièrement différent**
   (le plafond d'écriture en masse `trg_increment_monthly_bookings`, déjà fermé depuis
   2026-07-05). Les deux documents contiennent désormais un "P2-22" qui ne désigne pas la même
   chose — une ambiguïté documentaire réelle, pas nuancée.
3. **Incohérence interne à `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` lui-même** : son §2
   (tableau Master Inventory) a été mis à jour ligne par ligne jusqu'au 2026-07-06 13:45 et reflète
   correctement P0-1/P1-1/P1-2/P1-3/P1-5/P1-12 comme fermés — mais ses §1 (Executive Summary,
   lignes 22-34) et §19-20 (Final Executive Decision, lignes 513-543) n'ont **jamais été mis à
   jour** pour refléter ces mêmes fermetures : ils décrivent encore P0-1 comme "unpatched...
   today" et listent la fermeture de P0-1/P1-2/P1-3/P1-4 comme la condition à remplir avant de
   pouvoir arrêter le travail Backend — alors que 3 de ces 4 conditions sont déjà remplies selon le
   §2 du même document.

**Le Master Inventory n'est donc pas cohérent — ni entre ses deux instances, ni, pour la version
active, entre ses propres sections.**

## 4. Une correction documentaire est-elle nécessaire ?

**Oui — proposée explicitement ci-dessous, non appliquée**, conformément à la règle de cette
session :

1. **`docs/remediation/MASTER_ISSUES_MATRIX.md`** : mettre à jour les statuts de P0-1, P1-1, P1-2,
   P1-5 (et le résiduel de P1-3) en "Fermé", avec les citations exactes de `P0_VERIFICATION.md`/
   `P1_VERIFICATION.md` ; corriger le tableau exécutif ("P0 | 1 | 0" → "P0 | 1 | 1" ; "P1 | 8 | 1" →
   "P1 | 8 | 4").
2. **Résoudre la collision `P2-22`** : soit renommer l'élément ajouté par le P2-5 ECR dans
   `MASTER_ISSUES_MATRIX.md` (proposé : le renuméroter dans l'espace d'ID de
   `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`, qui va jusqu'à P1-13/P2-27 — le prochain ID
   P2 libre y est **P2-28**, pas P2-22), soit ajouter une note explicite de désambiguïsation dans
   les deux documents tant qu'ils coexistent séparément.
3. **`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`** : mettre à jour son §1 (Executive
   Summary) et ses §19-20 (Final Executive Decision) pour refléter l'état réel de son propre §2 —
   actuellement contradictoires en interne.
4. **Fusionner ou fusionner-par-référence les deux "Master Inventory"** : soit désigner
   explicitement `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` comme la seule source de vérité
   continue (ce que `KYNZA_FINAL_ENGINEERING_CERTIFICATION.md` affirme déjà faire) et marquer
   `MASTER_ISSUES_MATRIX.md` comme un instantané historique figé (2026-07-04) non maintenu, soit
   les réconcilier en un seul document.
5. **P2-5/P2-22 (le vrai P2-22 de cette session, le plafond plateforme)** doit être ajouté à
   `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (sous un ID non-collisionnant, voir point 2)
   puisque ce document est la référence active et ne reflète pas encore le travail du P2-5 ECR
   (2026-07-07), postérieur à sa dernière mise à jour (2026-07-06 13:45).

Aucune de ces corrections n'a été appliquée — elles sont proposées pour confirmation explicite de
Mylord, conformément à la règle de cette session.

## 5. Toutes les Edge Functions sont-elles protégées contre P2-22 ?

**Oui — les 16, avec preuve directe.** Voir `BODY_LIMIT_AUDIT.md` : les 16 fonctions partagent une
seule constante (`MAX_BODY_BYTES = 102 400` octets, `_shared/cors.ts:22`), aucune surcharge locale
n'existe (`grep` vérifié sur les 16 fichiers), et la valeur réellement appliquée en production a
été testée en direct (limite exacte confirmée à l'octet près sur 3 fonctions distinctes). Le
plafond plateforme, re-vérifié à partir des données brutes du P2-5 ECR plutôt que traité comme un
chiffre exact, dégrade de façon non déterministe entre ~209 000 et ~220 000 octets — la marge de
sécurité réelle est donc supérieure à 106 000 octets (plus du double), pas une marge étroite.

## 6. Le backend peut-il officiellement entrer en mode Maintenance sans ambiguïté documentaire ?

**Non — pas sans ambiguïté, et ce pour une raison précise, pas par prudence générique.** L'état
réel du backend (0 P0 ouvert, 4 P1 tous externes, protection P2-22 prouvée à 100% sur les 16
fonctions) est en fait **compatible** avec un mode Maintenance du point de vue de l'ingénierie —
mais **la documentation elle-même reste ambiguë** tant que les corrections de la Question 4 ne sont
pas appliquées : deux "Master Inventory" non réconciliés, une collision d'ID P2-22 non résolue, et
un document de référence interne à lui-même contradictoire (§2 vs §1/§19-20). Entrer en mode
Maintenance aujourd'hui reviendrait à s'appuyer sur un état documentaire que cette session vient de
prouver incohérent — la recommandation est donc : appliquer les corrections proposées en Question 4
(actions purement documentaires, aucun code, aucune migration), puis re-confirmer, avant de
considérer le mode Maintenance comme "sans ambiguïté."
