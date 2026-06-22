# KYNZA SKILL — TESTING & QUALITY | Version 1.0 | Lire avant toute intervention

> Domaine : structure de tests Flutter/Dart, suites RLS Vitest, CI, procédures de test offline et paiement, checklist release.
> Pour le détail des policies RLS testées, voir `kynza-supabase-backend.md` ; pour le détail du flux Leapa testé, voir `kynza-payments-leapa.md`.

> ⚠️ Statut au moment de la rédaction : projet greenfield, aucun de ces fichiers n'existe encore physiquement. Ce skill décrit la structure **cible obligatoire** à créer dès les premières fondations du projet — toute nouvelle feature doit l'alimenter, pas en faire abstraction en attendant "plus tard".

## 1. Structure des tests

```
test/                              # côté Flutter
├── unit/
│   ├── usecases/
│   │   └── apply_discount_usecase_test.dart
│   └── utils/
│       └── format_bif_test.dart
├── widget/
│   └── shared/
│       └── kynza_amount_widget_test.dart
└── integration/
    └── booking_flow_test.dart     # tunnel réservation complet, intégration GoRouter + Riverpod

src/__tests__/security/             # côté Edge Functions / TS
└── rls.test.ts                     # 6 suites RLS obligatoires

tests/fixtures/
└── test-accounts.ts                # comptes de test 4 rôles × 2 salons
```

- **Unit** : `domain/usecases` et `core/utils` — aucune dépendance Flutter/Supabase, exécution rapide, à privilégier en volume.
- **Widget** : composants `shared/widgets` et écrans isolés via `ProviderScope(overrides: [...])` pour mocker les Notifiers.
- **Integration** : parcours bout-en-bout critiques (tunnel réservation, paiement, onboarding) avec un vrai (ou sandbox) backend.

## 2. Tests unitaires — exemple UseCase

```dart
// test/unit/usecases/apply_discount_usecase_test.dart
void main() {
  group('ApplyDiscountUseCase', () {
    test('Owner peut appliquer 100% de remise', () {
      final result = ApplyDiscountUseCase().execute(role: UserRole.owner, percent: 100);
      expect(result.isSuccess, true);
    });

    test('Manager ne peut pas dépasser 15% (R19)', () {
      final result = ApplyDiscountUseCase().execute(role: UserRole.manager, percent: 20);
      expect(result.isFailure, true);
      expect(result.failure?.code, 'discount_exceeds_manager_limit');
    });

    test('Staff ne peut appliquer aucune remise', () {
      final result = ApplyDiscountUseCase().execute(role: UserRole.staff, percent: 5);
      expect(result.isFailure, true);
    });

    test('Toute remise Manager > 5% doit être loggée (R19)', () {
      final result = ApplyDiscountUseCase().execute(role: UserRole.manager, percent: 10);
      expect(result.requiresAuditLog, true);
    });
  });
}
```

## 3. Tests widget — exemple composant partagé

```dart
// test/widget/shared/kynza_amount_widget_test.dart
void main() {
  testWidgets('affiche le montant formaté en mode normal', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [confidentialModeProvider.overrideWith((ref) => false)],
      child: const MaterialApp(home: KynzaAmountWidget(amountBif: 45000)),
    ));
    expect(find.text('45 000 FBu'), findsOneWidget);
  });

  testWidgets('masque le montant en mode confidentiel', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [confidentialModeProvider.overrideWith((ref) => true)],
      child: const MaterialApp(home: KynzaAmountWidget(amountBif: 45000)),
    ));
    expect(find.text('••••• FBu'), findsOneWidget);
    expect(find.textContaining('45 000'), findsNothing);
  });
}
```

## 4. Fixtures — comptes de test

```typescript
// tests/fixtures/test-accounts.ts
export const TEST_SALON_A = "11111111-1111-1111-1111-111111111111";
export const TEST_SALON_B = "22222222-2222-2222-2222-222222222222";

export const TEST_ACCOUNTS = {
  ownerA: { id: "...", role: "owner", salonId: TEST_SALON_A, phone: "+25761000001" },
  managerA: { id: "...", role: "manager", salonId: TEST_SALON_A, phone: "+25761000002" },
  staffA: { id: "...", role: "staff", salonId: TEST_SALON_A, phone: "+25761000003" },
  clientA: { id: "...", role: "client", salonId: null, phone: "+25761000004" },
  ownerB: { id: "...", role: "owner", salonId: TEST_SALON_B, phone: "+25761000005" },
};

export async function seedTestAccounts(adminClient: SupabaseClient) {
  for (const account of Object.values(TEST_ACCOUNTS)) {
    await adminClient.auth.admin.createUser({
      phone: account.phone, phone_confirm: true,
      user_metadata: { role: account.role, salon_id: account.salonId },
    });
  }
}
```

