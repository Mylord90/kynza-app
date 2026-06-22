# KYNZA SKILL — BOOKING ENGINE | Version 1.0 | Lire avant toute intervention

> Domaine : machine à états des réservations, race conditions, priorités, no-show, buffer time, Caméléon Solo/Team.
> Ne couvre PAS : intégration Leapa détaillée (→ `kynza-payments-leapa.md`), RLS/schéma (→ `kynza-supabase-backend.md`).

## 1. Machine à états complète

```
pending_payment ──(webhook Leapa SUCCESS)──► confirmed
confirmed       ──(Staff tape "Confirmer arrivée")──► in_progress
in_progress     ──(Staff tape "Terminer + encaisser")──► completed
confirmed       ──(action annulation + confirmation)──► cancelled
confirmed       ──(H+15min, Staff tape "Absent")──► no_show
```

| Statut | Description | Déclencheur |
|---|---|---|
| `pending_payment` | Créneau verrouillé 5 min, paiement Leapa en cours | Sélection créneau + initiation paiement |
| `confirmed` | Transaction validée, créneau bloqué, WhatsApp envoyé | Webhook Leapa SUCCESS |
| `in_progress` | Praticien a tapé "Arrivé", timer démarré | Tap Confirmer arrivée (Staff, R10) |
| `completed` | Prestation finie, argent comptabilisé | Tap Terminer + encaissement |
| `cancelled` | Annulé, créneau libéré, remboursement si applicable | Action annulation + confirmation |
| `no_show` | Absent +15 min, score fiabilité client -1 | Praticien tape Absent |

Aucune transition hors de ce graphe n'est valide. Un `bookings.status` qui passerait directement de `pending_payment` à `completed` (sans `confirmed`/`in_progress`) indique un bug — à rejeter explicitement côté UseCase.

```dart
// domain/usecases/transition_booking_status_usecase.dart
const _validTransitions = <BookingStatus, Set<BookingStatus>>{
  BookingStatus.pendingPayment: {BookingStatus.confirmed, BookingStatus.cancelled, BookingStatus.expired},
  BookingStatus.confirmed: {BookingStatus.inProgress, BookingStatus.cancelled, BookingStatus.noShow},
  BookingStatus.inProgress: {BookingStatus.completed},
};

class TransitionBookingStatusUseCase {
  Result<void, Failure> execute(BookingStatus from, BookingStatus to) {
    if (!(_validTransitions[from]?.contains(to) ?? false)) {
      return Result.failure(Failure('invalid_transition: $from → $to'));
    }
    return const Result.success(null);
  }
}
```

## 2. Race conditions — verrou optimiste

```sql
-- contrainte au niveau schéma (déjà posée dans kynza-supabase-backend.md)
ALTER TABLE bookings ADD CONSTRAINT uq_practitioner_slot UNIQUE (practitioner_id, start_time);
```

```sql
-- Edge Function : transaction SQL atomique SELECT FOR UPDATE + INSERT
BEGIN;
  SELECT id FROM bookings
  WHERE practitioner_id = $1 AND start_time = $2
  FOR UPDATE;
  -- si la ligne existe déjà → l'INSERT suivant échoue sur la contrainte UNIQUE
  INSERT INTO bookings (salon_id, client_id, practitioner_id, service_id, start_time, end_time, buffer_end_time, amount_bif, status)
  VALUES ($3, $4, $1, $5, $2, $6, $7, $8, 'pending_payment');
COMMIT;
```

- Premier arrivé → `INSERT` réussit → `confirmed` normalement.
- Second arrivé (quelques ms après) → violation de contrainte UNIQUE → l'Edge Function catch l'erreur Postgres `23505` et répond avec une liste de créneaux alternatifs.
- **Message UX obligatoire** : *"Ce créneau vient d'être réservé. Voici les prochains disponibles."* — jamais d'erreur brute, jamais de code SQL exposé.

```typescript
// supabase/functions/create-booking/index.ts (extrait)
try {
  await insertBooking(supabase, payload);
} catch (e) {
  if (e.code === "23505") { // unique_violation
    const alternatives = await findNextAvailableSlots(supabase, payload.practitionerId, payload.startTime);
    return jsonResponse({ error: "slot_taken", message: "Ce créneau vient d'être réservé. Voici les prochains disponibles.", alternatives }, 409);
  }
  throw e;
}
```

## 3. Verrouillage de créneau pendant paiement (5 min)

- Dès `pending_payment`, le créneau est considéré occupé pour tout autre client (même contrainte UNIQUE).
- Si le paiement n'atteint pas `completed` sous 5 minutes (timeout USSD réel = 3 min + marge), un cron Supabase fait passer le booking en `expired`/`cancelled` et libère le créneau.

