# KYNZA SKILL — FLUTTER ARCHITECTURE | Version 1.0 | Lire avant toute intervention

> Domaine : structure de code Flutter, Clean Architecture, Riverpod, GoRouter, conventions.
> Ne couvre PAS : RLS/SQL (→ `kynza-supabase-backend.md`), design tokens (→ `kynza-uiux-design-system.md`), paiements (→ `kynza-payments-leapa.md`).

## 1. Structure de dossiers — feature-first obligatoire

Aucune exception. Un fichier qui ne rentre dans aucune de ces trois racines est mal placé.

```
lib/
├── main.dart                     # bootstrap, ProviderScope, runApp
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # tokens couleur (jamais de hex ailleurs)
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   ├── theme/
│   │   └── app_theme.dart        # ThemeData dark-first + light
│   ├── router/
│   │   ├── app_router.dart       # GoRouter root config
│   │   ├── route_guards.dart     # guards par rôle
│   │   └── routes.dart           # constantes de chemin (pas de string littérale ailleurs)
│   ├── providers/
│   │   ├── session_provider.dart # rôle, salon_id, JWT courant
│   │   └── connectivity_provider.dart
│   ├── models/
│   │   └── *.dart                # modèles partagés entre features (freezed)
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── session_service.dart
│   │   └── connectivity_service.dart
│   ├── utils/
│   │   ├── formatters.dart       # formatBif(), formatDate()
│   │   └── validators.dart
│   └── enums/
│       ├── user_role.dart
│       ├── booking_status.dart
│       └── payment_status.dart
├── shared/
│   └── widgets/
│       ├── kynza_button.dart
│       ├── kynza_card.dart
│       ├── kynza_skeleton.dart
│       ├── kynza_toast.dart
│       ├── kynza_empty_state.dart
│       ├── kynza_offline_banner.dart
│       └── kynza_amount_widget.dart
└── features/
    ├── auth/
    ├── home_owner/
    ├── home_staff/
    ├── home_client/
    ├── payments/
    ├── notifications/
    └── subscription/
```

Une feature isolée (ex. `auth`) suit toujours ce sous-découpage :

```
features/auth/
├── data/
│   ├── datasources/
│   │   └── auth_remote_datasource.dart   # appels Supabase bruts
│   └── repositories/
│       └── auth_repository_impl.dart     # implémente le contrat domain
├── domain/
│   ├── entities/
│   │   └── auth_user.dart                # entité pure, pas de dépendance Supabase
│   ├── repositories/
│   │   └── auth_repository.dart          # contrat abstrait (interface)
│   └── usecases/
│       ├── send_otp_usecase.dart
│       └── verify_otp_usecase.dart
└── presentation/
    ├── providers/
    │   └── auth_provider.dart            # Riverpod Notifier
    ├── screens/
    │   ├── phone_input_screen.dart
    │   └── otp_verify_screen.dart
    └── widgets/
        └── otp_input_field.dart
```

**Règle absolue** : `domain/` ne dépend jamais de Supabase, Flutter ou Hive. C'est la couche testable en isolation totale.

## 2. Flux Clean Architecture — sens unique strict

```
Widget (presentation/screens, widgets)
   │  écoute / appelle
   ▼
Notifier / Cubit (presentation/providers)
   │  appelle
   ▼
UseCase (domain/usecases)
   │  dépend de l'interface
   ▼
Repository — contrat abstrait (domain/repositories)
   ▲  implémenté par
   │
Repository — implémentation (data/repositories)
   │  appelle
   ▼
DataSource (data/datasources) → Supabase / Hive / API externe
```

- Un Widget n'appelle **jamais** un Repository ou un DataSource directement.
- Un UseCase ne connaît **jamais** Supabase — il dépend uniquement de l'interface `domain/repositories`.
- Une Entity (`domain/entities`) est un objet immuable sans logique d'I/O.

### ❌ Mauvais — logique métier + accès réseau dans le widget
```dart
class BookingButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final res = await Supabase.instance.client
            .from('bookings')
            .insert({'salon_id': salonId, 'status': 'pending_payment'});
        if (res.error == null) { /* ... */ }
      },
      child: const Text('Réserver'),
    );
  }
}
```

### ✅ Bon — widget ne fait qu'écouter et déclencher
```dart
class BookingButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingProvider);
    return KynzaButton(
      label: 'Réserver',
      isLoading: state.isLoading,
      onPressed: () => ref.read(bookingProvider.notifier).createBooking(),
    );
  }
}
```

## 3. Riverpod — organisation des providers

Quatre familles, chacune avec son usage strict :

