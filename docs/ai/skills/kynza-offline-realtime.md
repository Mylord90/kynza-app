# KYNZA SKILL — OFFLINE & REALTIME | Version 1.0 | Lire avant toute intervention

> Domaine : Hive/Isar, Outbox pattern, résolution de conflits, Supabase Realtime, indicateurs visuels offline.
> Ne couvre PAS : Realtime channels côté backend RLS (→ `kynza-supabase-backend.md`), composants UI génériques (→ `kynza-uiux-design-system.md`).

## 1. Principe directeur (R03)

KYNZA est Offline-First par contrainte terrain (3G instable, devices d'entrée de gamme). L'app doit rester pleinement utilisable sans réseau pour les opérations critiques du quotidien (consulter l'agenda, noter un client, encaisser en cash), et synchroniser silencieusement à la reconnexion — jamais de blocage brutal, jamais de perte de données saisies offline.

## 2. Hive — setup des boxes

```dart
// core/services/hive_service.dart
class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(BookingHiveAdapter());
    Hive.registerAdapter(ClientNoteHiveAdapter());
    Hive.registerAdapter(CashPaymentDraftAdapter());
    Hive.registerAdapter(OutboxItemAdapter());

    await Hive.openBox<BookingHive>('agenda_j7', encryptionCipher: await _cipher());
    await Hive.openBox<BookingHive>('agenda_30j_readonly');
    await Hive.openBox<ClientHive>('clients_cache_readonly');
    await Hive.openBox<OutboxItem>('outbox_queue', encryptionCipher: await _cipher());
    await Hive.openBox('kpis_cache');
  }

  static Future<HiveAesCipher> _cipher() async {
    const secureStorage = FlutterSecureStorage();
    var key = await secureStorage.read(key: 'hive_key');
    if (key == null) {
      key = base64UrlEncode(Hive.generateSecureKey());
      await secureStorage.write(key: 'hive_key', value: key);
    }
    return HiveAesCipher(base64Url.decode(key));
  }
}
```

- Chiffrement AES-256 activé sur toutes les boxes contenant des données personnelles/transactionnelles (`agenda_j7`, `outbox_queue`) — la clé vit dans `flutter_secure_storage`, jamais en clair dans Hive lui-même.
- `agenda_30j_readonly` et `clients_cache_readonly` peuvent rester non chiffrées si elles ne contiennent aucune donnée sensible au repos (à valider par l'Owner du projet selon la politique de confidentialité réelle).
- Un `TypeAdapter` par modèle métier (`@HiveType`/`@HiveField`), jamais de `Map<String, dynamic>` brut stocké directement.

## 3. Stratégie de cache — R/W vs R-only

| Donnée | Mode | Stockage | Mise à jour |
|---|---|---|---|
| Agenda J+7 | Lecture + écriture | Hive chiffré (`agenda_j7`) | Ouverture app + synchro reconnexion |
| Agenda 30j historique | Lecture seule | Hive (`agenda_30j_readonly`) | Arrière-plan |
| Fiches clients | Lecture seule | Hive (`clients_cache_readonly`) | Ouverture app |
| Notes techniques clients | Lecture + écriture | Queue synchro (Outbox) | À la reconnexion |
| KPIs & Stats | Cache dernière synchro | Hive (`kpis_cache`) | Arrière-plan |
| Encaissement Cash | Enregistrement local | Queue synchro (Outbox) | À la reconnexion |
| Encaissement Mobile Money | **Réseau requis** | — | — |
| Notifications Push | **Réseau requis** | — | Reçues à la reconnexion |
| Catalogue prix salons | Cache complet | Hive | TTL 30 min si en ligne |

```dart
// data/repositories/booking_repository_impl.dart
@override
Future<List<Booking>> getWeekAgenda(String salonId) async {
  if (await connectivity.isOnline) {
    final fresh = await remote.fetchWeekAgenda(salonId);
    await local.cacheWeekAgenda(fresh); // refresh silencieux du cache R/W
    return fresh;
  }
  return local.getCachedWeekAgenda(salonId); // fallback offline transparent
}
```

## 4. Outbox Pattern — file de reprise

Toute écriture offline est empilée dans une queue unique, jamais directement tentée contre le réseau.

```dart
// core/models/outbox_item.dart
@HiveType(typeId: 10)
class OutboxItem {
  @HiveField(0) final String id;
  @HiveField(1) final OutboxAction action; // newBooking, statusChange, cashPayment, clientNote
  @HiveField(2) final Map<String, dynamic> payload;
  @HiveField(3) final DateTime createdAt;
  @HiveField(4) int retryCount;

  OutboxItem({required this.id, required this.action, required this.payload,
              required this.createdAt, this.retryCount = 0});
}
```

```dart
// core/services/outbox_sync_service.dart
class OutboxSyncService {
  // Ordre de synchro STRICT — R03 : 1.Nouveaux RDV → 2.Statuts → 3.Cash → 4.Notes
  static const _priorityOrder = [
    OutboxAction.newBooking,
    OutboxAction.statusChange,
    OutboxAction.cashPayment,
    OutboxAction.clientNote,
  ];

  Future<void> syncAll() async {
    final box = Hive.box<OutboxItem>('outbox_queue');
    final items = box.values.toList()
      ..sort((a, b) => _priorityOrder.indexOf(a.action).compareTo(_priorityOrder.indexOf(b.action)));

    for (final item in items) {
      try {
        await _dispatch(item);
        await box.delete(item.id);
      } catch (e) {
        item.retryCount++;
        if (item.retryCount > 5) {
          await _flagForManualReview(item); // jamais de perte silencieuse de données
        }
        await box.put(item.id, item);
      }
    }
  }

  Future<void> _dispatch(OutboxItem item) => switch (item.action) {
    OutboxAction.newBooking => bookingRemote.create(item.payload),
    OutboxAction.statusChange => bookingRemote.updateStatus(item.payload),
    OutboxAction.cashPayment => paymentRemote.recordCash(item.payload),
    OutboxAction.clientNote => clientRemote.updateNote(item.payload),
  };
}
```

Déclenchement : worker arrière-plan sur transition `offline → online` (cf. `ConnectivityService`), jamais sur simple tap utilisateur, pour garantir que la synchro silencieuse a bien lieu même si l'app est en arrière-plan court.

## 5. Résolution de conflits — Server-Wins

```dart
// core/services/conflict_resolver.dart
class ConflictResolver {
  /// Le serveur (réservation client en ligne, modification concurrente)
  /// a TOUJOURS la priorité. On n'écrase jamais silencieusement.
  Future<SyncResult> resolve(OutboxItem localItem, ServerError serverError) async {
    if (serverError.code == 'slot_taken' || serverError.code == 'conflict') {
      await _notifyConflict(localItem);
      return SyncResult.discarded(reason: serverError.code);
    }
    return SyncResult.retry();
  }

  Future<void> _notifyConflict(OutboxItem item) async {
    showKynzaBanner(
      level: BannerLevel.warning,
      message: "⚠️ Conflit : [Nom] a réservé [heure] que vous venez de modifier.",
    );
  }
}
```

- Aucune mutation locale n'est réappliquée après un conflit détecté — l'état serveur est rechargé et remplace l'état local en cache.
- Le bandeau de conflit est explicite et nommé (jamais un simple toast générique "erreur de synchro").

## 6. Supabase Realtime — channels par salon

```dart
// core/services/realtime_service.dart
class RealtimeService {
  RealtimeChannel? _channel;
  Timer? _debounce;

  void subscribeToSalon(String salonId, void Function() onChange) {
    _channel = supabase.channel('salon:$salonId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all, schema: 'public', table: 'bookings',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'salon_id', value: salonId),
        callback: (_) => _debounced(onChange),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update, schema: 'public', table: 'salons',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: salonId),
        callback: (_) => _debounced(onChange),
      )
      ..subscribe(
        (status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _onReconnected();
        },
      );
  }

  void _debounced(void Function() cb) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), cb); // debounce 300ms obligatoire
  }

  Future<void> _onReconnected() async {
    await OutboxSyncService().syncAll(); // synchro silencieuse à la reconnexion
  }

  void dispose() => _channel?.unsubscribe();
}
```

- Un channel **par salon**, jamais un channel global tous-salons (fuite de données, coût mémoire inutile).
- `dispose()` appelé systématiquement au changement d'écran/salon pour éviter les fuites de subscriptions.

## 7. Bandeau et indicateurs visuels offline

```dart
// shared/widgets/kynza_offline_banner.dart
class KynzaOfflineBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    return switch (status) {
      ConnectivityStatus.offline => const _Banner(
          icon: Icons.cloud_off, color: AppColors.textSecondary,
          label: 'Hors ligne — données en cache', dismissible: false),
      ConnectivityStatus.syncing => const _Banner(
          icon: Icons.sync, color: AppColors.primary,
          label: 'Synchronisation en cours', dismissible: false, animated: true),
      ConnectivityStatus.reconnected => const _Banner(
          icon: Icons.check_circle, color: AppColors.success,
          label: 'Synchronisé', dismissible: true, autoHideAfter: Duration(seconds: 3)),
      ConnectivityStatus.online => const SizedBox.shrink(),
    };
  }
}
```

| État | Indicateur | Comportement |
|---|---|---|
| Offline | Bandeau gris discret + icône 🔴 dans la status bar | Non bloquant, cache local affiché |
| Syncing | Icône ⟳ animée + "Synchronisation en cours" | Disparaît < 3s, barre de progression 4dp sous le header |
| Reconnected | Icône ✅ verte "Synchronisé" | Auto-hide après 2-3s |
| Bouton nécessitant réseau | Grisé + icône 🔴 | Tap → toast "Cette action nécessite une connexion" |

```dart
// shared/widgets/kynza_button.dart (extrait — garde réseau)
KynzaButton(
  label: 'Payer en ligne',
  isDisabled: !isOnline,
  onPressed: isOnline ? onPay : () => showKynzaToast(
    message: 'Cette action nécessite une connexion',
    level: ToastLevel.warning,
  ),
)
```

## 8. Procédure de test offline (mode avion)

1. Lancer l'app en ligne, naviguer jusqu'à l'écran cible, laisser le cache se peupler.
2. Activer le mode avion (réseau réellement coupé, pas un mock de `ConnectivityPlus`).
3. Vérifier : l'écran reste utilisable, le bandeau offline apparaît sous 2s, aucune erreur réseau brute n'atteint l'UI.
4. Effectuer une action offline éligible (note client, RDV cash, nouveau RDV) → vérifier l'apparition dans `outbox_queue` (inspection via Hive DevTools ou log debug).
5. Désactiver le mode avion → vérifier : bandeau passe à "Synchronisation en cours" puis "Synchronisé" sous 3s, l'item disparaît de la queue, l'ordre de traitement respecte Nouveaux RDV → Statuts → Cash → Notes.
6. Forcer un conflit (modifier le même créneau depuis un second device pendant que le premier est offline) → vérifier l'apparition du bandeau de conflit nommé, pas d'écrasement silencieux.

Toute PR touchant à une fonctionnalité offline doit documenter le résultat de cette procédure dans sa description.

## 9. Données nécessitant impérativement le réseau

- **Paiement Mobile Money** (Leapa USSD) — par nature impossible hors-ligne, aucun mock de paiement réseau autorisé.
- **Notifications Push FCM** — reçues uniquement à la reconnexion, jamais mises en queue côté client (c'est Supabase qui gère la queue serveur, cf. matrice notifications).
- **Première authentification OTP** — l'envoi SMS nécessite le réseau ; en revanche une session déjà active reste utilisable offline.

Toute fonctionnalité qui tenterait de simuler un de ces flux offline (ex. "paiement en attente locale qui se valide plus tard sans webhook") est interdite — c'est une violation du principe non-custodial R01.
