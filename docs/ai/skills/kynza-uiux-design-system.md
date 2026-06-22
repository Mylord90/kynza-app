# KYNZA SKILL — UI/UX DESIGN SYSTEM | Version 1.0 | Lire avant toute intervention

> Domaine : tokens couleurs/typo/spacing, composants partagés obligatoires, états UI, animations, mode confidentiel.
> Ne couvre PAS : architecture des écrans (→ `kynza-flutter-architecture.md`), comportements métier (→ `kynza-booking-engine.md`).

## 1. AppColors — copier-collable

```dart
// core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark (par défaut — app dark-first)
  static const primary = Color(0xFFEAB308);
  static const primaryVariant = Color(0xFFCA8A04);
  static const background = Color(0xFF09090B);
  static const surface = Color(0xFF18181B);
  static const surfaceVariant = Color(0xFF27272A);
  static const border = Color(0xFF3F3F46);
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF97316);
  static const info = Color(0xFF3B82F6); // bleu créneau P3 / informations neutres

  // Light (variante claire — extension future)
  static const primaryLight = Color(0xFFD97706);
  static const primaryVariantLight = Color(0xFFB45309);
  static const backgroundLight = Color(0xFFFAFAFA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFF4F4F5);
  static const borderLight = Color(0xFFE4E4E7);
  static const textPrimaryLight = Color(0xFF09090B);
  static const textSecondaryLight = Color(0xFF71717A);
  static const successLight = Color(0xFF16A34A);
  static const errorLight = Color(0xFFDC2626);
  static const warningLight = Color(0xFFEA580C);

  static const ctaGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // ≈ 135°
  );

  // Glassmorphism émulé — pas de BackdropFilter, juste une surface translucide légère
  static const glassSurface = Color(0xE6181B1B); // rgba(24,24,27,0.90) approx, perf-friendly
}
```

Règle 80/15/5 : 80% `background`/`surface`, 15% `textPrimary`/`textSecondary`/icônes, 5% `primary` (accent doré réservé aux CTA, sélections, prix). Aucun écran ne doit dépasser ce ratio visuel.

## 2. AppTypography

```dart
// core/constants/app_typography.dart
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();
  static const _fontFamily = 'PlusJakartaSans'; // fallback: Inter

  static const h1 = TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w700);
  static const h2 = TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.w600);
  static const h3 = TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.w500);
  static const body = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400);
  static const button = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w600);
  static const badge = TextStyle(
    fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
  ); // toujours affiché en tout-caps via .toUpperCase()
}
```

| Niveau | Taille | Poids | Usage |
|---|---|---|---|
| H1 | 24px | Bold 700 | Titres de pages principales |
| H2 | 18px | SemiBold 600 | Noms salons, titres sections |
| H3 | 15px | Medium 500 | Prestations, prix |
| Body | 14px | Regular 400 | Commentaires, descriptions |
| Button | 14px | SemiBold 600 | Texte boutons |
| Badge | 11px | Bold 700 | Labels tout-caps (PROMOTED, SAVE) |

## 3. AppSpacing — grille 8pt

```dart
// core/constants/app_spacing.dart
class AppSpacing {
  AppSpacing._();
  static const xl = 24.0;  // paddings sections majeures
  static const lg = 16.0;  // marges extérieures universelles
  static const md = 12.0;  // espacement entre cards
  static const sm = 8.0;   // écart titre/description d'un service
  static const xs = 4.0;   // micro-alignements (icône ⭐ / note)

  static const radiusCard = 16.0;
  static const radiusButton = 12.0;
  static const radiusBottomSheet = 24.0;
  static const heightButton = 48.0;
  static const heightInput = 52.0;
  static const heightChip = 32.0;
}
```

Aucune valeur de marge/padding/radius littérale (`EdgeInsets.all(13)`) n'est tolérée hors de cette table — toujours `AppSpacing.lg`, jamais `16.0` inline.

## 4. Composants obligatoires

