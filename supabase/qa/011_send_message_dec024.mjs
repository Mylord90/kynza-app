// supabase/qa/011_send_message_dec024.mjs
// QA for the DEC-024 extension to messages_participant_insert (residual #7,
// 20260729100000_messages_dec024_extension.sql). Exactly the 4 mandated
// scenarios — no more. Same proven methodology as 010_create_conversation.mjs:
// Node/pg, one outer BEGIN...ROLLBACK, one SAVEPOINT per test, ephemeral
// credentials from `supabase db dump --linked --dry-run`.
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

  // Same two AFTER INSERT triggers on salons as 010_create_conversation.mjs
  // (init_owner_journey, auto_document_templates) — owner fixture must carry
  // this salon's id and simulated JWT claims before the salon row exists.
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

// Direct INSERT as postgres (bypasses RLS, matches the fixture-writer role
// used throughout this QA suite) — conversations are created here as a given
// fact of the scenario, not as a proof of create-conversation's own behavior
// (already covered by 010_create_conversation.mjs).
async function makeConversation({ salonId, clientId, staffProfileId, bookingId, type, deletedAt = null }) {
  const conversationId = randomUUID();
  await client.query(
    `INSERT INTO public.conversations (id, salon_id, type, client_id, staff_id, related_booking_id, deleted_at)
     VALUES ($1,$2,$3,$4,$5,$6,$7)`,
    [
      conversationId,
      salonId,
      type,
      clientId,
      type === "client_staff" ? staffProfileId : null,
      type === "client_staff" ? bookingId : null,
      deletedAt,
    ],
  );
  return conversationId;
}

async function attemptSend({ conversationId, senderId }) {
  await client.query("SET ROLE authenticated");
  await client.query(
    `SELECT set_config('request.jwt.claims', $1, true)`,
    [JSON.stringify({ sub: senderId, role: "authenticated" })],
  );
  let sqlstate = null;
  let insertedId = null;
  try {
    const res = await client.query(
      `INSERT INTO public.messages (conversation_id, sender_id, client_message_id, kind, body)
       VALUES ($1,$2,$3,'text','QA test message') RETURNING id`,
      [conversationId, senderId, randomUUID()],
    );
    insertedId = res.rows[0]?.id ?? null;
  } catch (e) {
    sqlstate = e.code;
  }
  return { sqlstate, insertedId };
}

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

// Scenario 1 — conversation deleted_at IS NOT NULL -> refused (42501).
// client_salon on purpose: isolates the new DEC-024 clause from DEC-016,
// which only applies to client_staff.
async function testDeletedConversationRefused() {
  return withSavepoint("t1_deleted_at", async () => {
    const { salonId, clientId } = await makeTenant();
    const conversationId = await makeConversation({
      salonId, clientId, type: "client_salon", deletedAt: new Date().toISOString(),
    });
    const { sqlstate, insertedId } = await attemptSend({ conversationId, senderId: clientId });
    return { sqlstate, insertedId };
  });
}

// Scenario 2 — booking cancelled -> refused (42501). Non-regression: proves
// the new deleted_at clause did not disturb the pre-existing DEC-016 gate.
async function testCancelledBookingRefused() {
  return withSavepoint("t2_cancelled", async () => {
    const { salonId, clientId, staffProfileId, bookingId } = await makeTenant({ bookingStatus: "cancelled" });
    const conversationId = await makeConversation({
      salonId, clientId, staffProfileId, bookingId, type: "client_staff", deletedAt: null,
    });
    const { sqlstate, insertedId } = await attemptSend({ conversationId, senderId: clientId });
    return { sqlstate, insertedId };
  });
}

// Scenario 3 — booking completed -> accepted. Closes the coverage gap named
// in the prior analysis (no positive test had ever named "completed").
async function testCompletedBookingAccepted() {
  return withSavepoint("t3_completed", async () => {
    const { salonId, clientId, staffProfileId, bookingId } = await makeTenant({ bookingStatus: "completed" });
    const conversationId = await makeConversation({
      salonId, clientId, staffProfileId, bookingId, type: "client_staff", deletedAt: null,
    });
    const { sqlstate, insertedId } = await attemptSend({ conversationId, senderId: clientId });
    return { sqlstate, insertedId };
  });
}

// Scenario 4 — non-participant -> refused (42501). Base participant-check
// non-regression, independent of DEC-016/DEC-024.
async function testNonParticipantRefused() {
  return withSavepoint("t4_non_participant", async () => {
    const { salonId, clientId, staffProfileId, bookingId } = await makeTenant();
    const conversationId = await makeConversation({
      salonId, clientId, staffProfileId, bookingId, type: "client_staff", deletedAt: null,
    });
    const outsiderId = randomUUID();
    await client.query(
      `INSERT INTO public.users (id, role, full_name, email) VALUES ($1,'client','QA Outsider',$2)`,
      [outsiderId, `qa+${outsiderId}@example.com`],
    );
    const { sqlstate, insertedId } = await attemptSend({ conversationId, senderId: outsiderId });
    return { sqlstate, insertedId };
  });
}

async function main() {
  await client.connect();
  await client.query("BEGIN");
  await client.query("SET ROLE postgres");
  await client.query("ALTER TABLE public.users DROP CONSTRAINT users_id_fkey");
  await client.query("ALTER TABLE public.users DROP CONSTRAINT users_salon_id_fkey");

  const before = await client.query("SELECT count(*)::int AS n FROM public.messages");

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

  const t1 = await testDeletedConversationRefused();
  report(
    "1. conversation deleted_at IS NOT NULL -> refused",
    t1.sqlstate === "42501",
    `sqlstate=${t1.sqlstate ?? "none (no error thrown)"} insertedId=${t1.insertedId}`,
  );

  const t2 = await testCancelledBookingRefused();
  report(
    "2. booking cancelled -> refused (DEC-016 non-regression)",
    t2.sqlstate === "42501",
    `sqlstate=${t2.sqlstate ?? "none (no error thrown)"} insertedId=${t2.insertedId}`,
  );

  const t3 = await testCompletedBookingAccepted();
  report(
    "3. booking completed -> accepted",
    t3.sqlstate === null && t3.insertedId !== null,
    `sqlstate=${t3.sqlstate ?? "none"} insertedId=${t3.insertedId}`,
  );

  const t4 = await testNonParticipantRefused();
  report(
    "4. non-participant -> refused",
    t4.sqlstate === "42501",
    `sqlstate=${t4.sqlstate ?? "none (no error thrown)"} insertedId=${t4.insertedId}`,
  );

  await client.query("ROLLBACK");
  await client.query("SET ROLE postgres");
  const after = await client.query("SELECT count(*)::int AS n FROM public.messages");
  await client.query("RESET ROLE");
  console.log(
    `Cleanup check — messages count before=${before.rows[0].n} after=${after.rows[0].n} `
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
