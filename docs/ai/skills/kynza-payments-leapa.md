# KYNZA SKILL — PAYMENTS LEAPA | Version 1.0 | Lire avant toute intervention

> Domaine : intégration Leapa API (Mobile Money Burundi), flux non-custodial, idempotence, remboursements.
> Ne couvre PAS : RLS/schéma générique (→ `kynza-supabase-backend.md`), machine à états booking (→ `kynza-booking-engine.md`).

## 1. Principe non-custodial — rappel non-négociable (R01)

KYNZA n'est **jamais** dépositaire de fonds. Leapa est l'intermédiaire agréé Mobile Money. L'argent va directement du Mobile Money du Client vers le Mobile Money de l'Owner. La table `transactions` est un miroir comptable, pas un solde réel. Toute fonctionnalité qui ferait apparaître KYNZA comme détenteur de fonds (ex. "solde KYNZA", "retrait depuis KYNZA") est interdite par construction.

## 2. Flux complet étape par étape

```
1. Client tap [Payer] → sélection méthode (Lumicash / EcoCash)
2. Flutter → Edge Function `create-payment`
     - vérifie le booking, calcule amount_bif, génère idempotency_key
3. Edge Function → Leapa API `POST /payments/initiate`
     - payload signé, idempotency_key obligatoire dans le header
4. Leapa → USSD push vers le téléphone du client (délai max 3 min)
5. Client valide avec son PIN Mobile Money
6. Leapa → Webhook `POST /leapa-webhook` (signature HMAC-SHA256)
7. Edge Function `leapa-webhook` → vérifie HMAC → update transactions.status
8. Si status=completed → bookings.status='confirmed', payment_status='completed'
9. Supabase Realtime → Flutter (<300ms) → écran succès + Push FCM + WhatsApp
10. Argent → DIRECTEMENT Mobile Money de l'Owner (jamais via KYNZA)
```

Aucune étape ne doit être contournée. En particulier, l'étape 2 (Edge Function) est obligatoire — Flutter n'appelle **jamais** Leapa directement (R16) car la clé API Leapa ne doit jamais transiter côté client.

## 3. Idempotency key — format et garanties

```dart
// core/utils/payment_utils.dart
String buildIdempotencyKey(String bookingId) {
  final windowMinute = (DateTime.now().millisecondsSinceEpoch / 60000).floor();
  return '${bookingId}_$windowMinute';
}
```

- Format : `${bookingId}_${Math.floor(Date.now()/60000)}` — une fenêtre de 60 secondes par booking.
- Stockée en `UNIQUE` sur `transactions.idempotency_key` ET passée à Leapa dans le header `Idempotency-Key`.
- Un double-tap sur `[Payer]` dans la même minute génère la même clé → Leapa et Supabase rejettent silencieusement le doublon, aucun double débit possible.
- Le bouton `[Payer]` est désactivé immédiatement au premier tap côté UI, indépendamment de la garantie serveur (défense en profondeur).

## 4. Edge Function — création de paiement

```typescript
// supabase/functions/create-payment/index.ts
import { buildIdempotencyKey } from "../_shared/payment_utils.ts";

Deno.serve(async (req) => {
  const { bookingId, method } = await req.json();
  const supabase = createServiceRoleClient();

  const { data: booking, error } = await supabase
    .from("bookings")
    .select("id, salon_id, amount_bif, status")
    .eq("id", bookingId)
    .is("deleted_at", null)
    .single();

  if (error || !booking) {
    return jsonResponse({ error: "booking_not_found" }, 404);
  }
  if (booking.status !== "pending_payment") {
    return jsonResponse({ error: "booking_not_payable" }, 409);
  }

  const idempotencyKey = buildIdempotencyKey(bookingId);

  const { error: txError } = await supabase.from("transactions").insert({
    salon_id: booking.salon_id,
    booking_id: booking.id,
    amount_bif: booking.amount_bif,
    method,
    status: "pending",
    idempotency_key: idempotencyKey,
  });
  if (txError) {
    // conflit UNIQUE = doublon déjà en cours, on renvoie l'état existant
    return jsonResponse({ idempotencyKey, alreadyPending: true }, 200);
  }

  const leapaRes = await fetch("https://api.leapa.bi/v1/payments/initiate", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("LEAPA_API_KEY")}`,
      "Idempotency-Key": idempotencyKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: booking.amount_bif,
      currency: "BIF",
      method,
      reference: idempotencyKey,
    }),
  });

  if (!leapaRes.ok) {
    await supabase.from("transactions")
      .update({ status: "failed" })
      .eq("idempotency_key", idempotencyKey);
    return jsonResponse({ error: "leapa_initiation_failed" }, 502);
  }

  await supabase.from("transactions")
    .update({ status: "processing" })
    .eq("idempotency_key", idempotencyKey);

  return jsonResponse({ idempotencyKey, status: "processing" }, 200);
});
```

## 5. Validation HMAC-SHA256 du webhook

```typescript
// supabase/functions/_shared/hmac.ts
import { createHmac, timingSafeEqual } from "node:crypto";

