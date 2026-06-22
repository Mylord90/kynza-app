# KYNZA SKILL — SECURITY & DEVSECOPS | Version 1.0 | Lire avant toute intervention

> Domaine : process de sécurité opérationnel, gestion de sessions, audit trail, rate limiting, tests RLS.
> Pour le détail SQL des policies RLS et triggers de colonnes, voir `kynza-supabase-backend.md` §3-4 — ce fichier ne le répète pas, il décrit le **process** qui encadre ce code.

## 1. Checklist sécurité — avant chaque PR (10 points)

1. Toute nouvelle table a RLS activé (`ENABLE ROW LEVEL SECURITY`) — aucune table sans policy n'est mergée.
2. Aucune policy `USING (true)` sur une table financière, personnelle ou d'audit.
3. `salon_id` utilisé dans les policies provient toujours de `auth.jwt()->>'salon_id'`, jamais d'un paramètre transmis par le client.
4. Toute colonne sensible ajoutée à `users` (score, rôle, statut) est ajoutée à `protect_user_columns()`.
5. Toute fonction `SECURITY DEFINER` a un `REVOKE EXECUTE FROM authenticated, anon` explicite, sauf si elle est volontairement appelable par le client (cas rare, justifié en commentaire SQL).
6. Tout nouveau webhook externe valide une signature (HMAC ou équivalent) avant tout traitement métier.
7. Aucune clé API, token ou secret n'apparaît dans le code, les logs, ou un fichier commité — uniquement Supabase Vault / variables d'environnement Edge Function.
8. Toute action destructive ou financière critique (remboursement, suppression, remise > seuil) écrit une entrée dans `activity_logs`.
9. Les tests de sécurité RLS (`npm run test:security`) passent pour les 4 rôles avant merge.
10. Aucune donnée financière ou personnelle n'est exposée dans un message d'erreur retourné au client (toujours un message générique côté UX, détail technique uniquement en log serveur).

Une PR qui touche à l'authentification, aux paiements ou aux tables financières ne peut pas être mergée sans qu'un humain ait explicitement validé cette checklist en revue.

## 2. Gestion des sessions

| Rôle | Règle |
|---|---|
| Staff | Session expire après 7 jours d'inactivité (R20) |
| Owner | Peut révoquer une session distante d'un collaborateur en 1 tap |
| Tous | JWT contient `salon_id` + `role` dans les claims, vérifié côté serveur à chaque requête |

```sql
-- Révocation Owner : invalide les refresh tokens du collaborateur ciblé
CREATE OR REPLACE FUNCTION revoke_user_sessions(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- nécessite que l'appelant soit owner du salon concerné (vérifié par l'Edge Function appelante)
  DELETE FROM auth.refresh_tokens WHERE user_id = p_user_id;
  NOTIFY realtime_force_logout, p_user_id::text; -- déclenche la coupure Realtime instantanée
END;
$$;

REVOKE EXECUTE ON FUNCTION revoke_user_sessions(UUID) FROM authenticated, anon;
GRANT EXECUTE ON FUNCTION revoke_user_sessions(UUID) TO service_role;
```

```typescript
// supabase/functions/revoke-staff-session/index.ts
Deno.serve(async (req) => {
  const { staffUserId } = await req.json();
  const owner = await getAuthenticatedUser(req);
  if (owner.role !== "owner") return jsonResponse({ error: "forbidden" }, 403);

  const supabase = createServiceRoleClient();
  const { data: staff } = await supabase.from("users").select("salon_id").eq("id", staffUserId).single();
  if (staff.salon_id !== owner.salon_id) return jsonResponse({ error: "forbidden" }, 403);

  await supabase.rpc("revoke_user_sessions", { p_user_id: staffUserId });
  return jsonResponse({ status: "revoked" }, 200);
});
```

Côté client, l'écoute du canal `realtime_force_logout` (ou équivalent broadcast Realtime) doit déclencher une déconnexion immédiate et un retour à l'écran de connexion — jamais un simple message d'erreur ignorable.

## 3. Audit trail — `activity_logs`

```typescript
// supabase/functions/_shared/audit.ts
export async function logActivity(
  supabase: SupabaseClient,
  params: { salonId: string; userId: string; typeAction: string; oldValues?: object; newValues?: object; ip?: string },
) {
  await supabase.from("activity_logs").insert({
    salon_id: params.salonId,
    user_id: params.userId,
    type_action: params.typeAction,
    old_values: params.oldValues ?? null,
    new_values: params.newValues ?? null,
    ip_address: params.ip ?? null,
  });
}
```

Événements à logger obligatoirement (liste non exhaustive, à étendre par analogie) :

| Événement | type_action |
|---|---|
| Modification prix service | `price_updated` |
| Annulation manuelle d'un RDV | `booking_cancelled` |
| Remboursement initié | `refund_initiated` |
| Suppression d'un utilisateur | `user_deleted` |
| Remise > 5% appliquée par un Manager (R19) | `discount_applied` |
| Révocation de session | `session_revoked` |

`activity_logs` est append-only : aucune policy `UPDATE`/`DELETE` n'existe jamais sur cette table (cf. `kynza-supabase-backend.md` §3 Profil E). Toute tentative de modification a posteriori d'un log doit être un signal d'alerte fort en revue de code.

## 4. Rate limiting & protection DDoS

