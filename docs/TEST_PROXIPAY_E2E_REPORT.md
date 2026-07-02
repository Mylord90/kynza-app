# KYNZA ProxiPay — Rapport Test E2E Émulateur

**Date :** 2026-07-02
**Commit de base :** `1438e4f` (+ correctifs listés ci-dessous, non commités au moment du test)
**Émulateur :** Kynza_Pixel6 (Android 34, `sdk gphone64 x86 64`)
**Durée totale :** ~2h30 (dont ~1h de déblocage d'un problème de build préexistant sans rapport avec ProxiPay)

---

## ⚠️ Écart avec le script de test original

Le script de test fourni supposait l'architecture du prompt spec initial (deep link
`kynza://proxipay?session=...`, écrans `ProxiPayClientConfirmScreen` /
`ProxiPayProcessingScreen` / `ProxiPayResultScreen` séparés, `KynzaLogger`,
colonnes `session_id`/`transport`/`transaction_ref`/`client_mobile_money_id`/
`synced_to_supabase`, logs NFC/BLE). Le plan **réellement approuvé et implémenté**
(voir `merry-swimming-shamir.md`) est volontairement plus simple :

- QR encode l'`id` brut de `proxipay_sessions` (pas d'URI, pas de deep link) —
  scanné in-app, même pattern que le QR de fidélité existant.
- Un seul écran par rôle : `ProxiPayQrScreen` (staff) / `ProxiPayScanScreen` (client).
- Aucun log `[INFO] ProxiPay: ...` n'existe (pas de `KynzaLogger` dans ce projet).
- Le paiement réel transite par la table `transactions` existante (pas de
  colonnes dédiées dans `proxipay_sessions`).
- Étape 7 (sync offline/Hive) **non applicable** — ProxiPay exige une connexion
  live par conception (comme le flux de paiement en ligne existant).

Le test ci-dessous suit donc les étapes 1–6 adaptées à cette architecture, plus
une vérification UI côté client via un champ de secours `kDebugMode` (pré-autorisé
par le script original pour ce cas exact : un seul device disponible pour jouer
les deux rôles).

---

## Résultats par étape

| Étape | Description | Statut | Notes |
|-------|-------------|--------|-------|
| 1 | Création booking test (walk-in, CoupeHomme, 10 000 BIF) | ✅ | Créé via l'UI Owner réelle, vérifié en DB |
| 2 | Initiation ProxiPay staff → QR affiché | ✅ | `proxipay-create-session` déployée, QR + countdown live |
| 3 | Session capturée en DB | ✅ | `status='pending'`, `amount_bif=10000`, `expires_at` correct |
| 4 | Résolution session côté client | ✅ | Champ debug `kDebugMode` ajouté ; état "expiré" et "invalide" tous deux vérifiés visuellement |
| 5 | Confirmation paiement (via `proxipay-confirm`) | ✅ | Simulée via un vrai appel API authentifié (JWT client réel) — voir note méthodologie |
| 6 | Confirmation côté Owner (temps réel) | ✅ | Transition automatique QR→attente→"Payment received ✓" sans aucune action manuelle |
| 7 | Sync offline | N/A | Hors scope V1 (voir écart ci-dessus) |

### Note méthodologie étape 5

