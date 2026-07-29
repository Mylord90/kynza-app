// supabase/qa/010_create_conversation.mjs
// QA for create-conversation's reopening machine (DEC-009/DEC-024) and its
// identity predicate. Runs the exact SQL statements the Edge Function issues
// (as service_role) against the linked project, inside one outer
// BEGIN...ROLLBACK, one SAVEPOINT per test so a failure never aborts the run
// and nothing is ever committed. Requires PGHOST/PGPORT/PGUSER/PGPASSWORD
// (short-lived credentials from `supabase db dump --linked --dry-run`).
import { randomUUID } from "node:crypto";
import pg from "pg";

const { Client } = pg;
const client = new Client({ ssl: { rejectUnauthorized: false } });

let passed = 0;
let failed = 0;

function report(name, ok, detail) {
  if (ok) passed++;
  else failed++;
  console.log(`[${ok ? "PASS" : "FAIL"}] ${name} — ${detail}`);
}

async function withSavepoint(name, fn) {
  // `SET ROLE authenticated`/`service_role` inside fn() is undone by this
  // ROLLBACK TO SAVEPOINT automatically (role is a transactional GUC) —
  // reverting back to whatever role was active when the savepoint was
  // taken, i.e. `postgres` (set once, before any savepoint exists).
  await client.query(`SAVEPOINT ${name}`);
  try {
    return await fn();
  } finally {
    await client.query(`ROLLBACK TO SAVEPOINT ${name}`);
  }
}

async function makeTenant({ bookingStatus = "completed" } = {}) {
  const salonId = randomUUID();
  const ownerId = randomUUID();
  const clientId = randomUUID();
  const staffProfileId = randomUUID();
  const serviceId = randomUUID();
  const bookingId = randomUUID();

  // owner_id has no FK on salons itself, but two AFTER INSERT triggers fire
  // synchronously on the salons insert: init_owner_journey() (needs a real
  // users row, NOT NULL owner_id downstream) and auto_document_templates()
  // -> create_default_document_templates(), which raises "forbidden" unless
  // has_role(auth.uid(), 'owner', p_salon_id) is true at that exact moment
  // — so the owner fixture must already carry this salon's id and the
  // simulated JWT claims must already point at the owner before the salon
  // row is inserted.
  await client.query(
    `INSERT INTO public.users (id, role, salon_id, full_name, email) VALUES ($1,'owner',$2,'QA Owner',$3)`,
    [ownerId, salonId, `qa+${ownerId}@example.com`],
  );
  await client.query(
    `SELECT set_config('request.jwt.claims', $1, true)`,
    [JSON.stringify({ sub: ownerId, role: "service_role" })],
  );
  await client.query(
    `INSERT INTO public.salons (id, name, owner_id, plan, plan_status) VALUES ($1,'QA Salon',$2,'pro','active')`,
    [salonId, ownerId],
  );
  await client.query(
    `INSERT INTO public.users (id, role, full_name, email) VALUES ($1,'client','QA Client',$2)`,
    [clientId, `qa+${clientId}@example.com`],
  );
  await client.query(
    `INSERT INTO public.staff_profiles (id, salon_id, role, display_name, is_active) VALUES ($1,$2,'staff','QA Staff',true)`,
    [staffProfileId, salonId],
  );
  await client.query(
    `INSERT INTO public.services (id, salon_id, name, category, duration_min, price_bif) VALUES ($1,$2,'QA Service','hair',30,10000)`,
    [serviceId, salonId],
  );
  await client.query(
    `INSERT INTO public.bookings
       (id, salon_id, client_id, practitioner_id, service_id, status, start_time, end_time, buffer_end_time, amount_bif)
     VALUES ($1,$2,$3,$4,$5,$6, NOW() + interval '1 day', NOW() + interval '1 day 30 minutes',
             NOW() + interval '1 day 30 minutes', 10000)`,
    [bookingId, salonId, clientId, staffProfileId, serviceId, bookingStatus],
  );

  return { salonId, clientId, staffProfileId, serviceId, bookingId };
}