export function verifyLeapaSignature(rawBody: string, signature: string, secret: string): boolean {
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  const a = new TextEncoder().encode(expected);
  const b = new TextEncoder().encode(signature);
  return a.length === b.length && timingSafeEqual(a, b);
}
```

Règle absolue : **toujours** lire le `rawBody` brut avant tout `JSON.parse`, car la signature porte sur les octets exacts envoyés par Leapa — un body re-sérialisé ne matchera jamais la signature.

## 6. Machine à états transaction

```
pending     → créneau verrouillé 5 min, en attente d'initiation Leapa
processing  → push USSD envoyé au client, attente PIN (max 3 min)
completed   → argent transféré, booking → CONFIRMED_PAID (badge doré)
failed      → PIN incorrect / timeout, aucun débit, créneau libéré < 1.5s
reversed    → remboursement validé, retour Mobile Money client
expired     → timeout 15 min général, créneau libéré, push client
```

Transitions valides uniquement : `pending→processing`, `processing→completed`, `processing→failed`, `completed→reversed`, `pending|processing→expired`. Toute transition hors de cette liste doit être rejetée par l'Edge Function (log dans `activity_logs` si tentative anormale).

## 7. Gestion du timeout USSD (3 min)

```dart
// presentation/widgets/ussd_waiting_view.dart
class UssdWaitingView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<TransactionStatus>(
      stream: ref.watch(transactionStatusStreamProvider(idempotencyKey)),
      builder: (context, snapshot) {
        if (snapshot.data == TransactionStatus.completed) {
          return const PaymentSuccessView();
        }
        if (snapshot.data == TransactionStatus.failed) {
          return const PaymentFailedView();
        }
        return RadarPulseAnimation(
          // Onde "Radar Pulse" dorée + compte à rebours visuel
          duration: const Duration(seconds: 60),
          maxWait: const Duration(minutes: 3),
          onTimeout: () => ref.read(transactionProvider.notifier).markExpired(),
          message: 'Votre demande est envoyée. Attendez le message sur votre téléphone.',
        );
      },
    );
  }
}
```

- Animation : Onde Radar Pulse dorée, ~60s perçus, compte à rebours jusqu'à 3 min réel.
- À l'expiration : statut → `failed`/`expired`, créneau libéré côté `bookings`, message anti-stress (section 8).
- Le suivi se fait via `StreamProvider` Realtime sur `transactions` filtré par `idempotency_key`, jamais par polling agressif côté client (le polling de secours offline est décrit section 10).

## 8. Messages UX anti-stress — jamais dire / toujours dire

| Situation | ❌ Ne jamais dire | ✅ Toujours dire |
|---|---|---|
| Attente USSD | "Processing..." | "Votre demande est envoyée. Attendez le message sur votre téléphone." |
| Paiement réussi | "Payment successful" | "✅ Payé ! Votre place est réservée chez [Salon]." |
| Paiement échoué | "Error: Payment failed" | "Ce paiement n'a pas abouti. Aucun argent débité. Réessayez ?" |
| Timeout | "Session expired" | "Le délai a dépassé. Aucun montant prélevé. Réessayez." |
| Remboursement | "Refund processing" | "Votre remboursement est en cours. Vous recevrez votre argent dans 24-72h." |

Aucun code HTTP, aucun terme technique anglais brut, aucune mention de stack trace ne doit jamais atteindre l'UI Client ou Owner sur un flux de paiement.

## 9. Remboursement — flow OTP Owner → Leapa Payout

```
1. Owner tap [Initier un remboursement] sur une transaction completed
2. Edge Function `request-refund-otp` → SMS OTP envoyé au numéro Owner vérifié
3. Owner saisit le code OTP reçu
4. Edge Function `confirm-refund` → vérifie OTP → appelle Leapa Payout API
5. Leapa exécute le virement retour vers le Mobile Money du Client
6. transactions.status = 'reversed' · activity_logs : type_action='refund_initiated'
```

```typescript
// supabase/functions/confirm-refund/index.ts
Deno.serve(async (req) => {
  const { transactionId, otpCode, refundPercent } = await req.json();
  const supabase = createServiceRoleClient();
  const user = await getAuthenticatedUser(req);

  if (user.role !== "owner") {
    return jsonResponse({ error: "forbidden" }, 403); // R17
  }

  const otpValid = await verifyOtp(user.phone, otpCode);
  if (!otpValid) {
    return jsonResponse({ error: "invalid_otp" }, 401);
  }

  const { data: tx } = await supabase
    .from("transactions").select("amount_bif, leapa_reference")
    .eq("id", transactionId).single();

  const refundAmount = Math.round(tx.amount_bif * (refundPercent / 100));

  await fetch("https://api.leapa.bi/v1/payouts", {
    method: "POST",
    headers: { "Authorization": `Bearer ${Deno.env.get("LEAPA_API_KEY")}` },
    body: JSON.stringify({ reference: tx.leapa_reference, amount: refundAmount }),
  });

  await supabase.from("transactions").update({ status: "reversed" }).eq("id", transactionId);
  await supabase.from("activity_logs").insert({
    salon_id: user.salon_id, user_id: user.id,
    type_action: "refund_initiated",
    new_values: { transactionId, refundAmount, refundPercent },
  });

  return jsonResponse({ status: "reversed", refundAmount }, 200);
});
```

### Barème de remboursement automatique (annulation par le client)
| Délai avant RDV | % remboursé |
|---|---|
| > 4h | 100% automatique |
| 2-4h | % configuré par le salon (ex. 50%) |
| < 2h | 0% par défaut, configurable |

Annulation d'un RDV **P1 (CONFIRMED_PAID)** par l'Owner lui-même → remboursement Leapa déclenché automatiquement à 100%, sans passer par le flow OTP manuel (l'Owner annule, ce n'est pas le client qui demande).

## 10. Prévention du double paiement

1. **Client** : bouton `[Payer]` désactivé dès le premier tap (`isLoading` state).
2. **Edge Function** : `INSERT` sur `transactions` avec `idempotency_key UNIQUE` → conflit = doublon détecté, requête renvoyée sans nouvel appel Leapa.
3. **Leapa** : header `Idempotency-Key` garantit l'unicité même si deux requêtes HTTP distinctes arrivent côté Edge Function (ex. retry réseau).
4. **Détection a posteriori (ERR_006)** : job de réconciliation périodique qui détecte un double débit malgré tout (bug tiers) → remboursement automatique du doublon en < 24h, log `activity_logs`.

## 11. Paiement offline — file cash uniquement

Mobile Money **requiert** le réseau (impossible offline). Seul l'**encaissement Cash** peut être enregistré hors-ligne :

```dart
// data/datasources/checkout_local_datasource.dart
Future<void> queueCashPayment(CashPaymentDraft draft) async {
  final box = await Hive.openBox<CashPaymentDraft>('cash_payment_queue');
  await box.add(draft);
}

