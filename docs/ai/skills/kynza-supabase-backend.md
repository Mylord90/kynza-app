# KYNZA SKILL — SUPABASE BACKEND | Version 1.0 | Lire avant toute intervention

> Domaine : schéma Postgres, RLS, triggers, JWT claims, Realtime, Edge Functions.
> Ne couvre PAS : logique Leapa détaillée (→ `kynza-payments-leapa.md`), checklist sécurité globale (→ `kynza-security-devsecops.md`).

## 1. Schéma complet des 8 tables core

Toute table KYNZA respecte trois invariants : `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `salon_id` pour le scoping multi-tenant (sauf `salons` elle-même), `deleted_at TIMESTAMPTZ` pour le soft delete (R12).

```sql
-- 1. salons
CREATE TABLE salons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free','pro','premium')),
  plan_status TEXT NOT NULL DEFAULT 'active' CHECK (plan_status IN ('active','grace_period','expired')),
  country_code TEXT NOT NULL DEFAULT 'BI',
  currency TEXT NOT NULL DEFAULT 'BIF',
  is_online BOOLEAN NOT NULL DEFAULT true,
  employees_count INT NOT NULL DEFAULT 0,
  address TEXT, lat DOUBLE PRECISION, lng DOUBLE PRECISION,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 2. users (1-1 avec auth.users, jamais de duplication d'auth)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  salon_id UUID REFERENCES salons(id),
  role TEXT NOT NULL CHECK (role IN ('owner','manager','staff','client')),
  phone TEXT UNIQUE,
  email TEXT,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  full_name TEXT,
  profile_completed BOOLEAN NOT NULL DEFAULT false,
  reliability_score INT NOT NULL DEFAULT 100 CHECK (reliability_score BETWEEN 0 AND 100),
  preferred_currency TEXT NOT NULL DEFAULT 'BIF',
  locale TEXT NOT NULL DEFAULT 'fr_BI',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 3. services
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  name TEXT NOT NULL,
  price_bif INT NOT NULL CHECK (price_bif >= 0),
  duration_min INT NOT NULL CHECK (duration_min > 0),
  buffer_min INT NOT NULL DEFAULT 0 CHECK (buffer_min >= 0),
  category TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 4. bookings — coeur du moteur de réservation
CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  client_id UUID NOT NULL REFERENCES users(id),
  practitioner_id UUID NOT NULL REFERENCES users(id),
  service_id UUID NOT NULL REFERENCES services(id),
  status TEXT NOT NULL DEFAULT 'pending_payment'
    CHECK (status IN ('pending_payment','confirmed','in_progress','completed','cancelled','no_show')),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  buffer_end_time TIMESTAMPTZ NOT NULL,
  amount_bif INT NOT NULL CHECK (amount_bif >= 0),
  payment_status TEXT NOT NULL DEFAULT 'pending',
  deposit_required BOOLEAN NOT NULL DEFAULT false,
  idempotency_key TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uq_practitioner_slot UNIQUE (practitioner_id, start_time)
);

