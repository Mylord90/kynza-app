import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mutation_outbox_service.dart';

// offlineSyncCoordinatorProvider deliberately does NOT live here — it's
// declared in offline_sync_coordinator_provider.dart instead. Declaring it
// in this file used to create 3 real core<->feature import cycles (this
// file -> {client_profile,legal,review}_providers.dart -> this file,
// tool-detected, Master Plan P3-1), since those 3 feature files only need
// mutationOutboxServiceProvider below, not the coordinator itself.

final mutationOutboxServiceProvider = Provider<MutationOutboxService>(
  (ref) => MutationOutboxService(),
);