```sql
-- Cron Supabase (pg_cron), exécuté toutes les minutes
SELECT cron.schedule(
  'release-expired-bookings',
  '* * * * *',
  $$
    UPDATE bookings
    SET status = 'cancelled'
    WHERE status = 'pending_payment'
      AND created_at < now() - interval '5 minutes'
      AND deleted_at IS NULL;
  $$
);
```

Aucun double débit n'est possible pendant ce verrou car l'`idempotency_key` (cf. `kynza-payments-leapa.md`) bloque toute nouvelle tentative Leapa sur la même fenêtre.

## 4. Priorités de réservation P1-P4

| Niveau | Statut | Couleur agenda | Garantie | Annulation |
|---|---|---|---|---|
| P1 | `CONFIRMED_PAID` | 🟢 Vert + 💳 | Verrouillé, non déplaçable sans confirmation explicite | Remboursement Leapa auto |
| P2 | `CONFIRMED` | 🟡 Jaune | Confirmé, déplaçable si urgence | Selon politique salon |
| P3 | `PENDING` | 🔵 Bleu | Provisoire, timeout 30 min | Libération automatique |
| P4 | `WALK_IN` | ⚪ Gris | Non garantie, file d'attente | Sans pénalité |

- Client payé en ligne (P1) : message *"Rendez-vous Garanti Premium. Présentez votre code."*
- Retard salon > 10 min : réorganisation automatique, les RDV non-garantis (P3/P4) sont décalés en priorité (jamais les P1).
- Owner qui annule un RDV P1 → remboursement Leapa déclenché automatiquement, sans flow OTP manuel (cf. `kynza-payments-leapa.md` §9).

```dart
// core/enums/booking_priority.dart
enum BookingPriority { p1ConfirmedPaid, p2Confirmed, p3Pending, p4WalkIn }

extension BookingPriorityX on BookingPriority {
  Color get tileColor => switch (this) {
    BookingPriority.p1ConfirmedPaid => AppColors.success,
    BookingPriority.p2Confirmed => AppColors.primary,
    BookingPriority.p3Pending => AppColors.info,
    BookingPriority.p4WalkIn => AppColors.textSecondary,
  };

  bool get isMovableWithoutConfirmation => this != BookingPriority.p1ConfirmedPaid;
}
```

## 5. Buffer time — invisible côté client

```dart
DateTime computeBufferEndTime(DateTime endTime, int bufferMin) {
  return endTime.add(Duration(minutes: bufferMin));
}
```

- `buffer_end_time = end_time + service.buffer_min` (ex. +10 min après une coloration).
- Bloque uniquement le planning du praticien pour nettoyage/préparation.
- **Jamais affiché au client** lors de la sélection de créneau en ligne (R18) — la disponibilité présentée au client masque ce tampon, elle utilise `buffer_end_time` comme borne réelle d'indisponibilité sans l'exposer dans l'UI.
- Configurable par service depuis le catalogue Owner (`services.buffer_min`).

## 6. Workflow No-Show

```
H+15min : Praticien tape [Absent] sur le tile RDV
   │
   ├─► Push client : "Nous n'avons pas pu vous accueillir. Reprenez RDV."
   ├─► Statut → NO_SHOW · créneau libéré (tuile grisée rayée)
   └─► reliability_score -= 1

Après 3 no-shows du même client :
   ├─► Warning Owner : "Ce client a 3 absences non excusées."
   └─► Option : [Requérir un acompte pour ses prochains RDV]
```

```typescript
// supabase/functions/mark-no-show/index.ts (extrait)
await supabase.from("bookings").update({ status: "no_show" }).eq("id", bookingId);

const { data: client } = await supabase
  .from("users")
  .select("reliability_score")
  .eq("id", clientId).single();

await supabase.from("users")
  .update({ reliability_score: Math.max(0, client.reliability_score - 1) })
  .eq("id", clientId);

const { count } = await supabase
  .from("bookings")
  .select("id", { count: "exact", head: true })
  .eq("client_id", clientId).eq("status", "no_show");

if (count >= 3) {
  await supabase.from("users").update({ deposit_required: true }).eq("id", clientId);
  await notifyOwner(salonId, `Ce client a ${count} absences non excusées.`);
}
```

`reliability_score` ne descend jamais sous 0, et n'est jamais visible côté Client (R18) — uniquement Owner/Staff.

## 7. Score de fiabilité — grilles et conséquences

| Grade | Score | Point couleur | Conséquences |
|---|---|---|---|
| Fiable | 80-100 | 🟢 | Réservation libre, aucune restriction |
| Standard | 50-79 | ⚪ | Rappels renforcés, aucune restriction |
| À surveiller | 25-49 | 🟠 | Max 1 RDV simultané, alerte Owner, acompte recommandé |
| Risque | 0-24 | 🔴 | Confirmation manuelle Owner, acompte fortement recommandé |

Score = présence (60%) + respect délais annulation (25%) + ancienneté (15%). Actif après ≥3 RDV passés. **Local au salon** — non transférable d'un salon à un autre (R09).