| Type | Usage | Exemple |
|---|---|---|
| `Provider` | valeur calculée/synchrone, sans état mutable | `appColorsProvider` |
| `StateNotifierProvider` / `NotifierProvider` | état mutable avec actions explicites | `bookingProvider` (créer, annuler RDV) |
| `FutureProvider` | fetch asynchrone unique, pas de mutation | `salonDetailsProvider(salonId)` |
| `StreamProvider` | flux temps réel (Supabase Realtime) | `calendarStreamProvider(salonId)` |

### Notifier — pattern de référence
```dart
// presentation/providers/booking_provider.dart
final bookingProvider =
    NotifierProvider<BookingNotifier, BookingState>(BookingNotifier.new);

class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState.initial();

  Future<void> createBooking(BookingDraft draft) async {
    state = state.copyWith(isLoading: true, error: null);
    final usecase = ref.read(createBookingUseCaseProvider);
    final result = await usecase.execute(draft);
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure.message),
      (booking) => state.copyWith(isLoading: false, booking: booking),
    );
  }
}
```

### StreamProvider — Realtime agenda
```dart
final calendarStreamProvider =
    StreamProvider.family<List<Booking>, String>((ref, salonId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('bookings')
      .stream(primaryKey: ['id'])
      .eq('salon_id', salonId)
      .map((rows) => rows.map(Booking.fromJson).toList());
});
```

### Injection des dépendances — toujours via Provider, jamais de singleton global
```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider));
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.watch(authRepositoryProvider));
});
```

## 4. GoRouter — configuration et guards par rôle

```dart
// core/router/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  return GoRouter(
    initialLocation: Routes.discover,
    redirect: (context, state) => routeGuard(state, session),
    routes: [
      GoRoute(
        path: Routes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.bookingDetail,           // /booking/:id
        name: 'bookingDetail',
        builder: (context, state) =>
            BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
    ],
  );
});
```

```dart
// core/router/route_guards.dart
String? routeGuard(GoRouterState state, SessionState session) {
  final role = session.role;
  final path = state.matchedLocation;

  if (_ownerOnlyRoutes.contains(path) && role != UserRole.owner) {
    return Routes.forbidden;
  }
  if (_staffRoutes.contains(path) && role != UserRole.staff) {
    return Routes.forbidden;
  }
  if (session.isGuest && _authRequiredRoutes.any(path.startsWith)) {
    return Routes.phoneInput;
  }
  return null; // pas de redirection
}
```

- Toute route doit apparaître dans `core/router/routes.dart` comme constante — jamais de string littérale `'/dashboard'` dispersée dans le code.
- Deep links (`/booking/:id`, `/payment/:id`) doivent être déclarés explicitement avec `pathParameters`, jamais parsés à la main.
- Le guard se base sur `session.role`, jamais sur un état local au widget.

## 5. Conventions de nommage

| Élément | Convention | Exemple |
|---|---|---|
| Fichier | `snake_case.dart` | `booking_provider.dart` |
| Classe | `PascalCase` | `BookingNotifier` |
| Variable / méthode | `camelCase` | `createBooking()` |
| Constante | `camelCase` (pas de `SCREAMING_CASE` en Dart) | `maxBookingsFree` |
| Provider | suffixe `Provider` | `bookingProvider`, `salonDetailsProvider` |
| UseCase | suffixe `UseCase`, verbe à l'infinitif | `CreateBookingUseCase` |
| Repository (interface) | suffixe `Repository` | `BookingRepository` |
| Repository (impl) | suffixe `RepositoryImpl` | `BookingRepositoryImpl` |
| DataSource | suffixe `DataSource` | `BookingRemoteDataSource` |
| Widget partagé | préfixe `Kynza` | `KynzaButton`, `KynzaCard` |
| Enum | nom singulier | `BookingStatus`, `UserRole` |

Tout fichier généré par un agent IA respecte cette table sans dérogation.

## 6. Exemple complet — feature `auth` (tous les layers)

### domain/entities/auth_user.dart
```dart
class AuthUser {
  final String id;
  final String salonId;
  final UserRole role;
  final String phone;
  final bool profileCompleted;

  const AuthUser({
    required this.id,
    required this.salonId,
    required this.role,
    required this.phone,
    required this.profileCompleted,
  });
}
```

### domain/repositories/auth_repository.dart
```dart
abstract class AuthRepository {
  Future<Result<void, Failure>> sendOtp(String phone);
  Future<Result<AuthUser, Failure>> verifyOtp(String phone, String code);
}
```

### domain/usecases/verify_otp_usecase.dart
```dart
class VerifyOtpUseCase {
  final AuthRepository _repository;
  const VerifyOtpUseCase(this._repository);

  Future<Result<AuthUser, Failure>> execute(String phone, String code) {
    return _repository.verifyOtp(phone, code);
  }
}
```

