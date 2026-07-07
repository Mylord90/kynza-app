# Firebase Android — Vérification & Certification

**Statut**: Vérification complète, 2026-07-07. **Périmètre**: Firebase Android strictement — aucune
configuration iOS touchée (roadmap iOS non tranchée). **Référence backend**: `docs/KYNZA_BACKEND_MAINTENANCE_HANDBOOK.md`.
**Méthode**: chaque affirmation ci-dessous est sourcée à une inspection directe du repo ou à une
commande/test exécuté(e) dans cette session — aucune reprise d'affirmation non vérifiée. Ce qui n'a
pas pu être vérifié directement est marqué **[À CONFIRMER]**.

---

## Checkpoint 1 — `google-services.json`

- **Emplacement**: `android/app/google-services.json` — présent, bon emplacement.
- **Git**: fichier **non suivi** par git (`git ls-files` retourne vide), ignoré via `.gitignore:50`
  (`android/app/google-services.json`). Confirme exactement le commentaire déjà présent dans
  `android/app/build.gradle.kts:9-15` : le fichier n'existe pas dans un checkout neuf, appliqué
  conditionnellement (`hasGoogleServicesConfig = file("google-services.json").exists()`).
- **Comparaison champ par champ** avec le fichier fourni par Mylord (protocole ci-dessus, point 4
  — identité complète) :

  | Champ | Fichier repo | Fichier fourni | Identique ? |
  |---|---|---|---|
  | `project_number` | 556359616754 | 556359616754 | ✅ |
  | `project_id` | kynza-f68d6 | kynza-f68d6 | ✅ |
  | `storage_bucket` | kynza-f68d6.firebasestorage.app | kynza-f68d6.firebasestorage.app | ✅ |
  | `mobilesdk_app_id` | 1:556359616754:android:aebd558ac5f306b99c286b | idem | ✅ |
  | `package_name` | com.kynza.app | com.kynza.app | ✅ |
  | `current_key` (API key) | AIzaSyDCy5AMuY0Lp2Q8OxFKTtSkYANbwoX2mm8 | idem | ✅ |

  **Aucune divergence** — rien remplacé, rien écrasé, conforme au protocole point 4 ("ne rien
  faire, documenter que la vérification a eu lieu").
- **Cohérence `package_name`**: `android/app/build.gradle.kts:48` → `applicationId = "com.kynza.app"`
  — identique au `package_name` du fichier. ✅
- **SHA-1/SHA-256**: le fichier ne contient **aucune entrée `oauth_client`** (`"oauth_client": []`
  vide dans les deux versions) — donc **aucun SHA-1 n'est actuellement enregistré** dans ce
  `google-services.json`, quel que soit le keystore. C'est cohérent avec le fait que l'app n'utilise
  pas Google Sign-In (Supabase Auth uniquement) — un SHA-1 vide n'est donc **pas bloquant** pour
  Crashlytics/FCM, qui s'authentifient via l'API key + `package_name` + `app_id`, pas via empreinte
  de certificat. Un SHA-1 ne redeviendra nécessaire que si Google Sign-In ou Play Integrity (App
  Check) sont un jour activés. **[À CONFIRMER côté Firebase Console]** : si un SHA-1 y est
  effectivement enregistré (pour Play Integrity, cf. Checkpoint 9), il s'agirait du keystore debug
  — dette déjà connue, non traitée ici (Règle 4).

## Checkpoint 2 — Configuration Gradle

- **Plugins déclarés** (`android/settings.gradle.kts:20-26`): `com.google.gms.google-services`
  4.5.0, `com.google.firebase.crashlytics` 3.0.6 — appliqués conditionnellement dans
  `android/app/build.gradle.kts:16-20` uniquement si `google-services.json` existe (dégradation
  gracieuse déjà en place et documentée dans le code).
- **AGP** 9.0.1, **Kotlin** 2.3.20, **Gradle wrapper** 9.1.0 — installés et fonctionnels (confirmé
  par un build réel, voir plus bas).
- **BoM Firebase**: aucun `platform("com.google.firebase:firebase-bom:...")` déclaré au niveau
  `app/build.gradle.kts`. **Ce n'est pas une anomalie** : chaque plugin FlutterFire installé
  (`firebase_core` 3.15.2, `firebase_crashlytics` 4.3.10, `firebase_messaging` 15.2.10,
  `firebase_performance` 0.10.1+10, versions résolues via `pubspec.lock`) embarque et gouverne sa
  propre version native Firebase Android en interne — c'est le pattern correct pour un projet
  n'ajoutant aucune dépendance Firebase native brute. Confirmé : `GeneratedPluginRegistrant.java`
  ne liste que ces 4 plugins Firebase, aucun autre.
- **Compatibilité Flutter/Gradle réelle** (pas supposée): `flutter --version` → Flutter 3.44.2,
  Dart 3.12.2, installés et vérifiés en direct.
- **Preuve réelle de compilation**: `flutter build apk --debug` a réussi
  (`√ Built build\app\outputs\flutter-apk\app-debug.apk`, voir note d'environnement plus bas) —
  preuve directe que les plugins `google-services`/`crashlytics` s'appliquent et fusionnent le
  manifeste sans conflit avec `google-services.json` présent.
- **Note d'environnement (hors périmètre Firebase, non corrigée)**: le premier essai de build a
  échoué avec un **crash JVM du daemon Gradle par Out-Of-Memory natif** — la machine de dev ne
  dispose que de **7 Go de RAM physique** (confirmé par le log de crash lui-même :
  `Host: ... 7G`), alors que `android/gradle.properties` fixe `org.gradle.jvmargs=-Xmx8G` — un
  heap alloué au seul daemon Gradle qui dépasse déjà la RAM totale de la machine. Un override
  temporaire (`-Xmx3G`) a été utilisé uniquement pour cette session de vérification puis **annulé
  intégralement** (`git diff` confirmé vide sur ce fichier en fin de session) — je n'ai pas
  modifié ce réglage de façon permanente car il est hors du périmètre strict "Firebase Android"
  (Règle 3) et affecte tout le projet. **À votre décision, Mylord** : `-Xmx8G` est probablement
  à revoir pour tout développement Android local sur cette machine, indépendamment de Firebase.

## Checkpoint 3 — FlutterFire

- **`firebase_options.dart`**: **n'existe nulle part** dans `lib/` (recherche directe, zéro
  résultat). FlutterFire CLI n'a **jamais été exécuté** sur ce projet — confirmé par absence, pas
  supposé.
- **`main.dart:92`**: `await Firebase.initializeApp();` — appelé **sans argument** (pas
  `DefaultFirebaseOptions.currentPlatform`). C'est un pattern valide et suffisant pour une
  intégration **Android-only** : le plugin Gradle `google-services` génère les ressources natives
  à partir de `google-services.json` au moment du build, et `Firebase.initializeApp()` sans
  options les lit automatiquement côté natif Android.
- **Décision prise cette session**: je n'ai **pas** exécuté `flutterfire configure` — l'intégration
  actuelle n'est pas "absente ou incohérente" au sens du protocole, juste un pattern différent
  (natif-only) de celui de la CLI, et tout aussi valide tant que seul Android est ciblé. Le jour où
  iOS démarre, `flutterfire configure` deviendra la manière standard de générer un
  `firebase_options.dart` multi-plateforme cohérent — **à réévaluer à ce moment-là**, pas
  maintenant (roadmap iOS non tranchée, hors périmètre explicite de cette session).

## Checkpoint 4 — Packages Flutter Firebase

| Package | Déclaré (`pubspec.yaml`) | Résolu (`pubspec.lock`) |
|---|---|---|
| `firebase_core` | `^3.0.0` | `3.15.2` |
| `firebase_messaging` | `^15.0.0` | `15.2.10` |
| `firebase_crashlytics` | `^4.0.0` | `4.3.10` |
| `firebase_performance` | `^0.10.0` | `0.10.1+10` |
| `firebase_analytics` | **absent** | — |
| `firebase_app_check` | **absent** | — |

- `flutter pub get` exécuté en direct : résolution propre, aucun conflit de version.
- `firebase_analytics` : **aucune trace nulle part** — ni dépendance, ni import Dart, ni entrée
  dans `GeneratedPluginRegistrant.java`. Analytics n'est **pas intégré**, malgré ce qui pourrait
  être activé côté Firebase Console (Checkpoint 10).
- `firebase_app_check` : **aucune dépendance** — confirmé absent également de
  `GeneratedPluginRegistrant.java`. C'est **intentionnel et documenté** (Checkpoint 9), pas un
  oubli.

## Checkpoint 5 — Initialisation Firebase (`main.dart`)

- Ordre correct : `WidgetsFlutterBinding.ensureInitialized()` (l.46) → `Firebase.initializeApp()`
  (l.92) → `CrashReportingService.init()` (l.93) → `PerformanceMonitoringService.startColdStartTrace()`
  (l.94) → `FirebaseMessaging.onBackgroundMessage(...)` (l.95).
- **Constat réel (pas une hypothèse)** : `_bootstrap()` s'exécute dans
  `runZonedGuarded(_bootstrap, (error, stack) => CrashReportingService.recordError(error, stack))`
  (`main.dart:40-43`). Si `Firebase.initializeApp()` lui-même échoue, le handler de zone appelle
  `CrashReportingService.recordError` → `FirebaseCrashlytics.instance.recordError(...)` — **mais
  Crashlytics dépend justement de Firebase pour fonctionner**. Un échec réel de
  `Firebase.initializeApp()` risquerait donc de ne **pas** être rapporté de façon fiable (risque de
  double-échec silencieux dans le handler de zone lui-même). C'est une lacune réelle identifiée par
  lecture directe du code, pas testée en conditions réelles (aurait nécessité de corrompre
  volontairement `google-services.json`, jugé hors propos). **Je ne l'ai pas corrigée** — le bon
  comportement de repli (l'app doit-elle démarrer sans Firebase ? afficher un écran d'erreur ?)
  est une décision produit qui vous revient, pas une correction que je dois improviser (Règle 2).

## Checkpoint 6 — `AndroidManifest.xml`

- **Meta-data FCM** (`android/app/src/main/AndroidManifest.xml:71-76`) : icône
  (`@drawable/ic_notification`, fichier confirmé présent) et couleur (`@color/notification_gold`,
  confirmée dans `colors.xml`) correctement déclarées.
- **`POST_NOTIFICATIONS`** : **non déclarée explicitement** dans le manifeste applicatif, mais
  **auto-fusionnée** depuis le manifeste propre du plugin `firebase_messaging-15.2.10`
  (`<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`, inspecté
  directement dans le plugin installé) — confirmé fonctionnel, la fusion de manifeste Android l'a
  bien intégrée (le build réel n'aurait pas échoué sinon).
- **App Check / Analytics** : aucune meta-data présente — cohérent avec l'absence des SDK
  correspondants (Checkpoints 4/9/10), pas une omission.
- Rien d'autre modifié dans ce fichier (deep links, permissions biométriques retirées — hors
  périmètre, non touchés).

## Checkpoint 7 — Firebase Messaging (test réel)

Test exécuté sur l'émulateur **Kynza_Pixel6** (image `google_apis` — Play Services présents, pas
le Play Store complet) :

