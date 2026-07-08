import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../domain/onboarding_slide.dart';

/// Applies a subtle, Apple-style Ken Burns effect (~2% zoom + a few pixels of
/// vertical drift) to [slide] over [duration]. A fixed 1.03 safety scale sits
/// underneath the animated 1.00→1.02 zoom so the drift never exposes an edge
/// of the cropped image. Fully static when [reduceMotion] is true.
///
/// Renders the LQIP thumbnail first, then crossfades in the full-resolution
/// WebP once decoded — this is the loading placeholder required in place of
/// any spinner or runtime blur.
class KynzaKenBurnsImage extends StatefulWidget {
  const KynzaKenBurnsImage({
    super.key,
    required this.slide,
    required this.duration,
    required this.reduceMotion,
    this.cacheWidth,
  });

  final OnboardingSlide slide;
  final Duration duration;
  final bool reduceMotion;
  final int? cacheWidth;

  @override
  State<KynzaKenBurnsImage> createState() => _KynzaKenBurnsImageState();
}

class _KynzaKenBurnsImageState extends State<KynzaKenBurnsImage>
    with SingleTickerProviderStateMixin {
  static const _safetyScale = 1.03;
  static const _zoomEnd = 1.02;
  static const _driftPixels = 10.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: _zoomEnd,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  late final Animation<double> _driftY = Tween<double>(
    begin: 0,
    end: _driftPixels * widget.slide.kenBurnsDriftDirection,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _errorFallback = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.background, Color(0xFF1A1208)],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final content = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          slide.lqipAsset,
          fit: BoxFit.cover,
          alignment: slide.alignment,
          errorBuilder: (context, error, stackTrace) => _errorFallback,
        ),
        Image.asset(
          slide.webpAsset,
          fit: BoxFit.cover,
          alignment: slide.alignment,
          cacheWidth: widget.cacheWidth,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppDurations.medium,
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        ),
      ],
    );

    if (widget.reduceMotion) return content;

    return Transform.scale(
      scale: _safetyScale,
      child: AnimatedBuilder(
        animation: _controller,
        child: content,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _driftY.value),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
    );
  }
}
