import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/booking_model.dart';
import 'package:kynza/core/models/notification_log_model.dart';
import 'package:kynza/core/models/notification_preferences_model.dart';
import 'package:kynza/core/models/search/search_result_item.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/providers/auth_providers.dart';
import 'package:kynza/core/services/profile_read_cache.dart';
import 'package:kynza/features/booking/application/providers/booking_providers.dart';
import 'package:kynza/features/booking/data/booking_read_cache.dart';
import 'package:kynza/features/booking/domain/repositories/booking_repository.dart';
import 'package:kynza/features/notifications/application/providers/notification_providers.dart';
import 'package:kynza/features/notifications/data/notification_read_cache.dart';
import 'package:kynza/features/notifications/domain/repositories/notification_repository.dart';
import 'package:kynza/features/search/application/providers/search_providers.dart';
import 'package:kynza/features/search/data/search_read_cache.dart';
import 'package:kynza/features/search/domain/repositories/search_repository.dart';

/// A cold-start-offline network never throws — `SupabaseStreamBuilder`'s
/// initial fetch just never completes while there's no connectivity to
/// retry against. `Stream.empty()` mirrors that shape for a stream-backed
/// repository call exactly (no error, no data — the caller waits forever
/// unless something else feeds it a value), which is why this is the
/// correct fake for a "network is down" repository, not a
/// `Stream.error(...)`.
class _HungBookingRepository implements BookingRepository {
  @override
  Stream<List<BookingModel>> getClientBookings(String clientId) =>
      const Stream.empty();
  @override
  Stream<List<BookingModel>> getSalonBookings(String salonId, DateTime date) =>
      const Stream.empty();
  @override
  Stream<List<BookingModel>> getPractitionerBookings(
    String practitionerId,
    DateTime date,
  ) => const Stream.empty();

  @override
  Future<BookingModel> createBooking(BookingModel draft) =>
      throw UnimplementedError();
  @override
  Future<BookingModel> createWalkInBooking({
    required String salonId,
    required String serviceId,
    required String practitionerId,
    required DateTime startTime,
    required String guestFirstName,
    required String guestPhone,
    String? notes,
  }) => throw UnimplementedError();
  @override
  Future<BookingModel?> getById(String bookingId) => throw UnimplementedError();
  @override
  Future<List<BookingModel>> getBookingsInRange(
    String salonId,
    DateTime start,
    DateTime end,
  ) => throw UnimplementedError();
  @override
  Future<List<BookingModel>> getPractitionerBookingsInRange(
    String practitionerId,
    DateTime start,
    DateTime end,
  ) => throw UnimplementedError();
  @override
  Future<BookingModel> updateStatus(String bookingId, BookingStatus status) =>
      throw UnimplementedError();
  @override
  Future<void> cancelBooking(String bookingId, String reason) =>
      throw UnimplementedError();
  @override
  Future<void> markNoShow(String bookingId) => throw UnimplementedError();
  @override
  Future<void> markInProgress(String bookingId) => throw UnimplementedError();
  @override
  Future<void> markCompleted(String bookingId) => throw UnimplementedError();
}

class _FailingSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResultItem>> search(String query, SearchFilters filters) =>
      Future.error('network unavailable');
  @override
  Future<void> logSearch(String query) async {}
  @override
  Future<List<String>> getPopularSearches() => Future.error('network unavailable');
}

