// supabase/functions/create-conversation/index.ts
// Opens (or reopens) a client_salon/client_staff conversation. Eligibility
// is booking-history existence only (DEC-016 gates message send, never
// conversation open — ADR_MESSAGING_FOUNDATION.md, "Separation DEC-016 /
// eligibilite create-conversation"). Reopening machine (DEC-024,
// ADR_MESSAGING_FOUNDATION.md:2133-2214): a 23505 unique-index conflict is
// resolved by one atomic UPDATE carrying the exact identity predicate that
// caused the conflict, never a separate SELECT-then-UPDATE.
import { logActivity } from "../_shared/audit.ts";
import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type ConversationType = "client_salon" | "client_staff";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const bodyGuard = await readBodyGuarded(req);
  if (!bodyGuard.ok) return bodyGuard.response;

  try {
    const user = await getAuthenticatedUser(req);
    const clientId = user.id;
    const admin = createServiceRoleClient();

    if (!(await checkRateLimit(admin, `create-conversation:${clientId}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = JSON.parse(bodyGuard.text);
    const type: string | undefined = body.type;
    const salonId: string | undefined = body.salon_id;
    const staffId: string | undefined = body.staff_id;
    const relatedBookingId: string | undefined = body.related_booking_id;

    if (!salonId) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }
    if (type !== "client_salon" && type !== "client_staff") {
      return jsonResponse({ error: "invalid_type" }, 422);
    }
    if (type === "client_staff" && (!staffId || !relatedBookingId)) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }

    if (!UUID_RE.test(salonId)) {
      return jsonResponse({ error: "invalid_type" }, 422);
    }
    if (type === "client_staff" && (!UUID_RE.test(staffId!) || !UUID_RE.test(relatedBookingId!))) {
      return jsonResponse({ error: "invalid_type" }, 422);
    }

    const conversationType = type as ConversationType;

    // Eligibility (DEC-016 separation: existence only, no status filter —
    // ADR_MESSAGING_FOUNDATION.md:1055-1061). client_salon: any booking, any
    // practitioner. client_staff: the cited quadruplet exactly.
    let eligibilityQuery = admin
      .from("bookings")
      .select("id")
      .eq("client_id", clientId)
      .eq("salon_id", salonId)
      .is("deleted_at", null);
    if (conversationType === "client_staff") {
      eligibilityQuery = eligibilityQuery
        .eq("id", relatedBookingId!)
        .eq("practitioner_id", staffId!);
    }
    const { data: eligibleBooking, error: eligibilityError } = await eligibilityQuery.maybeSingle();
    if (eligibilityError) throw eligibilityError;
    if (!eligibleBooking) {
      console.error(
        `create-conversation rejected: no_qualifying_booking client_id=${clientId} salon_id=${salonId}${
          conversationType === "client_staff" ? ` staff_id=${staffId}` : ""
        }`,
      );
      return jsonResponse({ error: "not_eligible" }, 403);
    }

    // Salon-active gate duplicated here on purpose: trg_check_conversation_salon_active
    // (invariant 7/DEC-006) is BEFORE INSERT only — the reopening UPDATE path
    // below has no SQL-level protection against a since-soft-deleted salon.
    // The eligibility query above already proves salonId is a real row (FK
    // on bookings.salon_id), so a missing row here is itself an invariant
    // violation, not a plain not_eligible — distinct from unexpected_state,
    // which DEC-024 reserves for its own reopening-diagnostic branches.
    const { data: salonRow, error: salonError } = await admin
      .from("salons")
      .select("deleted_at")
      .eq("id", salonId)
      .maybeSingle();
    if (salonError) throw salonError;
    if (!salonRow) {
      console.error(`create-conversation: salon_not_found_invariant_violation — salon_id=${salonId} missing despite passing eligibility`);
      return jsonResponse({ error: "salon_not_found_invariant_violation" }, 500);
    }
    if (salonRow.deleted_at) {
      console.error(`create-conversation rejected: salon_soft_deleted salon_id=${salonId}`);
      return jsonResponse({ error: "not_eligible" }, 403);
    }

    const { data: inserted, error: insertError } = await admin
      .from("conversations")
      .insert({
        salon_id: salonId,
        type: conversationType,
        client_id: clientId,
        staff_id: conversationType === "client_staff" ? staffId : null,
        related_booking_id: conversationType === "client_staff" ? relatedBookingId : null,
      })
      .select("id, created_at")
      .single();

    if (!insertError) {
      await logActivity(admin, req, {
        salonId,
        userId: clientId,
        typeAction: "conversation_created",
        newValues: { conversationId: inserted.id },
      });
      return jsonResponse(
        { conversationId: inserted.id, created_at: inserted.created_at, event: "conversation_created" },
        200,
      );
    }

    if (insertError.code !== "23505") {
      throw insertError;
    }

    // Reopening (DEC-009/DEC-024). Identity predicate shared verbatim
    // between the UPDATE below and the diagnostic SELECT that follows it —
    // never reconstructed independently (ADR_MESSAGING_FOUNDATION.md,
    // "regle d'identite invariante"). type is part of the predicate on both
    // branches: a client can hold a client_salon and a client_staff thread
    // against the same salon_id/client_id at once, so salon_id/client_id
    // alone would not identify a single row on the client_salon branch.
    const identityColumn = conversationType === "client_staff" ? "staff_id" : "salon_id";
    const identityValue = conversationType === "client_staff" ? staffId! : salonId;

    const { data: reopened, error: reopenError } = await admin
      .from("conversations")
      .update({ client_deleted_at: null, client_hidden_at: null })
      .eq(identityColumn, identityValue)
      .eq("client_id", clientId)
      .eq("type", conversationType)
      .is("deleted_at", null)
      .select("id")
      .maybeSingle();
    if (reopenError) throw reopenError;

    if (reopened) {
      await logActivity(admin, req, {
        salonId,
        userId: clientId,
        typeAction: "conversation_reopened",
        newValues: { conversationId: reopened.id },
      });
      return jsonResponse({ conversationId: reopened.id, event: "conversation_reopened" }, 200);
    }

    const { data: diagRow, error: diagError } = await admin
      .from("conversations")
      .select("id, deleted_at")
      .eq(identityColumn, identityValue)
      .eq("client_id", clientId)
      .eq("type", conversationType)
      .maybeSingle();
    if (diagError) throw diagError;

    if (diagRow && diagRow.deleted_at) {
      console.error(`create-conversation: conversation_erased conversation_id=${diagRow.id}`);
      return jsonResponse({ error: "conversation_erased" }, 403);
    }
    if (diagRow && !diagRow.deleted_at) {
      console.error(
        `create-conversation: unexpected_state — identity predicate mismatch, UPDATE should have matched conversation_id=${diagRow.id}`,
      );
      return jsonResponse({ error: "unexpected_state" }, 500);
    }
    console.error(
      `create-conversation: unexpected_state — 23505 conflict but no row found matching identity predicate (type=${conversationType})`,
    );
    return jsonResponse({ error: "unexpected_state" }, 500);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    console.error(`create-conversation failed: ${message}`);
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_conversation_failed" }, 500);
  }
});
