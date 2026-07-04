import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/utils/auth_errors.dart';

void main() {
  group('getAuthErrorMessage', () {
    test('maps invalid_credentials', () {
      expect(
        getAuthErrorMessage(Exception('invalid_credentials')),
        'Email ou mot de passe incorrect.',
      );
    });

    test('maps email_not_confirmed', () {
      expect(
        getAuthErrorMessage(Exception('email_not_confirmed')),
        'Vérifiez votre email avant de continuer.',
      );
    });

    test('maps user_already_exists', () {
      expect(
        getAuthErrorMessage(Exception('user_already_exists')),
        'Cet email est déjà utilisé.',
      );
    });

    test('maps weak_password', () {
      expect(
        getAuthErrorMessage(Exception('weak_password')),
        'Mot de passe trop faible (8 car. min, 1 majuscule, 1 chiffre).',
      );
    });

    test('maps rate_limit', () {
      expect(
        getAuthErrorMessage(Exception('rate_limit exceeded')),
        'Trop de tentatives. Attendez quelques minutes.',
      );
    });

    test('maps too_many as the same rate-limit case', () {
      expect(
        getAuthErrorMessage(Exception('too_many requests')),
        'Trop de tentatives. Attendez quelques minutes.',
      );
    });

    test('maps network errors', () {
      expect(
        getAuthErrorMessage(Exception('network error')),
        'Erreur réseau. Vérifiez votre connexion.',
      );
    });

    test('maps socket errors to the same network case', () {
      expect(
        getAuthErrorMessage(Exception('SocketException')),
        'Erreur réseau. Vérifiez votre connexion.',
      );
    });

    test('maps provider is not enabled', () {
      expect(
        getAuthErrorMessage(Exception('Provider is not enabled')),
        'Ce service est temporairement indisponible.',
      );
    });

    test('maps missing oauth secret', () {
      expect(
        getAuthErrorMessage(Exception('Missing OAuth secret')),
        'Configuration OAuth incomplète.',
      );
    });

    test('maps popup_closed', () {
      expect(
        getAuthErrorMessage(Exception('popup_closed_by_user')),
        'Connexion annulée.',
      );
    });

    test('maps cancelled as the same popup-closed case', () {
      expect(
        getAuthErrorMessage(Exception('cancelled')),
        'Connexion annulée.',
      );
    });

    test('maps expired links', () {
      expect(
        getAuthErrorMessage(Exception('token expired')),
        'Ce lien a expiré. Faites une nouvelle demande.',
      );
    });

    test('falls back to a generic message for an unrecognized error', () {
      expect(
        getAuthErrorMessage(Exception('some_totally_unknown_error_code')),
        'Une erreur est survenue. Réessayez.',
      );
    });

    test('falls back to a generic message for null', () {
      expect(getAuthErrorMessage(null), 'Une erreur est survenue. Réessayez.');
    });

    test('is case-insensitive', () {
      expect(
        getAuthErrorMessage(Exception('INVALID_CREDENTIALS')),
        'Email ou mot de passe incorrect.',
      );
    });
  });
}
