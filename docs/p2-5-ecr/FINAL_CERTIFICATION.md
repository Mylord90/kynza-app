# P2-5 Engineering Change Request — Final Certification

**Date**: 2026-07-07. Backed by Checkpoints 1-6 (`docs/p2-5-ecr/CP1_DESIGN_REVIEW.md` through
`CP6_DOCUMENTATION_CLOSURE.md`), which are themselves backed by live, evidenced testing —
`docs/p2-5-ecr/cp3_raw_dr_scratch_112_requests.ndjson`, `cp5_run1/2/3_*.ndjson` — not assumption.

---

## 1. P2-5 est-il définitivement résolu ?

**OUI — dans le périmètre exact que cette RCA et cet ECR ont défini, pas au sens le plus large
possible.** Le mécanisme identifié par la RCA (`docs/p2-5-rca/`) — `Content-Length` non fiable
entre la gateway Supabase et l'isolate Deno, provoquant le repli documenté du garde-fou vers un
`req.json()` non borné — est fermé, avec preuve : 100% de rejets corrects et déterministes sur
chaque taille de payload que la plateforme livre de façon fiable à l'isolate (jusqu'à ~208KB, plus
du double de `MAX_BODY_BYTES`), contre 0-20% pour l'ancien code testé dans la même session
(`CP3_TESTS.md` Section H, `CP5_VALIDATION.md`). Un phénomène plateforme distinct (P2-22,
ci-dessous) demeure ouvert, mais il n'est ni le mécanisme que la RCA a diagnostiqué, ni quelque
chose que ce garde-fou — ou tout code applicatif — peut corriger, comme démontré CP3 Section G/H.

## 2. Le nouveau mécanisme dépend-il encore de `Content-Length` ?

**NON.** `readBodyGuarded()` (`supabase/functions/_shared/cors.ts`) ne lit jamais l'en-tête
`Content-Length` — la version initiale de Checkpoint 2 conservait un pré-contrôle rapide basé sur
l'en-tête, retiré dès Checkpoint 3 après que les tests en direct ont montré qu'aucun client
légitime ne pouvait l'exercer sans violer le protocole HTTP lui-même (un en-tête sous-évalué par
rapport aux octets réellement envoyés bloque la requête au niveau du framing HTTP, avant même
d'atteindre le code applicatif). Le mécanisme actuel décide uniquement à partir des octets
effectivement lus du flux (`ADR-0005`).

## 3. Le comportement est-il déterministe ?

**OUI, pour le garde-fou lui-même — pas encore pour la question distincte de savoir si la
plateforme livre le corps de la requête à l'isolate.** Une fois que des octets arrivent au garde-fou,
sa décision (compter, comparer à `MAX_BODY_BYTES`, annuler si dépassement) est une fonction pure et
déterministe de ce qu'il a reçu — prouvé par lecture directe du code, et confirmé empiriquement par
100% de résultats identiques sur 15-30 tentatives consécutives, par fonction, à chaque taille
testée sous ~210KB (`CP3_TESTS.md`, `CP5_VALIDATION.md`). Au-dessus de ce seuil, c'est la livraison
elle-même qui devient non déterministe (P2-22) — un phénomène plateforme, prouvé identique sur
l'ancien code avec un en-tête honnête, donc non imputable à ce garde-fou.

## 4. La protection fonctionne-t-elle sur toutes les Edge Functions concernées ?

**OUI.** Les 16 fonctions affectées (`accept-invitation`, `calculate-commission`,
`check-permissions`, `claim-referral`, `create-booking`, `create-manual-invoice`,
`create-payment`, `create-walkin-booking`, `execute-workflow`, `mark-no-show`, `proxipay-confirm`,
`proxipay-create-session`, `rollback-remote-config`, `send-notification`, `update-remote-config`,
`validate-qr`) appellent toutes la même implémentation partagée — aucune réimplémentation locale.
Chacune a été testée individuellement, sous et au-dessus de la limite (`CP3_TESTS.md` Section D),
et le déploiement en production de les 16 est confirmé via `supabase functions list` (version et
`updated_at` mis à jour sur chacune).

## 5. Le ticket P2-5 peut-il être officiellement fermé ?

**OUI, avec le périmètre exact documenté.** `docs/remediation/MASTER_ISSUES_MATRIX.md` marque
désormais P2-5 **"Closed with Engineering Evidence (2026-07-07)"**, avec la preuve citée et une
clause de périmètre explicite renvoyant vers P2-22 pour ce qui reste ouvert — exactement la
discipline que Checkpoint 6 a appliquée plutôt que de fermer P2-5 au sens large sans preuve pour ce
sens large, ou de refuser toute fermeture malgré une preuve solide sur le mécanisme réellement visé.

## 6. Le backend KYNZA ne contient-il désormais plus aucune dette technique connue de niveau P2 ou supérieur ?

**NON — sans ambiguïté, et le Master Inventory le montre explicitement.** État actuel de
`docs/remediation/MASTER_ISSUES_MATRIX.md` après cette clôture :

| Sévérité | Total | Fermés | **Ouverts** |
|---|---|---|---|
| P0 | 1 | 0 | **1** |
| P1 | 8 | 1 | **7** |
| P2 | 22 | 1 (P2-5, cette session) | **21** |
| P3 | 19 | 5 | **14** |

Cette session elle-même a **ajouté** un nouvel élément P2 (P2-22) au moment même où elle en fermait
un autre (P2-5) — le compte net d'éléments P2 ouverts n'a pas baissé en dessous de 21. Le P0-1
(jeton d'invitation lisible publiquement) reste ouvert et critique ; 7 P1 restent ouverts. Toute
affirmation contraire contredirait directement le document que ce Checkpoint 6 vient de mettre à
jour dans cette même session.

---

## Résumé exécutif

P2-5, tel que diagnostiqué par sa RCA et corrigé par cet ECR, est fermé avec preuve d'ingénierie
réelle — pas une conclusion optimiste, pas un contournement. Le correctif dépend uniquement des
octets reçus, jamais d'un en-tête déclaré, et son comportement est déterministe à 100% partout où
il a pu être testé dans des conditions que la plateforme livre de façon fiable. Une découverte
séparée et honnêtement documentée (P2-22) montre qu'un plafond plateforme plus large existe pour
les corps de requête volumineux (~210KB+) — hors du périmètre de cet ECR, non causé ni corrigible
par lui, et désormais tracé comme dette technique distincte plutôt que dissimulé ou confondu avec
P2-5. Le backend KYNZA conserve une dette technique connue substantielle (1 P0, 7 P1, 21 P2, 14 P3
ouverts) — cette session en a fermé un élément et honnêtement ouvert un autre.