### data/datasources/auth_remote_datasource.dart
```dart
class AuthRemoteDataSource {
  final SupabaseClient _client;
  const AuthRemoteDataSource(this._client);

  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthUser> verifyOtp(String phone, String code) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: code,
      type: OtpType.sms,
    );
    final row = await _client
        .from('users')
        .select()
        .eq('id', res.user!.id)
        .single();
    return AuthUser(
      id: row['id'],
      salonId: row['salon_id'],
      role: UserRole.fromString(row['role']),
      phone: row['phone'],
      profileCompleted: row['profile_completed'],
    );
  }
}
```

### data/repositories/auth_repository_impl.dart
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  const AuthRepositoryImpl(this._remote);

  @override
  Future<Result<void, Failure>> sendOtp(String phone) async {
    try {
      await _remote.sendOtp(phone);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(Failure.fromException(e));
    }
  }

  @override
  Future<Result<AuthUser, Failure>> verifyOtp(String phone, String code) async {
    try {
      final user = await _remote.verifyOtp(phone, code);
      return Result.success(user);
    } catch (e) {
      return Result.failure(Failure.fromException(e));
    }
  }
}
```

### presentation/providers/auth_provider.dart
```dart
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.idle();

  Future<void> verifyOtp(String phone, String code) async {
    state = const AuthState.loading();
    final usecase = ref.read(verifyOtpUseCaseProvider);
    final result = await usecase.execute(phone, code);
    state = result.fold(
      (failure) => AuthState.error(failure.message),
      (user) => AuthState.authenticated(user),
    );
  }
}
```

### presentation/screens/otp_verify_screen.dart
```dart
class OtpVerifyScreen extends ConsumerWidget {
  final String phone;
  const OtpVerifyScreen({required this.phone, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    return Scaffold(
      body: switch (state) {
        AuthLoading() => const KynzaSkeleton.fullScreen(),
        AuthError(message: final m) => KynzaEmptyState(
            message: m,
            ctaLabel: 'Réessayer',
            onCta: () => ref.invalidate(authProvider),
          ),
        AuthAuthenticated() => const SizedBox.shrink(), // redirection via router
        _ => OtpInputField(
            onSubmit: (code) =>
                ref.read(authProvider.notifier).verifyOtp(phone, code),
          ),
      },
    );
  }
}
```

Ce squelette est le gabarit à reproduire pour `home_owner`, `home_staff`, `home_client`, `payments`, `notifications`, `subscription`.

## 7. Erreurs communes et corrections

| Erreur fréquente | Pourquoi c'est un problème | Correction |
|---|---|---|
| Appel `Supabase.instance.client` directement dans un widget | Logique métier hors couche, impossible à tester, viole R09 | Passer par DataSource → Repository → UseCase → Provider |
| `Color(0xFFEAB308)` hardcodé dans un widget | Viole R19, design system non centralisé | Utiliser `AppColors.primary` |
| `ListView(children: [...])` pour une liste de salons/services | Rend tous les items même hors écran, tue les perfs sur device bas de gamme | `ListView.builder(itemBuilder: ...)` |
| Provider recréé à chaque `build()` avec `Provider((ref) => MyService())` sans `autoDispose` ni état partagé voulu | Fuite mémoire ou état dupliqué | Déclarer le provider une seule fois au niveau fichier, jamais inline dans `build()` |
| `salonId` passé en paramètre depuis le client vers une requête Supabase | Viole R02 — le salon_id doit venir du JWT côté RLS, pas être un paramètre de confiance | Filtrer côté RLS via `auth.jwt()->>'salon_id'`, ne jamais faire confiance à un `salonId` transmis par le client pour l'autorisation |
| Écran qui affiche directement les données sans gérer `loading`/`error`/`empty`/`offline` | Viole R04, écran vide sans CTA possible | Toujours un `switch` exhaustif sur l'état (voir exemple `OtpVerifyScreen`) |
| Pop-up de confirmation ajoutée sur `[Confirmer arrivée]` Staff | Viole R10 explicitement | Action directe, aucun `showDialog` sur ce bouton |
| `flutter_bloc` et `Riverpod` mélangés dans une même feature | Incohérence d'architecture, double state management | Riverpod par défaut sur tout nouveau code ; `flutter_bloc` toléré uniquement si feature legacy déjà écrite ainsi |
| Logique de calcul de prix/réduction dans `presentation/screens` | Viole la séparation Clean Architecture | Déplacer dans un UseCase dédié (`ApplyDiscountUseCase`) |
| Repository qui retourne directement une exception Supabase brute au Notifier | Le Notifier ne doit pas connaître les types d'erreur Supabase | Wrapper systématique dans `Result<T, Failure>` au niveau Repository |
