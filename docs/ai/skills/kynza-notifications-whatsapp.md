# KYNZA SKILL — NOTIFICATIONS & WHATSAPP | Version 1.0 | Lire avant toute intervention

> Domaine : WhatsApp Business Cloud API, FCM, templates de messages, anti-spam, opt-out, deep links.
> Ne couvre PAS : logique de paiement déclenchant certaines notifications (→ `kynza-payments-leapa.md`).

## 1. Principe général

WhatsApp Business API en premier canal, Push FCM en second. **Jamais d'email** pour une alerte opérationnelle — adapté aux habitudes numériques africaines (faible usage email, fort usage WhatsApp, R14).

## 2. WhatsApp Business Cloud API — setup

```typescript
// supabase/functions/_shared/whatsapp.ts
const WA_TOKEN = Deno.env.get("WHATSAPP_TOKEN")!;
const WA_PHONE_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID")!;

export async function sendWhatsappTemplate(
  to: string, templateName: string, languageCode: "fr" | "rn", params: string[],
) {
  const res = await fetch(`https://graph.facebook.com/v19.0/${WA_PHONE_ID}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${WA_TOKEN}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to,
      type: "template",
      template: {
        name: templateName,
        language: { code: languageCode },
        components: [{ type: "body", parameters: params.map((p) => ({ type: "text", text: p })) }],
      },
    }),
  });
  if (!res.ok) throw new Error(`whatsapp_send_failed: ${await res.text()}`);
  return res.json();
}
```

Tout template envoyé doit être préalablement **approuvé** dans Meta Business Manager — aucun message libre (`type: "text"`) ne peut être envoyé en dehors d'une fenêtre de conversation ouverte de 24h initiée par le client.

## 3. Template confirmation de réservation

Format exact (issu du CDC, conservé à l'identique) :
```
🟢 CONFIRMATION - KYNZA

Bonjour [Prénom] ! Votre réservation est confirmée.

🏢 [Nom Salon] · 💇 [Service] · 🧑 [Praticien]
📅 [Date] · 🕐 [Heure] · 💰 [Prix] FBu
📍 [Adresse] · 🗺️ [Lien Maps court]

Modifier/annuler : [deep link app]

Merci pour votre confiance ! À très bientôt ✨
```

```typescript
await sendWhatsappTemplate(client.phone, "booking_confirmation", client.locale === "rn" ? "rn" : "fr", [
  client.firstName, salon.name, service.name, practitioner.firstName,
  formatDateFr(booking.startTime), formatTimeFr(booking.startTime),
  formatBif(booking.amountBif), salon.address, salon.mapsShortLink,
  `https://app.kynza.bi/booking/${booking.id}`,
]);
```

## 4. Templates rappels J-1 et H-2

| Rappel | Canal | Contenu clé | Action |
|---|---|---|---|
| H-24 | Push FCM | "Votre RDV chez [Salon] demain à [Heure]" | Ouvre `/booking/:id` |
| H-2 | Push FCM + bouton | "Votre RDV dans 2h chez [Salon]" + bouton **Confirmer** | Tap → `confirmed`, sinon ignoré silencieusement |

```typescript
// supabase/functions/send-reminders/index.ts (extrait, déclenché par cron)
const upcoming = await supabase.from("bookings")
  .select("*, salons(name), users!client_id(phone, locale)")
  .eq("status", "confirmed")
  .gte("start_time", windowStart).lte("start_time", windowEnd);

for (const booking of upcoming.data ?? []) {
  await sendFcmPush(booking.client_device_token, {
    title: "Rappel KYNZA",
    body: `Votre RDV chez ${booking.salons.name} ${isH2 ? "dans 2h" : "demain"} à ${formatTimeFr(booking.start_time)}`,
    data: { deepLink: `/booking/${booking.id}`, action: isH2 ? "confirm_button" : "none" },
  });
}
```

Rappels bridés à **2 occurrences max** par RDV (H-24 + H-2) — jamais de rappel supplémentaire ajouté "pour être sûr", même en cas de doute sur la livraison du premier.

## 5. Templates "Fill My Day" — 5 types × FR/Kirundi

| Type | Nom template Meta | Usage |
|---|---|---|
| Promo flash | `fill_day_promo_flash` | Trou agenda détecté, remise IA 10-30% |
| Nouveauté | `fill_day_new_service` | Annonce d'un nouveau service au catalogue |
| Remerciement | `fill_day_thank_you` | Post-visite, fidélisation douce |
| Relance | `fill_day_reactivation` | Client inactif >30j |
| Info | `fill_day_info` | Communication générale (horaires, fermeture) |

```typescript
const FILL_MY_DAY_SCRIPTS: Record<string, { fr: string; rn: string }> = {
  promo_flash: {
    fr: "🔥 [Salon] a des créneaux libres aujourd'hui ! -[X]% sur [Service] jusqu'à [Heure]. Réservez : [lien]",
    rn: "🔥 [Salon] ifise intumwa zisigaye uyu musi! -[X]% kuri [Service] gushika [Heure]. Andikisha: [lien]",
  },
  // ... new_service, thank_you, reactivation, info suivent le même schéma fr/rn
};
```

Chaque script reste **modifiable** par l'Owner avant envoi (prévisualisation obligatoire, cf. matrice marketing du CDC) — ce fichier décrit le contenu par défaut, pas un texte figé envoyé sans relecture.

## 6. FCM — Edge Function vers FCM v1 HTTP API

```typescript
// supabase/functions/_shared/fcm.ts
import { GoogleAuth } from "google-auth-library"; // ou JWT signé manuellement en Deno