// Worker de synchro, déclenché à la reconnexion (ordre R03 : Cash = étape 3)
Future<void> syncCashPaymentQueue() async {
  final box = await Hive.openBox<CashPaymentDraft>('cash_payment_queue');
  for (final draft in box.values.toList()) {
    await supabase.from("transactions").insert({
      ...draft.toJson(),
      "method": "cash",
      "status": "completed",
    });
    await box.delete(draft.key);
  }
}
```

Si le réseau est indisponible et que le client veut payer en Mobile Money : afficher l'option de secours "Payer sur place" (cf. edge case Mobile Money hors service), jamais bloquer l'écran sans alternative (R04).

## 12. Checklist avant de toucher au code paiement

1. Tout nouveau flux passe par une Edge Function — jamais d'appel Leapa direct Flutter.
2. `idempotency_key` généré et vérifié `UNIQUE` avant tout appel externe.
3. Webhook : HMAC vérifié sur le `rawBody` avant tout traitement, retour 401 sinon.
4. Aucun message UX ne reprend un code HTTP ou jargon technique (section 8).
5. Tout remboursement manuel passe par OTP SMS Owner (R17) — aucune exception.
6. Transition de statut transaction validée contre la liste autorisée (section 6).
7. Test du cas timeout (3 min USSD) et du cas double-tap avant de livrer.
