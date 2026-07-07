// supabase/functions/accept-invitation/index.ts
// A new or existing staff member taps the invitation deep link and lands
// here once authenticated — links their auth account to the staff_profiles
// row the Owner created (staff_invite_screen.dart), which is the only way
// a staff_profiles row ever gets a user_id (no self-serve staff signup).
import { logActivity } from "../_shared/audit.ts";
import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const bodyGuard = await readBodyGuarded(req);
  if (!bodyGuard.ok) return bodyGuard.response;

  try {
    const caller = await getAuthenticatedUser(req);
    const supabase = createServiceRoleClient();
    if (!(await checkRateLimit(supabase, `accept-invitation:${caller.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = JSON.parse(bodyGuard.text);
    const invitationToken = body.invitation_token ?? body.invitationToken;

    if (!invitationToken) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }

    // users.salon_id/role is single-valued — accepting would silently
    // overwrite an existing Owner's link to their own salon (R02-style
    // defense-in-depth: never let one mutation clobber unrelated state).
    if (caller.role === "owner") {
      return jsonResponse(
        { error: "already_owner", message: "Vous êtes déjà propriétaire d'un salon." },
        400,
      );
    }

    const { data: staffProfile, error: lookupError } = await supabase
      .from("staff_profiles")
      .select("id, salon_id, role, display_name, invited_by, invitation_accepted_at, deleted_at")
      .eq("invitation_token", invitationToken)
      .maybeSingle();

    if (lookupError) throw lookupError;
    if (!staffProfile || staffProfile.deleted_at || staffProfile.invitation_accepted_at) {
      return jsonResponse(
        { error: "invalid_invitation", message: "Invitation invalide ou déjà utilisée." },
        400,
      );
    }

    // Conditional UPDATE re-checks invitation_accepted_at IS NULL atomically —
    // .select().maybeSingle() returns null if a concurrent request already
    // consumed this token between the lookup above and here.
    const { data: updated, error: updateStaffError } = await supabase
      .from("staff_profiles")
      .update({ user_id: caller.id, invitation_accepted_at: new Date().toISOString() })
      .eq("invitation_token", invitationToken)
      .is("invitation_accepted_at", null)
      .select("salon_id, role")
      .maybeSingle();

    if (updateStaffError) throw updateStaffError;
    if (!updated) {
      return jsonResponse(
        { error: "invalid_invitation", message: "Invitation invalide ou déjà utilisée." },
        400,
      );
    }

    const { error: updateUserError } = await supabase
      .from("users")
      .update({ salon_id: updated.salon_id, role: updated.role })
      .eq("id", caller.id);
    if (updateUserError) throw updateUserError;

    await logActivity(supabase, req, {
      salonId: updated.salon_id,
      userId: caller.id,
      typeAction: "staff_invitation_accepted",
      newValues: { staffProfileId: staffProfile.id },
    });

    // Best-effort: notify whoever sent the invitation that it was accepted.
    if (staffProfile.invited_by) {
      supabase.functions.invoke("send-notification", {
        body: {
          userId: staffProfile.invited_by,
          salonId: updated.salon_id,
          event: "staff_joined",
          data: { staff_name: staffProfile.display_name ?? "" },
        },
      }).catch(() => {});
    }

    return jsonResponse(
      { success: true, salon_id: updated.salon_id, role: updated.role },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "accept_invitation_failed", message }, 500);
  }
});