- **Firebase Installations SDK** : un vrai `InstallationTokenResult` a été généré côté natif
  (log `com.google.firebase.installations.InstallationTokenResult$Builder.build()`), confirmant
  que le pipeline natif de génération de token (préalable à un token FCM) fonctionne réellement.
- **Constat de code (`lib/core/widgets/auth_boot_gate.dart:24-29`)** : `NotificationService.initialize()`
  — qui appelle `requestPermission()` puis `getToken()` — n'est déclenché **qu'après connexion
  réussie** (transition vers `AuthAuthenticated`). C'est **intentionnel** (ne pas demander la
  permission de notification avant login), pas un bug.
- **Limite réelle de cette session** : je n'avais pas d'identifiants de connexion valides pour le
  projet Supabase de **production** (`hhdkjfpgaklhrhfoxlhj`), donc impossible d'obtenir une session
  authentifiée et donc un vrai token FCM ou un test foreground/background/terminated complet.
- **Conclusion honnête** : la tuyauterie native FCM est prouvée fonctionnelle jusqu'au point
  d'authentification ; la récupération réelle du token et le comportement des 3 états de message
  restent **[À CONFIRMER]** — nécessite soit des identifiants de test fournis par Mylord, soit un
  passage manuel avec un vrai compte.

## Checkpoint 8 — Crashlytics (test réel, pas une lecture de config)