class _HungNotificationRepository implements NotificationRepository {
  @override
  Stream<List<NotificationLogModel>> getNotifications(
    String userId, {
    int limit = 20,
  }) => const Stream.empty();
  @override
  Stream<int> watchUnreadCount(String userId) => const Stream.empty();
  @override
  Future<void> markAsRead(String notifId) => throw UnimplementedError();
  @override
  Future<void> markAllAsRead(String userId) => throw UnimplementedError();
  @override
  Future<void> deleteNotification(String notifId) => throw UnimplementedError();
  @override
  Future<NotificationPreferencesModel> getPreferences(String userId) =>
      throw UnimplementedError();
  @override
  Future<void> updatePreferences(NotificationPreferencesModel prefs) =>
      throw UnimplementedError();
  @override
  Future<void> updateWhatsappPhone(String userId, String phone) =>
      throw UnimplementedError();
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'kynza_cold_start_offline_test',
    );
    Hive.init(tempDir.path);
    await Hive.openBox(BookingReadCache.boxName);
    await Hive.openBox(SearchReadCache.boxName);
    await Hive.openBox(ProfileReadCache.boxName);
    await Hive.openBox(NotificationReadCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(BookingReadCache.boxName);
    await Hive.deleteBoxFromDisk(SearchReadCache.boxName);
    await Hive.deleteBoxFromDisk(ProfileReadCache.boxName);
    await Hive.deleteBoxFromDisk(NotificationReadCache.boxName);
    await tempDir.delete(recursive: true);
  });

  test(
    'salonBookingsProvider (agenda) renders the last-cached snapshot on a '
    'cold start with no network, instead of hanging forever',
    () async {
      final date = DateTime(2026, 7, 5);
      final cached = [
        BookingModel(
          id: 'b1',
          salonId: 'salon-a',
          clientId: 'client-1',
          practitionerId: 'staff-1',
          serviceId: 'svc-1',
          startTime: date.add(const Duration(hours: 10)),
          endTime: date.add(const Duration(hours: 11)),
          bufferEndTime: date.add(const Duration(hours: 11, minutes: 15)),
          amountBif: 15000,
        ),
      ];
      await BookingReadCache.setSalonBookings('salon-a', date, cached);

      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(_HungBookingRepository()),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        salonBookingsProvider(('salon-a', date)),
        (_, _) {},
      );
      addTearDown(sub.close);

      // The underlying stream never emits (simulating no network) — the
      // cached value must arrive as the provider's first state without
      // waiting on the live stream at all.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final state = sub.read();

      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(1));
      expect(state.value!.single.id, 'b1');
    },
  );

  test(
    'searchResultsProvider (catalog browsing) falls back to the last-cached '
    'result set when the repository fails (offline)',
    () async {
      const query = 'coiffure';
      const filters = SearchFilters();
      final cached = [
        const SearchResultItem(
          id: 'svc-1',
          type: SearchResultType.service,
          title: 'Coupe déjà en cache',
          salonId: 'salon-a',
        ),
      ];
      await SearchReadCache.setResults('$query|null|null|null||null|relevance', cached);

      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(_FailingSearchRepository()),
          searchQueryProvider.overrideWith((ref) => query),
          searchFiltersProvider.overrideWith((ref) => filters),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(searchResultsProvider.future);

      expect(result, hasLength(1));
      expect(result.single.title, 'Coupe déjà en cache');
    },
  );

  test(
    'notificationsProvider (local history) renders the last-cached snapshot '
    'on a cold start with no network, instead of hanging forever',
    () async {
      const profile = UserProfile(id: 'user-1', fullName: 'Test User');
      final cached = [
        const NotificationLogModel(
          id: 'n1',
          userId: 'user-1',
          eventType: 'booking.confirmed',
          channel: 'in_app',
          title: 'Déjà en cache',
          body: 'Notification lue hors-ligne.',
        ),
      ];
      await NotificationReadCache.set('user-1', cached);

      final container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => profile),
          notificationRepositoryProvider.overrideWithValue(
            _HungNotificationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(notificationsProvider(20), (_, _) {});
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final state = sub.read();

      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(1));
      expect(state.value!.single.title, 'Déjà en cache');
    },
  );

  test(
    'ProfileReadCache round-trips a real UserProfile through Hive '
    '(the mechanism currentUserProfileProvider falls back to when '
    'client.from("users").select() throws offline)',
    () async {
      const profile = UserProfile(
        id: 'user-1',
        fullName: 'Cached User',
        phone: '+25761234567',
      );
      await ProfileReadCache.set('user-1', profile);

      final restored = ProfileReadCache.get('user-1');

      expect(restored, isNotNull);
      expect(restored!.fullName, 'Cached User');
      expect(restored.phone, '+25761234567');
    },
  );
}
