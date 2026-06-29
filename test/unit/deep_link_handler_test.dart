import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/router/deep_link_handler.dart';

void main() {
  group('DeepLinkHandler.parseRoute', () {
    test(
      'accept-invitation host with token rewrites to the route with query',
      () {
        final route = DeepLinkHandler.parseRoute(
          Uri.parse('com.kynza.app://accept-invitation?token=abc123'),
        );
        expect(route, '/accept-invitation?token=abc123');
      },
    );

    test('accept-invitation host without token rewrites to the bare route', () {
      final route = DeepLinkHandler.parseRoute(
        Uri.parse('com.kynza.app://accept-invitation'),
      );
      expect(route, '/accept-invitation');
    });

    test(
      'accept-referral host with token rewrites to the route with query',
      () {
        final route = DeepLinkHandler.parseRoute(
          Uri.parse('com.kynza.app://accept-referral?token=ref456'),
        );
        expect(route, '/accept-referral?token=ref456');
      },
    );

    test(
      'salon host with an id segment rewrites to the salon detail route',
      () {
        final route = DeepLinkHandler.parseRoute(
          Uri.parse('com.kynza.app://salon/salon-789'),
        );
        expect(route, '/client/salon/salon-789');
      },
    );

    test('salon host without an id segment returns null', () {
      final route = DeepLinkHandler.parseRoute(
        Uri.parse('com.kynza.app://salon'),
      );
      expect(route, isNull);
    });

    test('booking host with an id segment rewrites to the payment route', () {
      final route = DeepLinkHandler.parseRoute(
        Uri.parse('com.kynza.app://booking/booking-321'),
      );
      expect(route, '/client/payment/booking-321');
    });

    test('unrecognized host returns null', () {
      final route = DeepLinkHandler.parseRoute(
        Uri.parse('com.kynza.app://promotion/promo-1'),
      );
      expect(route, isNull);
    });

    test('a normal in-app relative path (empty host) returns null', () {
      final route = DeepLinkHandler.parseRoute(Uri.parse('/owner/dashboard'));
      expect(route, isNull);
    });
  });
}
