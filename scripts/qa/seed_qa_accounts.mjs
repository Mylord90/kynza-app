// One-off seed script for the kynza-dr-scratch Supabase project (ref
// hzjmyeptytvjmzbnsmwp), run manually via `node seed_qa_accounts.mjs`.
// Creates 2 fully independent tenants (Salon A / Salon B), each with an
// owner, a staff/practitioner, a client, and one bookable service — the
// "QA Supabase test accounts" needed for Phase 9's live-network tests
// (RLS cross-tenant, concurrent-booking stress, ProxiPay replay, E2E).
// Idempotent: re-running with the same emails updates existing users
// instead of failing on conflict.
//
// This project is a non-production scratch project explicitly kept for
// this purpose (see reference_dr_scratch_supabase.md memory) — never run
// this script against the real KYNZA production project ref.

const PROJECT_REF = "hzjmyeptytvjmzbnsmwp";
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const SERVICE_ROLE_KEY = process.env.KYNZA_SCRATCH_SERVICE_ROLE_KEY;
const ANON_KEY = process.env.KYNZA_SCRATCH_ANON_KEY;

if (!SERVICE_ROLE_KEY || !ANON_KEY) {
  console.error(
    "Set KYNZA_SCRATCH_SERVICE_ROLE_KEY and KYNZA_SCRATCH_ANON_KEY env vars first.",
  );
  process.exit(1);
}

const adminHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
  "Content-Type": "application/json",
};

async function req(method, path, body, headers = adminHeaders) {
  const res = await fetch(`${SUPABASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const json = text ? JSON.parse(text) : null;
  if (!res.ok) {
    throw new Error(`${method} ${path} -> ${res.status}: ${text}`);
  }
  return json;
}

async function findAuthUserByEmail(email) {
  const result = await req(
    "GET",
    `/auth/v1/admin/users?page=1&per_page=200`,
  );
  return (result.users ?? []).find((u) => u.email === email) ?? null;
}

async function createOrGetAuthUser(email, password, fullName) {
  const existing = await findAuthUserByEmail(email);
  if (existing) return existing;
  return req("POST", "/auth/v1/admin/users", {
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
}

async function upsertSalon(name, ownerId) {
  const existing = await req(
    "GET",
    `/rest/v1/salons?name=eq.${encodeURIComponent(name)}&select=id`,
  );
  if (existing.length > 0) return existing[0].id;
  const created = await req(
    "POST",
    "/rest/v1/salons",
    { name, owner_id: ownerId, plan: "pro", plan_status: "active" },
    { ...adminHeaders, Prefer: "return=representation" },
  );
  return created[0].id;
}

async function updateUserRow(userId, patch) {
  await req(
    "PATCH",
    `/rest/v1/users?id=eq.${userId}`,
    patch,
    { ...adminHeaders, Prefer: "return=minimal" },
  );
}

async function upsertStaffProfile(userId, salonId, role, displayName) {
  const existing = await req(
    "GET",
    `/rest/v1/staff_profiles?user_id=eq.${userId}&select=id`,
  );
  if (existing.length > 0) return existing[0].id;
  const created = await req(
    "POST",
    "/rest/v1/staff_profiles",
    {
      user_id: userId,
      salon_id: salonId,
      role: role === "owner" ? "manager" : role, // staff_profiles.role only allows manager|staff
      display_name: displayName,
      is_active: true,
    },
    { ...adminHeaders, Prefer: "return=representation" },
  );
  return created[0].id;
}

async function upsertService(salonId, name) {
  const existing = await req(
    "GET",
    `/rest/v1/services?salon_id=eq.${salonId}&name=eq.${encodeURIComponent(name)}&select=id`,
  );
  if (existing.length > 0) return existing[0].id;
  const created = await req(
    "POST",
    "/rest/v1/services",
    {
      salon_id: salonId,
      name,
      category: "hair",
      duration_min: 30,
      price_bif: 15000,
      is_active: true,
    },
    { ...adminHeaders, Prefer: "return=representation" },
  );
  return created[0].id;
}

async function signIn(email, password) {
  const result = await req(
    "POST",
    "/auth/v1/token?grant_type=password",
    { email, password },
    { apikey: ANON_KEY, "Content-Type": "application/json" },
  );
  return result.access_token;
}

async function buildTenant(label, password) {
  const ownerEmail = `kynza.qa.${label}.owner@example.com`;
  const staffEmail = `kynza.qa.${label}.staff@example.com`;
  const clientEmail = `kynza.qa.${label}.client@example.com`;

  const ownerAuth = await createOrGetAuthUser(ownerEmail, password, `Owner ${label.toUpperCase()}`);
  const staffAuth = await createOrGetAuthUser(staffEmail, password, `Staff ${label.toUpperCase()}`);
  const clientAuth = await createOrGetAuthUser(clientEmail, password, `Client ${label.toUpperCase()}`);

  const salonId = await upsertSalon(`QA Salon ${label.toUpperCase()}`, ownerAuth.id);

  await updateUserRow(ownerAuth.id, { role: "owner", salon_id: salonId, profile_completed: true });
  await updateUserRow(staffAuth.id, { role: "staff", salon_id: salonId, profile_completed: true });
  await updateUserRow(clientAuth.id, { profile_completed: true });

  const staffProfileId = await upsertStaffProfile(staffAuth.id, salonId, "staff", `Staff ${label.toUpperCase()}`);
  const serviceId = await upsertService(salonId, `QA Service ${label.toUpperCase()}`);

  const ownerToken = await signIn(ownerEmail, password);
  const staffToken = await signIn(staffEmail, password);
  const clientToken = await signIn(clientEmail, password);

  return {
    salonId,
    staffProfileId,
    serviceId,
    owner: { id: ownerAuth.id, email: ownerEmail, token: ownerToken },
    staff: { id: staffAuth.id, email: staffEmail, token: staffToken },
    client: { id: clientAuth.id, email: clientEmail, token: clientToken },
  };
}

const PASSWORD = process.env.KYNZA_QA_PASSWORD ?? "Kynza-QA-Test-2026!";

const [tenantA, tenantB] = await Promise.all([
  buildTenant("a", PASSWORD),
  buildTenant("b", PASSWORD),
]);

const output = {
  projectRef: PROJECT_REF,
  supabaseUrl: SUPABASE_URL,
  anonKey: ANON_KEY,
  password: PASSWORD,
  tenantA,
  tenantB,
};

console.log(JSON.stringify(output, null, 2));
