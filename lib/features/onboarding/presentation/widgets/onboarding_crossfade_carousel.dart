import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';
import '../../application/providers/onboarding_precache_provider.dart';
import '../../domain/onboarding_slide.dart';
import 'kynza_ken_burns_image.dart';
import 'onboarding_carousel_controller.dart';

/// Full-bleed crossfade carousel — never a horizontal slide. Each slide
/// holds for [holdDuration], then crossfades into the next, looping
/// forever. All slides are precached before the very first crossfade fires
/// so no transition ever reveals an undecoded frame.
class OnboardingCrossfadeCarousel extends ConsumerStatefulWidget {
  const OnboardingCrossfadeCarousel({
    super.key,
    required this.slides,
    required this.controller,
    this.holdDuration = const Duration(seconds: 4),
    this.cacheWidth,
  });

  final List<OnboardingSlide> slides;
  final OnboardingCarouselController controller;
  final Duration holdDuration;
  final int? cacheWidth;

  @override
  ConsumerState<OnboardingCrossfadeCarousel> createState() =>
      _OnboardingCrossfadeCarouselState();
}

class _OnboardingCrossfadeCarouselState
    extends ConsumerState<OnboardingCrossfadeCarousel>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: AppDurations.crossfade,
  );
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addListener(_reportProgress);

  int _currentIndex = 0;
  int? _previousIndex;
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _precacheAndStart();
  }

  Future<void> _precacheAndStart() async {
    await Future.wait([
      for (final slide in widget.slides) ...[
        precacheImage(AssetImage(slide.webpAsset), context),
        precacheImage(AssetImage(slide.lqipAsset), context),
      ],
    ]);
    if (!mounted) return;
    ref.read(onboardingImagesReadyProvider.notifier).state = true;
    _progressController.forward();
    _timer = Timer.periodic(widget.holdDuration, (_) => _advance());
  }

  void _reportProgress() {
    widget.controller.reportProgress(_currentIndex, _progressController.value);
  }

  void _advance() {
    if (!mounted) return;
    final previous = _currentIndex;
    setState(() {
      _previousIndex = previous;
      _currentIndex = (previous + 1) % widget.slides.length;
    });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    _fadeController.duration = reduceMotion
        ? AppDurations.fast
        : AppDurations.crossfade;
    _fadeController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _previousIndex = null);
    });
    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final slides = widget.slides;
    final previousIndex = _previousIndex;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (previousIndex != null)
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) =>
                  Opacity(opacity: 1 - _fadeController.value, child: child),
              child: KynzaKenBurnsImage(
                key: ValueKey('onboarding-prev-$previousIndex'),
                slide: slides[previousIndex],
                duration: widget.holdDuration,
                reduceMotion: true,
                cacheWidth: widget.cacheWidth,
              ),
            ),
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) => Opacity(
              opacity: previousIndex != null ? _fadeController.value : 1,
              child: child,
            ),
            child: KynzaKenBurnsImage(
              key: ValueKey('onboarding-cur-$_currentIndex'),
              slide: slides[_currentIndex],
              duration: widget.holdDuration,
              reduceMotion: reduceMotion,
              cacheWidth: widget.cacheWidth,
            ),
          ),
        ],
      ),
    );
  }
}