### KynzaButton — 3 variants
```dart
// shared/widgets/kynza_button.dart
enum KynzaButtonVariant { primary, secondary, destructive }

class KynzaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final KynzaButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;

  const KynzaButton({
    required this.label, required this.onPressed,
    this.variant = KynzaButtonVariant.primary,
    this.isLoading = false, this.isDisabled = false, super.key,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isDisabled || isLoading;
    return SizedBox(
      height: AppSpacing.heightButton,
      child: switch (variant) {
        KynzaButtonVariant.primary => Container(
            decoration: BoxDecoration(
              gradient: disabled ? null : AppColors.ctaGradient,
              color: disabled ? AppColors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: _content(textColor: Colors.black, onTap: disabled ? null : onPressed),
          ),
        KynzaButtonVariant.secondary => DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: _content(textColor: AppColors.textPrimary, onTap: disabled ? null : onPressed),
          ),
        KynzaButtonVariant.destructive => DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: _content(textColor: Colors.white, onTap: disabled ? null : _confirmDestructive(context)),
          ),
      },
    );
  }

  VoidCallback? _confirmDestructive(BuildContext context) => () {
    // R15 — pop-up de confirmation obligatoire avant toute action destructive
    showKynzaConfirmDialog(context, onConfirm: onPressed);
  };

  Widget _content({required Color textColor, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
      child: Center(
        child: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label, style: AppTypography.button.copyWith(color: textColor)),
      ),
    );
  }
}
```

`KynzaButtonVariant.destructive` déclenche **toujours** une confirmation modale (R15) — sauf le bouton `[Confirmer arrivée]` Staff qui n'utilise jamais ce variant et reste un `primary` standard (R10).

### KynzaCard
```dart
class KynzaCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const KynzaCard({required this.child, this.onTap, super.key});

  @override
  State<KynzaCard> createState() => _KynzaCardState();
}

class _KynzaCardState extends State<KynzaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: _pressed ? AppColors.primary : AppColors.border, width: 1),
          // PAS de BoxShadow — interdit pour la performance (R13)
        ),
        child: widget.child,
      ),
    );
  }
}
```

### KynzaSkeleton — shimmer (jamais de spinner seul sur écran vide, R04)
```dart
class KynzaSkeleton extends StatelessWidget {
  final double height;
  final double width;
  const KynzaSkeleton({this.height = 16, this.width = double.infinity, super.key});

  factory KynzaSkeleton.fullScreen() => const _SkeletonScreenLayout();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: AppColors.border,
      period: const Duration(milliseconds: 1200), // animation légère, GPU-friendly
      child: Container(
        height: height, width: width,
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
```

### KynzaToast — 4 niveaux
```dart
enum ToastLevel { success, error, warning, info }

void showKynzaToast({required String message, required ToastLevel level}) {
  final (color, duration, icon) = switch (level) {
    ToastLevel.success => (AppColors.success, const Duration(seconds: 2), Icons.check_circle),
    ToastLevel.error => (AppColors.error, null, Icons.error), // permanent + bouton Réessayer
    ToastLevel.warning => (AppColors.warning, const Duration(seconds: 3), Icons.warning_amber),
    ToastLevel.info => (AppColors.info, const Duration(seconds: 2), Icons.info_outline),
  };
  // toast.error : pas d'auto-dismiss, message humain sans code HTTP (cf. kynza-payments-leapa.md §8)
  _showToast(message: message, color: color, duration: duration, icon: icon, level: level);
}
```

### KynzaEmptyState — CTA obligatoire (R04)
```dart
class KynzaEmptyState extends StatelessWidget {
  final String illustrationAsset;
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;

  const KynzaEmptyState({
    required this.illustrationAsset, required this.message,
    required this.ctaLabel, required this.onCta, super.key,
  });
  // Pas de constructeur sans CTA : un écran vide sans action de redirection est interdit (R04).

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(illustrationAsset, height: 120),
        const SizedBox(height: AppSpacing.lg),
        Text(message, style: AppTypography.body, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        KynzaButton(label: ctaLabel, onPressed: onCta),
      ]),
    );
  }
}
```

### KynzaAmountWidget — mode confidentiel intégré
```dart
class KynzaAmountWidget extends ConsumerWidget {
  final int amountBif;
  const KynzaAmountWidget({required this.amountBif, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidential = ref.watch(confidentialModeProvider);
    final text = confidential ? '••••• FBu' : '${_formatBif(amountBif)} FBu';
    return Text(text, style: AppTypography.h3.copyWith(color: AppColors.textPrimary));
  }

  String _formatBif(int amount) =>
      amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}
```

Tout affichage de montant BIF dans l'app passe par `KynzaAmountWidget` — jamais un `Text('$amount FBu')` direct, sinon le mode confidentiel ne peut pas le masquer globalement.

## 5. Les 5 états UI obligatoires sur tout écran (R04)

