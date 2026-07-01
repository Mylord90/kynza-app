# KYNZA — Audit des indicateurs de chargement (pré-implémentation KynzaLoader)

> Généré avant toute ligne de code du composant `KynzaLoader`, conformément au protocole d'exécution du prompt Loader Premium. Baseline confirmée avant ce scan : `flutter analyze` → 0 issue, `flutter test` → 191/191.

## Constat clé

Le projet a **déjà** un point de passage unique : `KynzaSpinner`
(`lib/shared/widgets/kynza_spinner.dart`), un `RotationTransition` autour
d'un seul `CircularProgressIndicator`. Il n'y a donc **pas** ~15 contextes
disparates à migrer un par un comme le scénario générique du prompt le
suppose — il y a 1 widget interne à remplacer (`KynzaSpinner` →
`KynzaLoader`) + 1 occurrence brute isolée + le cas `RefreshIndicator`
(Phase 5.5) à styler.

## 1. Occurrences brutes de `CircularProgressIndicator`

| Fichier | Ligne | Contexte | Taille | Couleur |
|---|---|---|---|---|
| `lib/shared/widgets/kynza_spinner.dart` | 39 | Interne à `KynzaSpinner` (rotation + spinner) | `widget.size` (défaut 20) | `widget.color` (défaut `AppColors.primary`) |
| `lib/features/evolution/version_manager/presentation/screens/force_update_screen.dart` | 130 | Icône de bouton (`FilledButton.icon`) pendant l'ouverture du store | 18×18, `strokeWidth: 2` | `AppColors.background` (sombre sur bouton plein gold) |

## 2. Occurrences de `KynzaSpinner` (à migrer vers `KynzaLoader*`)

| Fichier | Ligne | Contexte | Taille actuelle | Mapping cible |
|---|---|---|---|---|
| `lib/shared/widgets/kynza_button.dart` | 82 | État de chargement de bouton (remplace le label) | 20 | `KynzaLoaderButton` |
| `lib/shared/widgets/kynza_loading_overlay.dart` | 22 | Overlay plein écran bloquant (OAuth, vérif. invitation/parrainage) | 32 | Devient `KynzaLoaderOverlay` (réutilisé tel quel par les écrans qui l'appellent) |
| `lib/features/auth/presentation/widgets/kynza_oauth_button.dart` | 104 | État de chargement de bouton OAuth | 20 | `KynzaLoaderButton` |
| `lib/features/billing/presentation/screens/billing_screen.dart` | 33 | Chargement initial plein corps (`Center`) | défaut (20) | `KynzaLoaderInline(size: large)` |
| `lib/features/billing/presentation/screens/invoice_history_screen.dart` | 37 | Idem | défaut | `KynzaLoaderInline(size: large)` |
| `lib/features/billing/presentation/screens/subscription_plans_screen.dart` | 40 | Idem | défaut | `KynzaLoaderInline(size: large)` |
| `lib/features/permissions/presentation/screens/permission_group_detail_screen.dart` | 72 | Chargement async (`AsyncValue.when(loading:)`) | défaut | `KynzaLoaderInline(size: large)` |
| `lib/features/loyalty/presentation/screens/loyalty_qr_screen.dart` | 121 | Chargement inline dans un `Padding` | défaut | `KynzaLoaderInline(size: medium)` |
| `lib/features/reviews/presentation/screens/leave_review_screen.dart` | 100, 116 | Chargement async (×2 `when(loading:)`) | défaut | `KynzaLoaderInline(size: large)` |
| `lib/features/booking/presentation/screens/salon_detail_screen.dart` | 45 | Chargement async plein corps | défaut | `KynzaLoaderInline(size: large)` |
| `lib/features/salon/presentation/widgets/media_upload_button.dart` | 76 | État de chargement d'un bouton d'upload média | défaut | `KynzaLoaderButton` |
| `lib/features/payment/presentation/widgets/radar_pulse_widget.dart` | 51 | Centre d'une animation radar (anneaux concentriques existants) pendant l'attente de paiement Leapa | 32 | `KynzaLoader(variant: pulse, size: medium)` — remplace uniquement le spinner central, les anneaux restent |
| `lib/core/router/app_router.dart` | 24 occurrences (727, 818, 844, 872, 891, 928, 944, 960, 976, 992, 1008, 1026, 1045, 1061, 1079, 1095, 1111, 1127, 1143, 1159, 1177, 1206, 1222) | Garde de route — `Scaffold` plein écran pendant la résolution d'un provider async avant d'afficher l'écran réel | défaut, dans `Center` | `KynzaLoaderInline(size: large)` |

## 3. `RefreshIndicator` (Phase 5.5 — exception documentée, pas remplacé par CustomPainter)

12 occurrences, **toutes non stylées** (spinner Material bleu par défaut) :

```
lib/features/team/presentation/screens/commission_screen.dart
lib/features/billing/presentation/screens/invoice_history_screen.dart
lib/features/staff/presentation/screens/staff_list_screen.dart
lib/features/staff/presentation/screens/staff_detail_screen.dart
lib/features/staff/presentation/screens/my_performance_screen.dart
lib/features/dashboard/presentation/screens/audit_log_screen.dart
lib/features/dashboard/presentation/screens/advanced_dashboard_screen.dart
lib/features/reviews/presentation/widgets/salon_reviews_tab.dart
lib/features/marketing/presentation/screens/marketing_dashboard_screen.dart
lib/features/notifications/presentation/screens/notifications_screen.dart
lib/features/services/presentation/screens/services_list_screen.dart
lib/features/search/presentation/screens/advanced_search_screen.dart
```

Décision (Phase 5.5 du prompt) : on garde le widget Material natif (geste de
pull-to-refresh non réimplémentable sans régression) mais on ajoute
`color: AppColors.primary` + `backgroundColor: AppColors.surface` à chacun.

## 4. Hors scope — confirmé non concerné

- `KynzaSkeleton` / `KynzaCardSkeletons` (shimmer) — système différent, gelé (Phase 7.2 du prompt).
- Aucun `LinearProgressIndicator` trouvé dans `lib/`.
- Aucun cas d'usage de progression déterministe (upload % connu, etc.) — `KynzaLoaderVariant.linear` documenté comme extension future uniquement, non codé (conforme à la note V1 du prompt).

## 5. Plan d'exécution

1. Créer `lib/shared/widgets/loader/` (architecture complète : painter, controller, models, variantes, provider Riverpod overlay).
2. Réécrire `KynzaSpinner` pour devenir un alias interne du nouveau `KynzaLoader` small **OU** supprimer `KynzaSpinner` et migrer ses 12 call sites + `kynza_button.dart` + `kynza_loading_overlay.dart` directement vers `KynzaLoader`/`KynzaLoaderButton`/`KynzaLoaderInline`. → **Décision : suppression complète**, pas de wrapper de compatibilité (pas de double système).
3. Remplacer l'icône `CircularProgressIndicator` de `force_update_screen.dart` par `KynzaLoader(size: small, theme: onGoldBackground)`.
4. Styler les 12 `RefreshIndicator` en gold.
5. Ajouter les tokens couleur manquants à `AppColors` (Gold light `#FFD54A`, Gold core `#F5C542`, Amber deep `#D98A00` — Gold accent `#EAB308` existe déjà sous `AppColors.primary`) — R19 interdit le hex hardcodé hors `AppColors`.
6. Tests painter/widget/performance + mise à jour du test existant qui vérifiait `CircularProgressIndicator` sur `KynzaButton`.
7. `docs/LOADER_GUIDE.md` + mise à jour `AGENT.md` (section LOADER OFFICIEL).