// Meta-test (blocking): proves the simulated authenticated context is real
// before any test trusts it — otherwise every RLS-dependent test would run
// under the connected superuser-ish role instead of a real `authenticated`
// caller, and would pass for the wrong reason.
async function metaTestAuthContext() {
  return withSavepoint("meta_test", async () => {
    const uid = randomUUID();
    await client.query("SET ROLE authenticated");
    await client.query(
      `SELECT set_config('request.jwt.claims', $1, true)`,
      [JSON.stringify({ sub: uid, role: "authenticated" })],
    );
    const roleRes = await client.query("SELECT auth.role() AS role");
    const uidRes = await client.query("SELECT auth.uid() AS uid");
    return {
      roleOk: roleRes.rows[0].role === "authenticated",
      uidOk: uidRes.rows[0].uid === uid,
      role: roleRes.rows[0].role,
      uid: uidRes.rows[0].uid,
      expectedUid: uid,
    };
  });
}

// RLS non-regression: no INSERT policy exists on conversations (Migration 1
// comment: "creation only via the future create-conversation Edge Function,
// service_role") — a direct authenticated INSERT must be rejected, 42501.
async function testRlsNoInsertPolicy() {
  return withSavepoint("t_rls_insert", async () => {
    const { salonId, clientId } = await makeTenant();
    await client.query("SET ROLE authenticated");
    await client.query(
      `SELECT set_config('request.jwt.claims', $1, true)`,
      [JSON.stringify({ sub: clientId, role: "authenticated" })],
    );
    let sqlstate = null;
    try {
      await client.query(
        `INSERT INTO public.conversations (salon_id, type, client_id) VALUES ($1,'client_salon',$2)`,
        [salonId, clientId],
      );
    } catch (e) {
      sqlstate = e.code;
    }
    return { sqlstate };
  });
}

// Test A: reopening resets client_deleted_at/client_hidden_at only. The
// salon_* columns are NOT protected by any trigger against this exact write
// (protect_conversation_columns lets is_system through on Categories D/D')
// — the only guard is the Edge Function's own SET clause. This test is that
// guard's sole regression net.
async function testReopenPreservesSalonSide() {
  return withSavepoint("t_test_a", async () => {
    const { salonId, clientId } = await makeTenant();
    const conversationId = randomUUID();
    await client.query(
      `INSERT INTO public.conversations
         (id, salon_id, type, client_id, salon_pinned, salon_archived, salon_hidden_at, salon_deleted_at,
          client_deleted_at, client_hidden_at)
       VALUES ($1,$2,'client_salon',$3, true, true, NOW(), NOW(), NOW(), NOW())`,
      [conversationId, salonId, clientId],
    );

    await client.query("SET ROLE service_role");
    const updateRes = await client.query(
      `UPDATE public.conversations
         SET client_deleted_at = NULL, client_hidden_at = NULL
       WHERE salon_id = $1 AND client_id = $2 AND type = 'client_salon' AND deleted_at IS NULL
       RETURNING id`,
      [salonId, clientId],
    );

    const after = await client.query(
      `SELECT salon_pinned, salon_archived, salon_hidden_at, salon_deleted_at, client_deleted_at, client_hidden_at
       FROM public.conversations WHERE id = $1`,
      [conversationId],
    );

    return { rowCount: updateRes.rowCount, after: after.rows[0] };
  });
}

// Test B: a globally-erased conversation (deleted_at IS NOT NULL) must never
// be reopened — the AND deleted_at IS NULL guard excludes it, 0 rows, no
// column touched (DEC-024).
async function testNoResurrectionOfErasedConversation() {
  return withSavepoint("t_test_b", async () => {
    const { salonId, clientId } = await makeTenant();
    const conversationId = randomUUID();
    await client.query(
      `INSERT INTO public.conversations (id, salon_id, type, client_id, deleted_at)
       VALUES ($1,$2,'client_salon',$3, NOW())`,
      [conversationId, salonId, clientId],
    );

    const before = await client.query(`SELECT * FROM public.conversations WHERE id = $1`, [conversationId]);

    await client.query("SET ROLE service_role");
    const updateRes = await client.query(
      `UPDATE public.conversations
         SET client_deleted_at = NULL, client_hidden_at = NULL
       WHERE salon_id = $1 AND client_id = $2 AND type = 'client_salon' AND deleted_at IS NULL
       RETURNING id`,
      [salonId, clientId],
    );

    const after = await client.query(`SELECT * FROM public.conversations WHERE id = $1`, [conversationId]);

    return {
      rowCount: updateRes.rowCount,
      unchanged: JSON.stringify(before.rows[0]) === JSON.stringify(after.rows[0]),
    };
  });
}

