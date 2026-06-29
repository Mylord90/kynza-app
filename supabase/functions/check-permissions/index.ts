// supabase/functions/check-permissions/index.ts
// Batch permission evaluation — used by screens that need many flags at
// once (permission_audit_screen, user_permissions_screen showing a whole
// user's effective permission matrix) where one RPC per flag would mean
// dozens of round trips. Single-flag inline checks (PermissionGuard) call
// check_permission() directly via supabase.rpc() instead — see
// lib/core/permissions/permission_service.dart.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

interface PermissionQuery {
  feature: string;
  action: string;
  resource?: string;
  userId?: string;
}

const MAX_PERMISSIONS_PER_REQUEST = 50;

function permissionKey(userId: string, p: PermissionQuery): string {
  const suffix = p.resource ? `.${p.resource}` : "";
  return `${userId}:${p.feature}.${p.action}${suffix}`;
}

// deno-lint-ignore no-explicit-any
async function resolvePermission(admin: any, salonId: string, userId: string, p: PermissionQuery) {
  const { data, error } = await admin.rpc("check_permission", {
    p_user_id: userId,
    p_salon_id: salonId,
    p_feature: p.feature,
    p_action: p.action,
    p_resource: p.resource ?? "",
  });
  // check_permission() raises for an unauthorized cross-user check —
  // surface that as "false" rather than failing the whole batch.
  return error ? false : data === true;
}

Deno.serve(async (req: Request) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    const admin = createServiceRoleClient();

    if (!(await checkRateLimit(admin, `check-permissions:${caller.id}`, 30, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }
    if (!caller.salon_id) {
      return jsonResponse({ error: "no_salon" }, 400);
    }

    const body = await req.json();
    const permissions = body.permissions as PermissionQuery[] | undefined;
    if (!Array.isArray(permissions) || permissions.length === 0) {
      return jsonResponse({ error: "invalid_permissions" }, 400);
    }
    if (permissions.length > MAX_PERMISSIONS_PER_REQUEST) {
      return jsonResponse({ error: "too_many_permissions" }, 400);
    }

    // The admin client bypasses check_permission()'s own self-or-owner
    // guard (it runs as service_role, not "authenticated") — re-enforce
    // it here so a staff/client caller can't probe another user's
    // permissions just because this function holds the service key.
    const canCheckOthers = caller.role === "owner" || caller.role === "manager";

    const results: Record<string, boolean> = {};
    for (const p of permissions) {
      if (!p.feature || !p.action) continue;
      const targetUserId = p.userId ?? caller.id;
      const key = permissionKey(targetUserId, p);

      results[key] = targetUserId !== caller.id && !canCheckOthers
        ? false
        : await resolvePermission(admin, caller.salon_id, targetUserId, p);
    }

    return jsonResponse({ results }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "check_permissions_failed", message }, 500);
  }
});