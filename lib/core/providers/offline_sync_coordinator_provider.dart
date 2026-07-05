import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home_client/application/providers/client_profile_providers.dart';
import '../../features/legal/application/providers/legal_providers.dart';
import '../../features/reviews/application/providers/review_providers.dart';
import '../services/offline_sync_coordinator.dart';
import 'offline_sync_providers.dart';

final offlineSyncCoordinatorProvider = Provider<OfflineSyncCoordinator>(
  (ref) => OfflineSyncCoordinator(
    outbox: ref.watch(mutationOutboxServiceProvider),
    reviewRepository: ref.watch(reviewRepositoryProvider),
    dataDeletionRepository: ref.watch(dataDeletionRepositoryProvider),
    clientProfileRepository: ref.watch(clientProfileRepositoryProvider),
  ),
);
