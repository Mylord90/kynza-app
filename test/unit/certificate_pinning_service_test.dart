import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/security/certificate_pinning_service.dart';

void main() {
  group('CertificatePinningService — scaffolded, inert by default', () {
    test('isActive is false with the feature flag off and no pinned certs', () {
      expect(CertificatePinningService.featureFlagEnabled, isFalse);
      expect(CertificatePinningService.pinnedCertificateDerBytes, isEmpty);
      expect(CertificatePinningService.isActive, isFalse);
    });

    test(
      'isActive stays false even if only one of the two gates were flipped '
      '(both featureFlagEnabled AND real pinned bytes are required)',
      () {
        // featureFlagEnabled is a compile-time constant, so this test can't
        // flip it — but it documents the AND semantics isActive relies on:
        // an empty pin list keeps pinning off even if the flag were true,
        // which is exactly the safety property this scaffold depends on.
        expect(
          CertificatePinningService.isActive,
          equals(
            CertificatePinningService.featureFlagEnabled &&
                CertificatePinningService.pinnedCertificateDerBytes.isNotEmpty,
          ),
        );
      },
    );

    test('createClient does not throw and returns a usable client when inactive', () {
      expect(CertificatePinningService.createClient, returnsNormally);
    });
  });
}