## 8. Fast-Pass "Réserver à nouveau" (2 clics)

```
Tap "Réserver à nouveau" (fiche salon ou onglet Appointments)
   │  (pas de catalogue, pas de choix praticien)
   ▼
Redirection directe → Étape 1 : Sélection Date & Heure
   - service du dernier RDV pré-coché
   - praticien habituel pré-sélectionné
   ▼
Choisir heure → Confirmer → RDV créé
```

```dart
// presentation/providers/fast_pass_provider.dart
Future<void> startFastPass(String lastBookingId) async {
  final lastBooking = await ref.read(bookingRepositoryProvider).getById(lastBookingId);
  ref.read(bookingDraftProvider.notifier).prefill(
    serviceId: lastBooking.serviceId,
    practitionerId: lastBooking.practitionerId,
  );
  router.goNamed('bookingDateTime'); // saute direct à l'étape 1, pas le tunnel complet
}
```

Le tunnel complet (4 étapes : Date&Heure → Services&Notes → Récap → Succès) reste disponible pour un nouveau choix de service ; Fast-Pass ne fait que pré-remplir et raccourcir à 2 taps perçus (Réserver à nouveau → Confirmer heure).

## 9. Drag & Drop — règles calendrier Owner/Manager

| Action | Résultat |
|---|---|
| Long press 500ms sur tile | Active le mode Drag & Drop, menu compact : Déplacer · Dupliquer · Absent · Annuler |
| Drop sur créneau libre | Pop-up *"Déplacer [Nom] de [H1] à [H2] ?"* → [Confirmer] / [Annuler] |
| Drop sur créneau occupé | **Bloqué**. Message : *"Créneau pris."* — aucun écrasement silencieux jamais |
| Après confirmation | SMS automatique au client + notification praticien concerné |

```dart
void onDropSlot(BookingTile dragged, TimeSlot target) {
  if (target.isOccupied) {
    showKynzaToast(message: 'Créneau pris.', level: ToastLevel.error);
    return;
  }
  showConfirmDialog(
    message: 'Déplacer ${dragged.clientName} de ${dragged.startTime} à ${target.startTime} ?',
    onConfirm: () => ref.read(calendarProvider.notifier).moveBooking(dragged.id, target.startTime),
  );
}
```

## 10. Interface Caméléon — Solo vs Team

| Mode | Déclencheur | UI principale | Différences clés |
|---|---|---|---|
| Solo | `employees_count = 0` | Calendrier 1 colonne | Pas de module Équipe, Dashboard simplifié |
| Team | `employees_count ≥ 1` | Calendrier multi-colonnes | Module Staff, métriques équipe, classement |

```dart
// presentation/widgets/calendar_view.dart
class CalendarView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(salonStreamProvider); // alimenté par Supabase Realtime
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400), // R15
      child: salon.employeesCount == 0
          ? const SoloCalendarColumn(key: ValueKey('solo'))
          : const TeamCalendarColumns(key: ValueKey('team')),
    );
  }
}
```

La bascule est pilotée par Supabase Realtime sur `salons.employees_count` — jamais par un état local recalculé manuellement, pour rester cohérent dès qu'un Owner ajoute/retire un collaborateur depuis un autre device.

## 11. Suppression d'un collaborateur avec RDV futurs

- Le système **refuse** la suppression brute s'il existe des `bookings` futurs avec `practitioner_id` = ce collaborateur.
- L'Owner est contraint de choisir un collaborateur de substitution pour transférer les RDV futurs.
- Notification WhatsApp personnalisée envoyée à chaque client concerné : *"Votre praticien a changé : [Nouveau praticien] vous accueillera le [Date]."*

```sql
CREATE OR REPLACE FUNCTION prevent_staff_deletion_with_future_bookings()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM bookings
    WHERE practitioner_id = OLD.id AND start_time > now() AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Impossible de supprimer : RDV futurs existants. Choisissez un substitut.';
  END IF;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_prevent_staff_deletion
  BEFORE DELETE ON users
  FOR EACH ROW
  WHEN (OLD.role = 'staff')
  EXECUTE FUNCTION prevent_staff_deletion_with_future_bookings();
```

## 12. Checklist avant de toucher au moteur de réservation

1. Toute nouvelle transition de statut vérifiée contre le graphe valide (section 1).
2. Toute création de booking passe par la contrainte `UNIQUE(practitioner_id, start_time)` + gestion explicite de l'erreur `23505`.
3. `buffer_end_time` recalculé si `service.buffer_min` change — jamais stocké sans recalcul à la modification du service.
4. Aucune désactivation du verrou 5 minutes même "temporairement pour tester".
5. Aucun écran d'agenda n'affiche les montants des collègues à un Staff (R11).
6. Le score de fiabilité reste invisible côté Client sur tout nouvel écran (R18).