-- 5. transactions
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  booking_id UUID REFERENCES bookings(id),
  leapa_reference TEXT UNIQUE,
  amount_bif INT NOT NULL CHECK (amount_bif >= 0),
  method TEXT NOT NULL CHECK (method IN ('lumicash','ecocash','enoti','cash','card')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','completed','failed','reversed','expired')),
  idempotency_key TEXT UNIQUE NOT NULL,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 6. subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  plan TEXT NOT NULL CHECK (plan IN ('free','pro','premium')),
  status TEXT NOT NULL DEFAULT 'active',
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  monthly_bookings_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- 7. loyalty_cards
CREATE TABLE loyalty_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  client_id UUID NOT NULL REFERENCES users(id),
  stamps INT NOT NULL DEFAULT 0,
  required INT NOT NULL DEFAULT 10,
  reward TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. activity_logs — append-only, jamais de deleted_at (rien n'est jamais retiré)
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES salons(id),
  user_id UUID NOT NULL REFERENCES users(id),
  type_action TEXT NOT NULL,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## 2. Indexes obligatoires

Chaque table multi-tenant doit avoir un index sur `salon_id` (toute requête RLS filtre dessus) plus les index spécifiques aux patterns d'accès du produit.

```sql
CREATE INDEX idx_users_salon_id ON users(salon_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_services_salon_id ON services(salon_id) WHERE deleted_at IS NULL;

CREATE INDEX idx_bookings_salon_id ON bookings(salon_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_bookings_practitioner_start ON bookings(practitioner_id, start_time);
CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_status ON bookings(status) WHERE deleted_at IS NULL;

CREATE INDEX idx_transactions_salon_id ON transactions(salon_id);
CREATE INDEX idx_transactions_booking_id ON transactions(booking_id);
CREATE UNIQUE INDEX idx_transactions_idempotency ON transactions(idempotency_key);

CREATE INDEX idx_subscriptions_salon_id ON subscriptions(salon_id);
CREATE INDEX idx_loyalty_client_salon ON loyalty_cards(client_id, salon_id);
CREATE INDEX idx_activity_logs_salon_id ON activity_logs(salon_id, created_at DESC);
```

## 3. Pattern RLS — un template par profil d'accès

Toujours activer RLS explicitement, puis écrire des policies positives (jamais de `USING (true)` sur une table sensible).

### Profil A — Owner only (wallet, transactions, subscriptions)
```sql
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY owner_only_select ON transactions
  FOR SELECT
  USING (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND (auth.jwt()->>'role') = 'owner'
  );
-- Aucune policy INSERT/UPDATE/DELETE côté client : ces écritures
-- passent exclusivement par Edge Functions avec la service_role key.
```

### Profil B — Staff own (bookings, my-clients)
```sql
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY staff_own_bookings ON bookings
  FOR SELECT
  USING (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND (
      (auth.jwt()->>'role') IN ('owner','manager')
      OR practitioner_id = auth.uid()
    )
  );

CREATE POLICY staff_update_own_bookings ON bookings
  FOR UPDATE
  USING (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND (
      (auth.jwt()->>'role') IN ('owner','manager')
      OR practitioner_id = auth.uid()
    )
  );
```

### Profil C — Client own (ses propres réservations, sa fidélité)
```sql
ALTER TABLE loyalty_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY client_own_loyalty ON loyalty_cards
  FOR SELECT
  USING (client_id = auth.uid());
```

### Profil D — Self row only (users), colonnes sensibles protégées par trigger (pas par RLS seule)
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_self_select ON users
  FOR SELECT
  USING (id = auth.uid() OR salon_id = (auth.jwt()->>'salon_id')::uuid);

CREATE POLICY users_self_update_safe ON users
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND salon_id = (SELECT salon_id FROM users WHERE id = auth.uid())
    AND role = (SELECT role FROM users WHERE id = auth.uid())
  );
```

`WITH CHECK` empêche qu'un `UPDATE` partiel modifie `salon_id` ou `role` même s'il ne les mentionne pas explicitement dans le payload — toujours comparer à la valeur déjà en base, jamais faire confiance au payload entrant.

### Profil E — Append-only (activity_logs)
```sql
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY logs_owner_select ON activity_logs
  FOR SELECT
  USING (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND (auth.jwt()->>'role') = 'owner'
  );

CREATE POLICY logs_self_insert_safe ON activity_logs
  FOR INSERT
  WITH CHECK (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND user_id = auth.uid()
    AND type_action IN (
      'booking_created','booking_cancelled','price_updated',
      'refund_initiated','user_deleted','discount_applied'
    )
  );
-- Pas de policy UPDATE/DELETE : la table est strictement append-only.
```

## 4. Triggers de protection des colonnes sensibles

```sql
CREATE OR REPLACE FUNCTION protect_user_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.salon_id IS DISTINCT FROM OLD.salon_id
     OR NEW.role IS DISTINCT FROM OLD.role
     OR NEW.email_verified IS DISTINCT FROM OLD.email_verified
     OR NEW.reliability_score IS DISTINCT FROM OLD.reliability_score THEN
    RAISE EXCEPTION 'Modification interdite des colonnes protégées';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_protect_user_columns
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION protect_user_columns();

-- Seules les Edge Functions (service_role, qui contourne les triggers via
-- une fonction dédiée SECURITY DEFINER) peuvent légitimement faire évoluer
-- reliability_score ou role — jamais l'API publique authenticated.

REVOKE EXECUTE ON FUNCTION protect_user_columns() FROM authenticated, anon;
```

```sql
CREATE OR REPLACE FUNCTION sync_email_verified()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET email_verified = (NEW.email_confirmed_at IS NOT NULL)
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_email_verified
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_email_verified();

REVOKE EXECUTE ON FUNCTION sync_email_verified() FROM authenticated, anon;
```

## 5. Fonction `has_role` — scoping centralisé

```sql
CREATE OR REPLACE FUNCTION has_role(p_role TEXT, p_salon_id UUID DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY INVOKER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND role = p_role
      AND (p_salon_id IS NULL OR salon_id = p_salon_id)
      AND deleted_at IS NULL
  );
$$;
```

Utilisation dans une policy :
```sql
CREATE POLICY marketing_owner_manager ON marketing_campaigns
  FOR ALL
  USING (
    salon_id = (auth.jwt()->>'salon_id')::uuid
    AND (has_role('owner', salon_id) OR has_role('manager', salon_id))
  );
```

`SECURITY INVOKER` (et non `DEFINER`) car la fonction ne fait que lire avec les droits de l'appelant — elle ne doit jamais élever de privilège.

## 6. JWT custom claims hook

```sql
CREATE OR REPLACE FUNCTION custom_access_token_hook(event JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  claims JSONB;
  user_row RECORD;
BEGIN
  SELECT salon_id, role, preferred_currency INTO user_row
  FROM public.users WHERE id = (event->>'user_id')::uuid;

  claims := event->'claims';
  claims := jsonb_set(claims, '{salon_id}', to_jsonb(user_row.salon_id));
  claims := jsonb_set(claims, '{role}', to_jsonb(user_row.role));
  claims := jsonb_set(claims, '{preferred_currency}', to_jsonb(user_row.preferred_currency));

  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

REVOKE EXECUTE ON FUNCTION custom_access_token_hook(JSONB) FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION custom_access_token_hook(JSONB) TO supabase_auth_admin;
```

À enregistrer dans Supabase Dashboard → Authentication → Hooks → Custom Access Token. Toute modification de `role` ou `salon_id` en base ne prend effet dans le JWT qu'au prochain refresh token — penser à forcer un `refreshSession()` côté client après un changement de rôle.

## 7. Realtime — channels et optimistic UI

```dart
// pattern recommandé : un channel par salon, jamais un channel global
final channel = supabase
    .channel('bookings:salon:$salonId')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'bookings',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'salon_id',
        value: salonId,
      ),
      callback: (payload) => _debouncedRefresh(),
    )
    .subscribe();