async function getFcmAccessToken(): Promise<string> {
  const auth = new GoogleAuth({
    credentials: JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!),
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token!;
}

export async function sendFcmPush(deviceToken: string, payload: { title: string; body: string; data?: Record<string, string> }) {
  const accessToken = await getFcmAccessToken();
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: { title: payload.title, body: payload.body },
        data: payload.data ?? {},
      },
    }),
  });
}
```

`FCM_SERVICE_ACCOUNT_JSON` vit dans les variables d'environnement Edge Function — jamais embarqué dans l'app Flutter (qui n'a besoin que de la config publique `google-services.json`/`GoogleService-Info.plist` pour s'enregistrer auprès de FCM, pas de la service account serveur).

## 7. Deep links

| Lien | Écran cible | Rôle |
|---|---|---|
| `/booking/:id` | Détail réservation | Client |
| `/payment/:id` | Écran de paiement / reçu | Client |
| `/staff/today` | Écran Aujourd'hui | Staff |

```dart
// core/router/app_router.dart (extrait gestion deep link)
GoRoute(
  path: '/booking/:id',
  builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
),
```

Tout lien généré côté notification (WhatsApp ou Push) doit utiliser exactement ces chemins déclarés dans `core/router/routes.dart` — jamais un chemin "à la main" construit côté Edge Function sans les garder synchronisés.

## 8. Anti-spam — compteur côté Supabase

```sql
CREATE TABLE notification_quota (
  salon_id UUID REFERENCES salons(id),
  channel TEXT CHECK (channel IN ('whatsapp_promo','whatsapp_general')),
  window_start TIMESTAMPTZ NOT NULL,
  count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (salon_id, channel, window_start)
);

CREATE OR REPLACE FUNCTION check_and_increment_promo_quota(p_salon_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE v_week_start TIMESTAMPTZ := date_trunc('week', now());
DECLARE v_count INT;
BEGIN
  INSERT INTO notification_quota (salon_id, channel, window_start, count)
  VALUES (p_salon_id, 'whatsapp_promo', v_week_start, 1)
  ON CONFLICT (salon_id, channel, window_start)
  DO UPDATE SET count = notification_quota.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= 2; -- max 2 promos/semaine/salon (R12)
END;
$$;
```

```typescript
// avant tout envoi promo groupé
const allowed = await supabase.rpc("check_and_increment_promo_quota", { p_salon_id: salonId });
if (!allowed) return jsonResponse({ error: "weekly_promo_quota_reached" }, 429);
```

Limite complémentaire : max **50 messages WhatsApp/heure** par salon (throttling d'envoi en lot côté Edge Function `fill-my-day`, jamais un `Promise.all` sans limite sur une liste de destinataires).

## 9. Opt-out STOP/ARRET — automatique et immédiat (R13)

```typescript
// supabase/functions/whatsapp-inbound-webhook/index.ts (extrait)
const message = payload.entry[0].changes[0].value.messages?.[0];
if (message && /^(stop|arret|arrêt)$/i.test(message.text.body.trim())) {
  await supabase.from("users")
    .update({ whatsapp_opt_out: true })
    .eq("phone", message.from);
  await sendWhatsappTemplate(message.from, "opt_out_confirmation", "fr", []);
}
```

Toute fonction d'envoi promotionnel doit vérifier `whatsapp_opt_out = false` avant d'inclure un destinataire — vérification systématique, jamais une liste figée constituée une fois puis réutilisée sans recheck.

## 10. Matrice des déclencheurs — événement → canal → priorité

| Événement | Canal | Priorité | Hors-ligne |
|---|---|---|---|
| Nouvelle réservation payée | In-App Owner + WhatsApp Client | CRITIQUE · Instant | Queue Supabase → envoi à la reconnexion |
| Rappel RDV H-24 | Push Client | HAUTE | Ignorée si déconnecté |
| Rappel RDV H-2 + bouton Confirmer | Push + bouton | HAUTE | Ignorée si déconnecté |
| Annulation par le salon | WhatsApp Client + Push | CRITIQUE | SMS de secours si WhatsApp échoue |
| Échec transaction Leapa | In-App Owner + Push Client | HAUTE | Affiché à la reconnexion |
| No-show détecté | Push Owner | HAUTE | Affiché à la reconnexion |
| Badge fidélité gagné | In-App Client | BASSE | Cumulé en cache locale |
| Abonnement expirant J-7 | Push Owner | HAUTE | — |

## 11. Notifications et offline

- Les notifications Push/WhatsApp **nécessitent le réseau** par nature (R réseau requis, cf. `kynza-offline-realtime.md` §9) — elles ne sont jamais mises en queue côté client.
- C'est Supabase qui maintient la queue serveur pour les événements CRITIQUE (ex. nouvelle réservation payée alors que l'Owner est hors-ligne) : l'event est stocké et livré dès que le device de l'Owner revient en ligne et se réabonne au channel Realtime, ou au prochain réveil FCM.
- Côté client, un algorithme local stocke les IDs des notifications déjà reçues, pour appliquer un delta à la reconnexion et éviter les doublons d'affichage in-app.