Deux salons distincts (`TEST_SALON_A`/`TEST_SALON_B`) sont indispensables pour tester l'isolation cross-tenant — un test qui ne couvre qu'un seul salon ne peut jamais prouver qu'une fuite de données inter-salon est impossible.

## 5. Les 6 suites RLS obligatoires

| Suite | Table | Vérifie |
|---|---|---|
| 1 | `transactions` | Owner only, isolation cross-salon, refus INSERT direct |
| 2 | `subscriptions` | Owner only, refus Manager/Staff |
| 3 | `bookings` | Staff voit ses RDV uniquement, Owner/Manager voient tout le salon |
| 4 | `users` | Self row only, colonnes protégées immuables (`protect_user_columns`) |
| 5 | `activity_logs` | Append-only, SELECT Owner only, whitelist `type_action` à l'INSERT |
| 6 | `loyalty_cards` | Client voit sa propre carte uniquement |

Voir `kynza-security-devsecops.md` §6 pour le template complet d'une suite. Chaque suite doit couvrir au minimum : accès autorisé, refus rôle non autorisé, isolation cross-salon, refus d'écriture hors Edge Function si applicable.

## 6. Dart analyze — zéro warning toléré

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    always_use_package_imports: true

analyzer:
  errors:
    missing_required_param: error
    avoid_print: error
```

```
flutter analyze --fatal-infos
```

Une PR avec un seul warning `dart analyze` n'est pas mergeable — pas de tolérance "on corrigera plus tard", la dette s'accumule vite sur un projet multi-agents.

## 7. Coverage — objectif 80% sur les features core

```
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Périmètre "core" exigeant ≥80% de couverture : `booking_engine` (machine à états), `payments` (idempotence, statuts), `auth` (OTP flow), `core/utils` (formatage BIF, validators). Le reste de l'app (écrans purement présentationnels) n'a pas d'objectif chiffré strict mais doit avoir au moins un test widget par composant partagé `shared/widgets`.

## 8. CI — GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
  push:
    branches: [main, staging]

jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.0' }
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - run: flutter build apk --release --no-pub # build smoke test

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run test:security
      - run: npm run typecheck
      - run: npm run lint
```

Le merge vers `main`/`staging` est bloqué si l'un des deux jobs échoue — aucune fusion "je corrigerai le lint après" tolérée sur ces branches.

## 9. Procédure de test offline

Voir `kynza-offline-realtime.md` §8 pour la procédure complète (mode avion réel, vérification Outbox, ordre de synchro, test de conflit). Toute PR touchant à une feature avec écriture offline doit documenter dans sa description que cette procédure a été exécutée manuellement, en plus des tests automatisés.

## 10. Procédure de test paiement — sandbox Leapa

1. Configurer les credentials sandbox Leapa (jamais les credentials production) dans l'environnement `dev`/`staging`.
2. **Cas succès** : initier un paiement, simuler la validation PIN côté sandbox, vérifier `transactions.status=completed`, `bookings.status=confirmed`, réception du WhatsApp de confirmation (ou log d'envoi en sandbox).
3. **Cas échec** : simuler un PIN incorrect côté sandbox, vérifier `status=failed`, créneau libéré en moins de 1.5s, message UX conforme au tableau anti-stress.
4. **Cas timeout** : laisser expirer la fenêtre de 3 min sans validation, vérifier le passage à `expired`, libération du créneau, push client.
5. **Cas double paiement** : déclencher deux requêtes avec le même `idempotency_key` dans la même minute, vérifier qu'un seul enregistrement `transactions` existe et qu'aucun second appel Leapa n'a été émis.
6. **Cas webhook signature invalide** : envoyer un payload avec une signature HMAC altérée, vérifier un rejet `401` sans aucune mutation de `transactions`/`bookings`.

## 11. Checklist avant chaque release

```
□ flutter analyze --fatal-infos clean (zéro warning)
□ flutter test passe (unit + widget + integration)
□ npm run test:security passe (6 suites RLS)
□ Build Flutter release (APK/IPA) sans erreur
□ Procédure offline (mode avion) validée manuellement sur l'écran le plus impacté par la release
□ Procédure paiement sandbox (5 cas ci-dessus) validée si la release touche au flux Leapa
□ Aucune occurrence de "SalonYawe" dans le diff (cf. AGENT.md R-DO-NOT-BREAK)
□ Aucun secret/clé API ajouté en dur dans le code ou les fichiers de config versionnés
□ Linter Supabase (migrations SQL) : 0 erreur, RLS activé sur toute nouvelle table
```

Une release qui ne peut pas cocher l'intégralité de cette liste n'est pas une release candidate — elle reste en `staging` jusqu'à résolution.