Deux crashs réels provoqués sur le même émulateur, preuve capturée par logs horodatés :

1. **Crash Dart réel** (assertion `Env.supabaseUrl.startsWith('https://')` échouée,
   `main.dart:98` — dû à l'absence de `--dart-define` lors de l'installation ad hoc de l'APK, pas
   un bug applicatif) :
   ```
   07-07 20:24:24.009 I/flutter: ----------------FIREBASE CRASHLYTICS----------------
   07-07 20:24:24.026 I/flutter: 'package:kynza/main.dart': Failed assertion: line 98 pos 5...
   07-07 20:24:24.028 I/flutter: #2 _bootstrap (package:kynza/main.dart:98:5)
   07-07 20:24:24.037 I/flutter: ----------------------------------------------------
   ```
   → Preuve directe et non fabriquée que `runZonedGuarded` → `CrashReportingService.recordError`
   → `FirebaseCrashlytics.instance.recordError(...)` fonctionne de bout en bout avec stack trace
   complète.
2. **Crash natif forcé** (`adb shell am crash com.kynza.app`) → `FATAL EXCEPTION` /
   `CrashedByAdbException` réel, suivi au lancement suivant de :
   ```
   07-07 20:24:47.556 E/FirebaseCrashlytics: Cannot send reports. Timed out while fetching settings.
   ```
   → Preuve que le SDK tente réellement une communication réseau vers le backend Firebase au
   démarrage suivant — l'échec est un **timeout réseau de l'environnement sandbox/émulateur**, pas
   un défaut de code.
