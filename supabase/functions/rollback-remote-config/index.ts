// supabase/functions/rollback-remote-config/index.ts
// Phase 4 (Backend Enterprise Completion) — one-click revert to a prior
// remote_config_versions row. Restoring writes a NEW version (rather than
// deleting later ones) so the full history stays intact and is itself
// re-revertible — an append-only rollback, not a destructive one.
//
// Access control: gated to is_system_admin (P2-9 fix, Master Plan CP2 —
// see update-remote-config/index.ts for the same change and its
// prerequisite).
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    if (!caller.is_system_admin) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `rollback-remote-config:${caller.id}`, 30, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = await req.json();
    const key = body.key as string | undefined;
    const targetVersion = body.version_number ?? body.versionNumber;
    if (!key || typeof targetVersion !== "number") {
      return jsonResponse({ error: "missing_fields" }, 400);
    }

    const { data: entry, error: entryError } = await admin
      .from("remote_config_entries")
      .select("id, value_json")
      .eq("key", key)
      .is("deleted_at", null)
      .maybeSingle();
    if (entryError) throw entryError;
    if (!entry) return jsonResponse({ error: "unknown_key" }, 404);

    const { data: targetRow, error: targetError } = await admin
      .from("remote_config_versions")
      .select("value_json")
      .eq("entry_id", entry.id)
      .eq("version_number", targetVersion)
      .maybeSingle();
    if (targetError) throw targetError;
    if (!targetRow) return jsonResponse({ error: "unknown_version" }, 404);

    const beforeJson = entry.value_json;
    const restoredValue = targetRow.value_json;

    const { error: updateError } = await admin
      .from("remote_config_entries")
      .update({ value_json: restoredValue, updated_by: caller.id })
      .eq("id", entry.id);
    if (updateError) throw updateError;

    const { data: lastVersion } = await admin
      .from("remote_config_versions")
      .select("version_number")
      .eq("entry_id", entry.id)
      .order("version_number", { ascending: false })
      .limit(1)
      .maybeSingle();
    const nextVersion = (lastVersion?.version_number ?? 0) + 1;

    await admin.from("remote_config_versions").insert({
      entry_id: entry.id,
      version_number: nextVersion,
      value_json: restoredValue,
      changed_by: caller.id,
      change_reason: `rollback_to_v${targetVersion}`,
    });

    await admin.from("remote_config_audit").insert({
      entry_id: entry.id,
      action: "rolled_back",
      actor_id: caller.id,
      before_json: beforeJson,
      after_json: restoredValue,
    });

    return jsonResponse(
      { success: true, key, value: restoredValue, version: nextVersion },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "rollback_remote_config_failed", message }, 500);
  }
});
