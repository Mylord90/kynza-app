import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';
import 'kynza_nav_item.dart';
import 'kynza_nav_theme.dart';

/// Bottom navigation bar flottante premium de KYNZA — concept "Lame Dorée".
///
/// Remplace `BottomNavigationBar` dans les écrans d'accueil de chaque rôle.
/// Onglet actif : icône translatée vers le haut avec un halo doré, pastille
/// gold sous le libellé. Respecte `MediaQuery.disableAnimations`.
class KynzaBottomNav extends StatefulWidget {
  const KynzaBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemTapped,
    this.theme = KynzaNavTheme.standard,
  });

  final List<KynzaNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final KynzaNavTheme theme;

  @override
  State<KynzaBottomNav> createState() => _KynzaBottomNavState();
}

class _KynzaBottomNavState extends State<KynzaBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _translateAnimations;
  late List<Animation<double>> _haloAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controllers[widget.currentIndex].value = 1.0;
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.items.length,
      (_) => AnimationController(
        vsync: this,
        duration: widget.theme.animationDuration,
      ),
    );
    _translateAnimations = _controllers
        .map(
          (c) =>
              Tween<double>(
                begin: 0.0,
                end: widget.theme.activeItemElevation,
              ).animate(
                CurvedAnimation(parent: c, curve: widget.theme.animationCurve),
              ),
        )
        .toList();
    _haloAnimations = _controllers
        .map(
          (c) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: widget.theme.animationCurve),
          ),
        )
        .toList();
  }

  @override
  void didUpdateWidget(KynzaBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
      KynzaHaptics.selection();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Padding(
      padding: EdgeInsets.only(
        left: theme.horizontalMargin,
        right: theme.horizontalMargin,
        bottom: theme.bottomMargin + safeAreaBottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor.withValues(
            alpha: theme.backgroundOpacity,
          ),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: theme.borderColor,
            width: theme.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.verticalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index, reduceMotion),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool reduceMotion) {
    final theme = widget.theme;
    final item = widget.items[index];
    final isActive = index == widget.currentIndex;
    final controller = _controllers[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          label: item.semanticLabel ?? item.label,
          selected: isActive,
          button: true,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final translateY = reduceMotion
                  ? 0.0
                  : _translateAnimations[index].value;
              final haloOpacity = reduceMotion
                  ? 0.0
                  : _haloAnimations[index].value;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (haloOpacity > 0)
                          Opacity(
                            opacity: haloOpacity,
                            child: Container(
                              width: theme.haloRadius * 2,
                              height: theme.haloRadius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.haloColor,
                              ),
                            ),
                          ),
                        AnimatedSwitcher(
                          duration: theme.animationDuration,
                          child: Icon(
                            isActive
                                ? (item.activeIcon ?? item.icon)
                                : item.icon,
                            key: ValueKey<bool>(isActive),
                            size: isActive
                                ? theme.iconSizeActive
                                : theme.iconSizeInactive,
                            color: isActive
                                ? theme.iconColorActive
                                : theme.iconColorInactive,
                          ),
                        ),
                        if (item.badgeCount > 0)
                          Positioned(
                            top: -2,
                            right: -8,
                            child: _NavBadge(count: item.badgeCount),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: theme.animationDuration,
                      curve: theme.animationCurve,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: isActive ? 11.5 : 10.5,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? theme.labelColorActive
                            : theme.labelColorInactive,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.0,
                      duration: theme.animationDuration,
                      curve: theme.animationCurve,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.indicatorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