- **Ce qui n'est PAS vérifié** : la réception côté serveur (Firebase Console) — aucun accès
  console dans cette session. **Action recommandée pour Mylord** : vérifier le dashboard
  Crashlytics du projet `kynza-f68d6` pour confirmer que l'un des deux événements est bien arrivé
  côté serveur (la capture + tentative de transmission locale sont prouvées ; la réception
  distante reste **[À CONFIRMER]**).

## Checkpoint 9 — App Check (état réel, pas supposé)

- **Confirmé par inspection directe** : App Check est un **scaffold délibérément inerte et
  documenté** (`lib/core/security/app_check_service.dart`, `app_check_feature_gate.dart`,
  `docs/security/APP_CHECK_ARCHITECTURE.md`). `AppCheckService.headers()` retourne toujours `{}`
  aujourd'hui.
- **Aucune dépendance `firebase_app_check`** n'existe (pubspec.yaml, pubspec.lock,
  `GeneratedPluginRegistrant.java` — tous confirment l'absence).
- **Double gate** (`Env.appCheckEnabled` + feature flag) — les deux à `false` par défaut, prouvé
  inerte par `test/unit/app_check_feature_gate_test.dart` (dans les 411 tests qui passent).
- **Réponse à la question du prompt** : peu importe ce qui est activé côté Firebase Console
  (App Check), **aucun token n'est produit ni vérifié côté app** aujourd'hui — c'est l'état attendu
  à ce stade (pas de keystore release → pas d'attestation Play Integrity possible de toute façon).
  Procédure d'activation déjà documentée dans `APP_CHECK_ARCHITECTURE.md` §3, non ré-exécutée ici
  (hors périmètre — activerait potentiellement un changement d'échelle, Règle 6).

## Checkpoint 10 — Analytics (état réel)

- **Confirmé absent** : `firebase_analytics` n'est dépendance nulle part, zéro import Dart, zéro
  entrée native (`GeneratedPluginRegistrant.java`).
- **Aucun événement de test n'a pu être envoyé** — il n'y a rien à déclencher, pas un problème de
  configuration à corriger. Ajouter le package serait un vrai changement de scope (nouvelle
  dépendance native + cycle de build), pas une correction de ce qui existe déjà — décision à
  prendre séparément, pas improvisée ici (Règle 2, et instruction explicite du prompt).
- **Proposition d'événements funnel KYNZA critiques** (à instrumenter *si* Analytics est ajouté un
  jour) : `sign_up`/`login`, `booking_created`, `payment_completed` (Leapa/ProxiPay), `loyalty_stamp_earned`,
  `loyalty_reward_redeemed`, `referral_claimed`. Non implémenté dans cette session.

## Checkpoint 11 — Non-régression

- `flutter analyze` → **"No issues found!"** (42.5s) — conforme au 0-issue attendu.
- `flutter test` → **`+411 ~5`, "All tests passed!"** — correspondance **exacte** avec le chiffre
  cité par le Handbook (`411 passed, 5 skipped`). Aucun écart, aucune régression.
- `git status --porcelain -uno` en fin de session → **vide**, aucune modification de fichier suivi
  ne subsiste (l'unique édition temporaire de `gradle.properties` a été intégralement annulée).

## Checkpoint 12 — Certification finale

| Question | Réponse | Preuve |
|---|---|---|
| Firebase Android entièrement intégré ? | **Partiellement.** Crashlytics + FCM + Performance réellement câblés et testés en conditions réelles (CP7/CP8, avec les 2 réserves ci-dessus). Analytics et App Check **non intégrés** au niveau SDK — confirmé, pas supposé. | CP4, CP7, CP8, CP9, CP10 |
| FlutterFire correctement configuré ? | **Pas via la CLI** — aucun `firebase_options.dart`. L'app utilise le pattern natif-only (`Firebase.initializeApp()` + `google-services.json`), valide pour Android-only. À revoir si iOS démarre. | CP3 |
| `firebase_options.dart` valide et cohérent avec `google-services.json` ? | **N/A** — le fichier n'existe pas. `google-services.json` lui-même vérifié 100% identique à celui fourni par Mylord. | CP1, CP3 |
| Dépendances Firebase cohérentes en version ? | **Oui** — 4 packages installés, résolution propre, build réel réussi, `flutter analyze`/`test` sans régression. | CP2, CP4, CP11 |
| Prête pour des tests Android réels ? | **Oui**, avec 2 réserves explicites : token FCM complet non observé (besoin d'un vrai login), réception Crashlytics côté serveur non confirmée (besoin d'un accès Console). | CP7, CP8 |

### Dépendances externes encore ouvertes (reprises telles quelles du Handbook, pas une nouvelle liste)

- **Keystore Android release** — jamais généré, `android/key.properties` confirmé absent cette
  session (non touché, Règle 4). Bloque tout SHA-1 release et donc Play Integrity/App Check réel.
- **Google Play Console** — Data Safety form non démarré, pas de clé d'upload réelle.
- **iOS** — non démarré, hors périmètre de cette session.
- **Contenu légal réel** — sans lien avec Firebase, déjà documenté ailleurs (Handbook §3.12).

### Ce qui reste volontairement non traité dans cette session

- Génération du keystore release (Règle 4 — jamais automatisé).
- Activation réelle de `firebase_app_check` / `firebase_analytics` (changement de scope, décision
  produit séparée).
- Correctif de la lacune de gestion d'erreur CP5 (décision produit sur le comportement de repli).
- Réglage `-Xmx8G` de `android/gradle.properties` (hors périmètre strict Firebase, affecte tout le
  projet).

---

*(Aucun commit créé pour cette session — voir note ci-dessous : aucune configuration Firebase
n'a été modifiée, seulement vérifiée et prouvée par des tests réels. Ce document est nouveau et
prêt à être commité à la demande de Mylord.)*
