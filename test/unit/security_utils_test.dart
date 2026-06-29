import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/utils/security_utils.dart';

void main() {
  group('SecurityUtils.maskPhone', () {
    test('keeps the first 4 and last 2 digits, masks the rest', () {
      expect(SecurityUtils.maskPhone('+25779123456'), '+257***56');
    });

    test('returns a fully masked placeholder for very short input', () {
      expect(SecurityUtils.maskPhone('12345'), '***');
    });
  });

  group('SecurityUtils.maskEmail', () {
    test('keeps the first 3 local-part characters and the full domain', () {
      expect(
        SecurityUtils.maskEmail('jeanne@example.com'),
        'jea***@example.com',
      );
    });

    test('fully masks a short local part', () {
      expect(SecurityUtils.maskEmail('jo@example.com'), '***@example.com');
    });

    test('returns a generic placeholder for a malformed address', () {
      expect(SecurityUtils.maskEmail('not-an-email'), '***@***.***');
    });
  });
}