// DEC-016 separation, positive: the eligibility query create-conversation
// runs (step 12 of index.ts) carries no status filter — a cancelled/no_show
// booking must still satisfy it.
async function testEligibilityIgnoresBookingStatus() {
  return withSavepoint("t_dec016", async () => {
    const { salonId, clientId, staffProfileId, bookingId } = await makeTenant({ bookingStatus: "cancelled" });
    const res = await client.query(
      `SELECT id FROM public.bookings
       WHERE id = $1 AND client_id = $2 AND practitioner_id = $3 AND salon_id = $4 AND deleted_at IS NULL`,
      [bookingId, clientId, staffProfileId, salonId],
    );
    return { found: res.rowCount === 1 };
  });
}

// Identity predicate, cross-type: same client + same salon holds both a
// client_salon and a client_staff thread. Reopening the client_salon pair
// must touch only that row — this is why `type` is mandatory in the WHERE,
// not cosmetic (salon_id/client_id alone would match both rows).
async function testIdentityDoesNotCrossTypes() {
  return withSavepoint("t_identity", async () => {
    const { salonId, clientId, staffProfileId, bookingId } = await makeTenant();
    const salonConvId = randomUUID();
    const staffConvId = randomUUID();

    await client.query(
      `INSERT INTO public.conversations (id, salon_id, type, client_id, client_deleted_at, client_hidden_at)
       VALUES ($1,$2,'client_salon',$3, NOW(), NOW())`,
      [salonConvId, salonId, clientId],
    );
    await client.query(
      `INSERT INTO public.conversations
         (id, salon_id, type, client_id, staff_id, related_booking_id, client_deleted_at, client_hidden_at)
       VALUES ($1,$2,'client_staff',$3,$4,$5, NOW(), NOW())`,
      [staffConvId, salonId, clientId, staffProfileId, bookingId],
    );

    await client.query("SET ROLE service_role");
    const updateRes = await client.query(
      `UPDATE public.conversations
         SET client_deleted_at = NULL, client_hidden_at = NULL
       WHERE salon_id = $1 AND client_id = $2 AND type = 'client_salon' AND deleted_at IS NULL
       RETURNING id`,
      [salonId, clientId],
    );

    const staffConvAfter = await client.query(
      `SELECT client_deleted_at, client_hidden_at FROM public.conversations WHERE id = $1`,
      [staffConvId],
    );

    return {
      rowCount: updateRes.rowCount,
      updatedId: updateRes.rows[0]?.id,
      salonConvId,
      staffConvUntouched: staffConvAfter.rows[0].client_deleted_at !== null
        && staffConvAfter.rows[0].client_hidden_at !== null,
    };
  });
}

