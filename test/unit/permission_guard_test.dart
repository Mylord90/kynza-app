import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/user_role.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/permissions/permission_guard.dart';
import 'package:kynza/core/permissions/permission_service.dart';
import 'package:kynza/core/providers/auth_providers.dart';

void main() {
  group('PermissionGuard', () {
    testWidgets(
      'shows the child for an owner without calling the permission RPC',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProfileProvider.overrideWith(
                (ref) async => const UserProfile(
                  id: 'owner-1',
                  salonId: 'salon-1',
                  role: UserRole.owner,
                ),
              ),
            ],
            child: const MaterialApp(
              home: PermissionGuard(
                feature: 'billing',
                action: 'manage',
                child: Text('Secret'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Secret'), findsOneWidget);
      },
    );

    testWidgets('hides the child and shows the fallback when denied', (
      tester,
    ) async {
      const query = (feature: 'billing', action: 'manage', resource: '');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'staff-1',
                salonId: 'salon-1',
                role: UserRole.staff,
              ),
            ),
            permissionProvider(query).overrideWith((ref) async => false),
          ],
          child: const MaterialApp(
            home: PermissionGuard(
              feature: 'billing',
              action: 'manage',
              fallback: Text('Verrouillé'),
              child: Text('Secret'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsNothing);
      expect(find.text('Verrouillé'), findsOneWidget);
    });

    testWidgets(
      'shows the child for a non-owner once the permission resolves to true',
      (tester) async {
        const query = (
          feature: 'staff',
          action: 'view_commissions',
          resource: 'all',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProfileProvider.overrideWith(
                (ref) async => const UserProfile(
                  id: 'staff-1',
                  salonId: 'salon-1',
                  role: UserRole.staff,
                ),
              ),
              permissionProvider(query).overrideWith((ref) async => true),
            ],
            child: const MaterialApp(
              home: PermissionGuard(
                feature: 'staff',
                action: 'view_commissions',
                resource: 'all',
                child: Text('Secret'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Secret'), findsOneWidget);
      },
    );
  });
}