Sur un seul émulateur, il n'est pas possible d'avoir deux sessions applicatives
actives simultanément (contrainte reconnue par le script original). Plutôt que
de se déconnecter/reconnecter (ce qui détruit l'abonnement Realtime de l'écran
Owner et invaliderait le test de l'étape 6), la confirmation client a été
déclenchée par un appel direct et authentifié à l'Edge Function déployée
`proxipay-confirm` (JWT obtenu via `POST /auth/v1/token?grant_type=password`
pour `kynza.qa.client@gmail.com`) — un appel API strictement identique à ce
qu'un second téléphone physique aurait envoyé. Cela a permis de vérifier
fidèlement le comportement réactif de l'écran Owner (étape 6) sans le perdre.
L'UI client elle-même (formulaire de confirmation, montant, nom du salon) a
été vérifiée séparément à l'étape 4 avec une seconde session.

## Données de test

- booking_id (test principal) : `77b987d8-1417-4c76-a345-a988ed418988`
- booking_id (test UI client) : `720634c9-6f55-48b1-a6d6-376bef4e6dc1`
- proxipay session_id (confirmée) : `c0c8e690-ee96-4bf5-92fc-aeafddc6299d`
- transaction : `120709a3-a466-423f-8391-85f4c6ddfe97` (`status=processing`, sandbox — `LEAPA_API_KEY` non configurée)
- idempotency_key : `77b987d8-1417-4c76-a345-a988ed418988_29716795`

## Vérifications DB finales (booking principal)

```
bookings.status             = 'completed'      ✅
transactions.status         = 'processing'     ✅ (sandbox, attendu tant que Leapa n'est pas live)
transactions.method         = 'lumicash'       ✅
proxipay_sessions.status    = 'confirmed'      ✅
proxipay_sessions.client_id = <QA client id>   ✅
```

## Bugs trouvés et corrigés

Tous **préexistants et sans rapport avec le code ProxiPay** (surfacés uniquement
parce que c'était la première fois que l'app tournait sur cet émulateur après
les changements récents) :

1. **`phosphor_flutter` 2.1.0 incompatible avec le SDK Flutter actuel** —
   `PhosphorIconData extends IconData` ne compile plus depuis qu'`IconData` est
   devenu une `final class`. Corrigé par un patch local vendored
   (`packages/phosphor_flutter/`, voir `README_PATCH.md` dans ce dossier) :
   toutes les constantes d'icônes construisent désormais un `IconData` brut au
   lieu d'une sous-classe. Le rendu duotone (jamais utilisé dans KYNZA) est
   devenu inerte — comportement documenté, sans impact.
2. **`main.dart` : `Stack` enveloppait `MaterialApp.router` au lieu de l'inverse**
   — provoquait une erreur `No Directionality widget found` à chaque
   reconstruction d'`AuthBootGate`. Corrigé en déplaçant l'overlay du loader
   dans le paramètre `builder:` de `MaterialApp.router` (pattern Flutter
   standard pour les overlays globaux).
3. **Lancement sans `--dart-define`** — `Env.supabaseUrl`/`supabaseAnonKey`
   sont vides sans les flags `--dart-define=SUPABASE_URL=...`
   `--dart-define=SUPABASE_ANON_KEY=...` (voir `.vscode/launch.json`), ce qui
   provoquait un échec de connexion silencieux à chaque tentative de
   connexion. Pas un bug de code — juste une étape de build à ne pas oublier
   en dehors de VS Code.

## Gap d'implémentation ProxiPay comblé pendant le test

- **Aucun point d'entrée UI côté client** ne menait à `ProxiPayScanScreen`
  (la route existait, mais rien ne la déclenchait). Ajouté : bouton "scanner"
  dans l'AppBar de `HomeClientScreen`, même pattern que le bouton
  "Scan loyalty" côté Owner. Un champ `kDebugMode` de saisie manuelle de
  session id a aussi été ajouté à `ProxiPayScanScreen` (caméra non fonctionnelle
  sur cet émulateur, et un seul device pour jouer les deux rôles) — jamais
  compilé en release.

## Findings mineurs (non corrigés, hors scope de ce test)

- `bookings.payment_method` reste `'cash'` après un paiement ProxiPay réussi —
  `markCompleted()` (préexistant, non modifié par ProxiPay) fixe cette valeur
  sans se soucier du mode de paiement réel. La source de vérité correcte est
  `transactions.method`. À corriger si `bookings.payment_method` devient
  affiché quelque part côté UI.
- `markCompleted()` n'écrit aucune entrée `activity_logs` (comportement
  préexistant, identique avant ProxiPay).

## Performance observée

- Détection/affichage du QR après tap "Complete & collect" : ~1-2 s (perçu, non chronométré précisément)
- Confirmation paiement → transition Owner "Payment received ✓" : quasi instantané (Realtime), < 2 s observés
- Fenêtre d'expiration session : 3 min, comportement expiré/regénération vérifié

## Vérifications finales

```
flutter analyze   → No issues found
flutter test      → 244/244 passed
dart format       → 0 changed
```

## Décision finale

☑ **VALIDÉ** — le flux ProxiPay V1 (QR) fonctionne de bout en bout, y compris
la confirmation en temps réel côté Owner sans action manuelle. Prêt pour
commit + `git push origin main`, sous réserve de revue des correctifs
préexistants listés ci-dessus (notamment le patch `phosphor_flutter`, qui
mérite un oeil humain avant merge étant donné son ampleur).