- Limite applicative : 100 req/min par utilisateur authentifié, appliquée au niveau Edge Function (compteur Redis/Upstash ou table Supabase à TTL court selon l'infra retenue).
- Protection DDoS : déléguée à la couche Supabase/Cloudflare native, pas de réinvention côté application.
- Tout endpoint Edge Function exposé publiquement (webhook Leapa, hooks) doit avoir une limite de débit spécifique et plus stricte que les endpoints authentifiés classiques, car non protégé par un token utilisateur.

```typescript
// supabase/functions/_shared/rate_limit.ts
export async function checkRateLimit(supabase: SupabaseClient, key: string, limit = 100, windowSec = 60): Promise<boolean> {
  const { data, error } = await supabase.rpc("increment_rate_counter", { p_key: key, p_window_sec: windowSec });
  if (error) return true; // fail-open contrôlé : ne jamais bloquer un paiement légitime sur un bug de compteur
  return data <= limit;
}
```

## 5. Secrets management

- Toute clé (`LEAPA_API_KEY`, `LEAPA_WEBHOOK_SECRET`, `FCM_SERVER_KEY`, `WHATSAPP_TOKEN`) vit dans Supabase Vault ou les variables d'environnement des Edge Functions.
- Jamais de secret dans `pubspec.yaml`, dans un fichier `.dart` commité, ou dans une variable `--dart-define` versionnée.
- Rotation : toute clé suspectée compromise est révoquée côté fournisseur (Leapa/Firebase/Meta) **avant** d'être retirée du Vault — l'ordre inverse laisse une fenêtre d'exploitation.
- `.env`/`.env.local` systématiquement dans `.gitignore`, jamais d'exception.

## 6. Tests de sécurité — template Vitest RLS

```typescript
// src/__tests__/security/rls.test.ts (extrait — suite "transactions")
import { describe, it, expect, beforeAll } from "vitest";
import { createClientForRole } from "../helpers/test-clients";

describe("RLS · transactions", () => {
  let ownerClient, staffClient, clientClient;

  beforeAll(async () => {
    ownerClient = await createClientForRole("owner", { salonId: TEST_SALON_A });
    staffClient = await createClientForRole("staff", { salonId: TEST_SALON_A });
    clientClient = await createClientForRole("client", { salonId: TEST_SALON_A });
  });

  it("owner peut lire les transactions de son salon", async () => {
    const { data, error } = await ownerClient.from("transactions").select("*");
    expect(error).toBeNull();
    expect(data).not.toBeNull();
  });

  it("staff ne peut PAS lire les transactions du salon", async () => {
    const { data } = await staffClient.from("transactions").select("*");
    expect(data).toEqual([]); // RLS filtre silencieusement, pas d'erreur 500
  });

  it("client ne peut PAS lire les transactions d'un autre salon", async () => {
    const otherSalonClient = await createClientForRole("owner", { salonId: TEST_SALON_B });
    const { data } = await otherSalonClient.from("transactions").select("*").eq("salon_id", TEST_SALON_A);
    expect(data).toEqual([]);
  });

  it("aucun rôle ne peut INSERT directement une transaction (passage Edge Function obligatoire)", async () => {
    const { error } = await ownerClient.from("transactions").insert({ amount_bif: 1000, method: "lumicash" });
    expect(error).not.toBeNull(); // pas de policy INSERT côté client = rejet attendu
  });
});
```

Les 6 suites RLS obligatoires (une par table sensible) : `transactions`, `subscriptions`, `bookings`, `users`, `activity_logs`, `loyalty_cards`. Chaque suite teste au minimum : accès autorisé pour le bon rôle, refus pour les rôles non autorisés, isolation cross-salon, refus d'écriture directe sur les tables réservées aux Edge Functions.

## 7. Couches de sécurité — vue d'ensemble

```
Couche 1 — Flutter UI         : garde de rôle sur la navigation (GoRouter guards)
Couche 2 — Supabase RLS       : USING/WITH CHECK sur chaque table
Couche 3 — Triggers Postgres  : protection des colonnes immuables
Couche 4 — Edge Functions     : seule voie d'écriture pour paiements/remboursements/révocations
Couche 5 — Webhooks signés    : HMAC-SHA256 sur tout événement entrant externe
Couche 6 — Transport          : HTTPS + TLS 1.3 sur tous les endpoints
Couche 7 — Chiffrement repos  : AES-256 sur numéros Mobile Money et boxes Hive sensibles
```

Aucune couche ne doit être considérée comme suffisante seule — c'est la défense en profondeur (Couche 1 seule = contournable en patchant l'APK, Couche 2 seule = un bug RLS expose tout, etc.) qui garantit la sécurité réelle.

## 8. Numéros Mobile Money — chiffrement at-rest

```sql
-- chiffrement AES-256 via pgcrypto, jamais stocké en clair
CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE users ADD COLUMN phone_encrypted BYTEA;

CREATE OR REPLACE FUNCTION encrypt_phone(p_phone TEXT)
RETURNS BYTEA LANGUAGE sql SECURITY DEFINER AS $$
  SELECT pgp_sym_encrypt(p_phone, current_setting('app.encryption_key'));
$$;
```

La clé `app.encryption_key` est injectée au niveau de la configuration Postgres (Supabase Vault), jamais codée en dur dans une migration versionnée.