async function main() {
  await client.connect();
  await client.query("BEGIN");
  // cli_login_postgres (the ephemeral CLI role) is a member of `postgres`
  // but does not inherit it automatically — every table in this domain is
  // owned by `postgres` and has no direct grant to cli_login_postgres, so
  // this SET ROLE stays active for the rest of the transaction (each
  // SAVEPOINT below is taken after this point, so ROLLBACK TO SAVEPOINT
  // reverts any per-test SET ROLE authenticated/service_role back to this).
  await client.query("SET ROLE postgres");
  // Fixture users need arbitrary ids without a matching auth.users row —
  // same technique already used and rolled back cleanly for Migration 2's
  // production test run. users_salon_id_fkey is also dropped: the owner
  // fixture must already carry the new salon's id at INSERT time (below) so
  // that auto_document_templates()'s has_role() check passes synchronously
  // when the salon row is inserted — the salon row does not exist yet at
  // that point, so the plain FK cannot be satisfied without relaxing it.
  await client.query("ALTER TABLE public.users DROP CONSTRAINT users_id_fkey");
  await client.query("ALTER TABLE public.users DROP CONSTRAINT users_salon_id_fkey");

  const before = await client.query("SELECT count(*)::int AS n FROM public.conversations");

  const meta = await metaTestAuthContext();
  const metaOk = meta.roleOk && meta.uidOk;
  report(
    "META auth.role()/auth.uid() simulation",
    metaOk,
    `role=${meta.role} uidOk=${meta.uidOk} (expected ${meta.expectedUid}, got ${meta.uid})`,
  );
  if (!metaOk) {
    console.error("Meta-test failed — aborting, every subsequent test would run under a false context.");
    await client.query("ROLLBACK");
    await client.end();
    process.exit(1);
  }

  const rls = await testRlsNoInsertPolicy();
  report(
    "RLS non-regression: authenticated direct INSERT",
    rls.sqlstate === "42501",
    `sqlstate=${rls.sqlstate ?? "none (no error thrown)"}`,
  );

  const a = await testReopenPreservesSalonSide();
  const aOk = a.rowCount === 1
    && a.after.salon_pinned === true
    && a.after.salon_archived === true
    && a.after.salon_hidden_at !== null
    && a.after.salon_deleted_at !== null
    && a.after.client_deleted_at === null
    && a.after.client_hidden_at === null;
  report(
    "Test A: reopen resets client_* only, salon_* untouched",
    aOk,
    `rowCount=${a.rowCount} salon_pinned=${a.after.salon_pinned} salon_archived=${a.after.salon_archived} `
      + `salon_hidden_at=${a.after.salon_hidden_at !== null} salon_deleted_at=${a.after.salon_deleted_at !== null} `
      + `client_deleted_at=${a.after.client_deleted_at} client_hidden_at=${a.after.client_hidden_at}`,
  );

  const b = await testNoResurrectionOfErasedConversation();
  report(
    "Test B: erased conversation (deleted_at NOT NULL) is never reopened",
    b.rowCount === 0 && b.unchanged,
    `rowCount=${b.rowCount} unchanged=${b.unchanged}`,
  );

  const dec016 = await testEligibilityIgnoresBookingStatus();
  report(
    "DEC-016 positive: eligibility ignores booking status (cancelled)",
    dec016.found,
    `found=${dec016.found}`,
  );

  const idn = await testIdentityDoesNotCrossTypes();
  const idnOk = idn.rowCount === 1 && idn.updatedId === idn.salonConvId && idn.staffConvUntouched;
  report(
    "Identity predicate: reopening client_salon never touches client_staff row",
    idnOk,
    `rowCount=${idn.rowCount} updatedId=${idn.updatedId === idn.salonConvId ? "salonConvId (correct)" : "WRONG ROW"} `
      + `staffConvUntouched=${idn.staffConvUntouched}`,
  );

  await client.query("ROLLBACK");
  // ROLLBACK also reverts SET ROLE postgres (role is transactional) — the
  // session is back to cli_login_postgres, which has no direct grant on
  // this table, so this final proof-of-cleanup read needs its own role set.
  await client.query("SET ROLE postgres");
  const after = await client.query("SELECT count(*)::int AS n FROM public.conversations");
  await client.query("RESET ROLE");
  console.log(
    `Cleanup check — conversations count before=${before.rows[0].n} after=${after.rows[0].n} `
      + `(${before.rows[0].n === after.rows[0].n ? "OK" : "MISMATCH"})`,
  );

  console.log(`\n${passed} passed, ${failed} failed.`);
  await client.end();
  if (failed > 0) process.exit(1);
}

main().catch(async (e) => {
  console.error("QA script crashed:", e);
  try {
    await client.query("ROLLBACK");
    await client.end();
  } catch (_e) {
    // ignore — connection likely already dead
  }
  process.exit(1);
});
