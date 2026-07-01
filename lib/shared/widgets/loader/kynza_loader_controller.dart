import 'package:flutter/animation.dart';
import '../../../core/constants/app_durations.dart';

/// Wrapper autour d'un `AnimationController` dédié au `KynzaLoader`. Le
/// widget propriétaire reste responsable d'appeler [dispose].
class KynzaLoaderController {
  KynzaLoaderController({
    required TickerProvider vsync,
    Duration duration = AppDurations.loaderOrbit,
  }) : _controller = AnimationController(vsync: vsync, duration: duration) {
    _controller.repeat();
  }

  final AnimationController _controller;

  Animation<double> get animation => _controller;

  void dispose() => _controller.dispose();

  void stop() => _controller.stop();

  void resume() => _controller.repeat();
}