```

```dart
// debounce 300ms obligatoire : Realtime peut envoyer plusieurs events
// rapprochés (ex. insert + update du même booking)
Timer? _debounceTimer;
void _debouncedRefresh() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    ref.invalidate(calendarStreamProvider);
  });
}
```

Pattern optimistic UI : appliquer l'état local immédiatement (R06 — feedback <1s), puis réconcilier silencieusement avec l'event Realtime confirmé. En cas de divergence, le serveur gagne toujours (Server-Wins, cf. `kynza-offline-realtime.md`).

## 8. Edge Function Deno — template webhook Leapa avec HMAC

```typescript
// supabase/functions/leapa-webhook/index.ts
import { createHmac, timingSafeEqual } from "node:crypto";

const LEAPA_WEBHOOK_SECRET = Deno.env.get("LEAPA_WEBHOOK_SECRET")!;

function verifyHmac(rawBody: string, signatureHeader: string): boolean {
  const expected = createHmac("sha256", LEAPA_WEBHOOK_SECRET)
    .update(rawBody)
    .digest("hex");
  const expectedBuf = new TextEncoder().encode(expected);
  const givenBuf = new TextEncoder().encode(signatureHeader);
  if (expectedBuf.length !== givenBuf.length) return false;
  return timingSafeEqual(expectedBuf, givenBuf);
}

Deno.serve(async (req) => {
  const rawBody = await req.text();
  const signature = req.headers.get("x-leapa-signature") ?? "";

  if (!verifyHmac(rawBody, signature)) {
    return new Response("invalid signature", { status: 401 });
  }

  const payload = JSON.parse(rawBody);
  const { idempotency_key, status, leapa_reference } = payload;

  const supabase = createServiceRoleClient(); // service_role, bypass RLS

  const { data: existing } = await supabase
    .from("transactions")
    .select("status")
    .eq("idempotency_key", idempotency_key)
    .single();

  if (existing?.status === "completed") {
    return new Response("already processed", { status: 200 }); // idempotence
  }

  await supabase
    .from("transactions")
    .update({ status, leapa_reference, confirmed_at: new Date().toISOString() })
    .eq("idempotency_key", idempotency_key);

  if (status === "completed") {
    await supabase
      .from("bookings")
      .update({ status: "confirmed", payment_status: "completed" })
      .eq("idempotency_key", idempotency_key);
  }

  return new Response("ok", { status: 200 });
});
```

Toute clé secrète (`LEAPA_WEBHOOK_SECRET`, `LEAPA_API_KEY`) vit exclusivement dans Supabase Vault / variables d'environnement Edge Function — jamais dans le repo, jamais côté client Flutter (R16).

## 9. Soft delete — pattern obligatoire partout (R12)

```sql
-- jamais ceci :
DELETE FROM services WHERE id = '...';

-- toujours ceci :
UPDATE services SET deleted_at = now() WHERE id = '...';

-- et chaque SELECT applicatif filtre explicitement :
SELECT * FROM services WHERE salon_id = $1 AND deleted_at IS NULL;
```

Toute policy RLS de lecture sur une table avec `deleted_at` doit inclure `AND deleted_at IS NULL`, sauf pour les écrans d'audit/historique Owner qui peuvent explicitement vouloir voir les enregistrements soft-deleted.

## 10. Checklist avant de merger une migration

1. Table créée avec `salon_id` (sauf `salons`) + `deleted_at`.
2. `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` exécuté.
3. Au moins une policy `SELECT` écrite et testée pour chaque rôle concerné.
4. Aucune policy `USING (true)` sur une table contenant des données financières ou personnelles.
5. Index sur `salon_id` créé.
6. Si colonne sensible ajoutée à `users` : mise à jour de `protect_user_columns()`.
7. Si nouvelle table d'écriture client : vérifier qu'aucune logique métier critique (paiement, remboursement) n'est laissée à la portée d'une policy `INSERT`/`UPDATE` directe — ces flux passent par Edge Function.
