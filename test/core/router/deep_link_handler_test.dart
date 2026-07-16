import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kynza/core/router/deep_link_handler.dart';
import 'package:kynza/core/router/route_names.dart';

/// Small throwaway router purely to obtain a real RouteConfiguration.
/// GoRouter builds `.configuration` synchronously in its constructor
/// (go_router router.dart:205), so this never needs a widget pumped.
GoRouter _routerWith(List<String> registeredPaths) => GoRouter(
  initialLocation: registeredPaths.first,
  routes: [
    for (final path in registeredPaths)
      GoRoute(path: path, builder: (context, state) => const SizedBox()),
  ],
);

void main() {
  group('DeepLinkHandler.capturePendingIntent / consumePendingIntent', () {
    final router = _routerWith([RouteNames.splash, RouteNames.notifications]);
    final config = router.configuration;

    tearDownAll(router.dispose);

    setUp(() {
      // A stray capture leaking from a previous test must never survive —
      // mirrors the real "one cold start, one intent" contract.
      DeepLinkHandler.consumePendingIntent(config);
    });

    test('no capture -> consume returns null', () {
      expect(DeepLinkHandler.consumePendingIntent(config), isNull);
    });

    test('captures a known route and replays it once', () {
      DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

      expect(
        DeepLinkHandler.consumePendingIntent(config),
        RouteNames.notifications,
      );
    });

    test('rejeu unique — a second consume after a successful one is null', () {
      DeepLinkHandler.capturePendingIntent(RouteNames.notifications);

      DeepLinkHandler.consumePendingIntent(config); // first — consumes it
      expect(DeepLinkHandler.consumePendingIntent(config), isNull);
    });

    test(
      'an unknown path is discarded silently — the real send-notification '
      'bug (deepLink: "/booking/:id", no such route registered anywhere)',
      () {
        DeepLinkHandler.capturePendingIntent('/booking/abc123');

        expect(DeepLinkHandler.consumePendingIntent(config), isNull);
      },
    );

    test('an unknown path is still cleared even though discarded', () {
      DeepLinkHandler.capturePendingIntent('/booking/abc123');
      DeepLinkHandler.consumePendingIntent(config); // discarded, but cleared

      DeepLinkHandler.capturePendingIntent(RouteNames.notifications);
      expect(
        DeepLinkHandler.consumePendingIntent(config),
        RouteNames.notifications,
      );
    });

    test('capturing null is a no-op', () {
      DeepLinkHandler.capturePendingIntent(null);

      expect(DeepLinkHandler.consumePendingIntent(config), isNull);
    });

    test('capturing an empty string is a no-op', () {
      DeepLinkHandler.capturePendingIntent('');

      expect(DeepLinkHandler.consumePendingIntent(config), isNull);
    });

    test('a malformed path never throws — discarded, not crashed', () {
      DeepLinkHandler.capturePendingIntent('not a valid ::: uri %');

      expect(
        () => DeepLinkHandler.consumePendingIntent(config),
        returnsNormally,
      );
    });
  });
}