```dart
sealed class ScreenState<T> {}
class ScreenLoading<T> extends ScreenState<T> {}
class ScreenError<T> extends ScreenState<T> { final String message; ScreenError(this.message); }
class ScreenEmpty<T> extends ScreenState<T> { final String ctaLabel; final VoidCallback onCta; ScreenEmpty(this.ctaLabel, this.onCta); }
class ScreenOffline<T> extends ScreenState<T> { final T cachedData; ScreenOffline(this.cachedData); }
class ScreenData<T> extends ScreenState<T> { final T data; ScreenData(this.data); }
```

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(myScreenProvider);
  return switch (state) {
    ScreenLoading() => const KynzaSkeleton.fullScreen(),
    ScreenError(message: final m) => KynzaEmptyState(
        illustrationAsset: 'assets/error.svg', message: m,
        ctaLabel: 'Réessayer', onCta: () => ref.invalidate(myScreenProvider)),
    ScreenEmpty(ctaLabel: final cta, onCta: final action) => KynzaEmptyState(
        illustrationAsset: 'assets/empty.svg', message: 'Rien à afficher pour le moment',
        ctaLabel: cta, onCta: action),
    ScreenOffline(cachedData: final data) => Column(children: [
        const KynzaOfflineBanner(), Expanded(child: MyDataView(data: data)),
      ]),
    ScreenData(data: final data) => MyDataView(data: data),
  };
}
```

Tout nouvel écran qui ne couvre pas ces 5 branches exhaustivement est rejeté en revue de code.

## 6. Animations — durées, courbes, règles GPU-friendly

| Interaction | Durée | Courbe | Effet |
|---|---|---|---|
| Transitions d'écrans | 200ms | `Cubic-Bezier(0.16,1,0.3,1)` | Fluide, sans saccade |
| Tap bouton/catégorie | 100ms | Linear | Ripple doré léger |
| Confirmation réservation | 400ms | Ease-out | Spinner → coche dorée + vibration haptique |
| Attente validation USSD | ~60s perçu | — | Onde Radar Pulse dorée + compte à rebours |
| Succès paiement | 2s | — | Coche verte animée + confettis discrets |
| Upgrade plan abonnement | 1.5s | Ease-in-out | Transition dorée premium + particules |
| Bascule Solo↔Team | 400ms | — | `AnimatedSwitcher` (R15) |

Règles GPU-friendly : préférer `AnimatedContainer`/`AnimatedSwitcher`/`Opacity` à des `CustomPainter` complexes ; éviter toute animation qui recalcule un `layout`/`size` à chaque frame ; pas plus d'une animation continue simultanée par écran sur device bas de gamme.

## 7. Interdictions strictes (R13, R19)

- ❌ `BackdropFilter` ou tout effet de blur — coût GPU trop élevé sur Snapdragon 460. Utiliser `AppColors.glassSurface` (couleur translucide statique) à la place.
- ❌ Lottie si RAM disponible < 3 Go (détection via `device_info_plus`) — fournir un fallback statique ou une animation Flutter native légère.
- ❌ Couleur hex hardcodée (`Color(0xFF...)`) en dehors de `app_colors.dart`.
- ❌ `BoxShadow` sur les cards — remplacé par la bordure colorée (gris → doré au tap).
- ❌ `ListView`/`Column` sans `.builder` pour toute liste potentiellement longue (salons, services, historique).

## 8. Bottom Sheets — spécifications complètes

```dart
Future<T?> showKynzaBottomSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusBottomSheet)),
    ),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
    builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
      Container( // poignée 36×4dp
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 36, height: 4,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
      ),
      Flexible(child: child),
    ]),
  );
}
```

Glissement bas→haut, hauteur max 85% de l'écran, arrondi 24dp en haut uniquement, poignée 36×4dp toujours visible en tête.

## 9. Mode confidentiel — toggle 👁

```dart
// core/providers/confidential_mode_provider.dart
final confidentialModeProvider = NotifierProvider<ConfidentialModeNotifier, bool>(
  ConfidentialModeNotifier.new,
);

class ConfidentialModeNotifier extends Notifier<bool> {
  @override
  bool build() => _loadPersisted(); // persiste entre les écrans (Hive ou SharedPreferences)

  void toggle() {
    state = !state;
    _persist(state);
  }
}
```

```dart
// shared/widgets/confidential_toggle_icon.dart
IconButton(
  icon: Icon(confidential ? Icons.visibility_off : Icons.visibility),
  onPressed: () => ref.read(confidentialModeProvider.notifier).toggle(),
)
```

Tout montant affiché à l'écran (revenus, prix, CA) doit lire `confidentialModeProvider` via `KynzaAmountWidget` (section 4) — aucune exception, y compris dans les widgets de dashboard, les notifications in-app, et les exports PDF si le mode est actif au moment de l'export.
