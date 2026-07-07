// supabase/functions/update-remote-config/index.ts
// Phase 4 (Backend Enterprise Completion) — the only write path onto
// remote_config_entries. No table policy grants authenticated INSERT/UPDATE
// on that table (see 20260704110000_remote_config_engine.sql) — every write
// goes through this function's validation gate first.
//
// Access control: gated to is_system_admin (P2-9 fix, Master Plan CP2 —
// the SYSTEM_ADMIN scope from 20260704120000_observability_system_admin.sql
// is a hard prerequisite for this gate and must be applied first, or every
// caller is rejected).
import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

type ValueType = "string" | "number" | "boolean" | "object" | "array";

function typeMatches(value: unknown, valueType: ValueType): boolean {
  switch (valueType) {
    case "string":
      return typeof value === "string";
    case "number":
      return typeof value === "number" && Number.isFinite(value);
    case "boolean":
      return typeof value === "boolean";
    case "object":
      return typeof value === "object" && value !== null && !Array.isArray(value);
    case "array":
      return Array.isArray(value);
  }
}

// Per-category refinements beyond the base type check — a malformed value
// must never reach clients even if it happens to match the base JSON type.
// Phase 8 (Backend Enterprise Completion) extends this with the new
// categories it seeds, rather than introducing a second validation path.
const KNOWN_PAYMENT_METHODS = ["mobile_money", "proxipay", "cash"];

function categoryRefinementError(category: string, key: string, value: unknown): string | null {
  if (
    category === "prices" ||
    category === "quotas" ||
    category === "quota_thresholds" ||
    category === "rate_limits"
  ) {
    if (typeof value === "number" && value < 0) {
      return `${key}: must be >= 0 for category '${category}'`;
    }
  }
  if (category === "theming" && typeof value === "string") {
    if (!/^#[0-9A-Fa-f]{6}$/.test(value)) {
      return `${key}: theming string values must be a #RRGGBB hex color`;
    }
  }
  if (category === "working_hours_defaults" && typeof value === "string") {
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) {
      return `${key}: working_hours_defaults strings must be HH:MM (24h)`;
    }
  }
  if (category === "payment_method_availability" && Array.isArray(value)) {
    if (value.length === 0 || !value.every((v) => KNOWN_PAYMENT_METHODS.includes(v))) {
      return `${key}: must be a non-empty array of known payment methods (${KNOWN_PAYMENT_METHODS.join(", ")})`;
    }
  }
  return null;
}

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const bodyGuard = await readBodyGuarded(req);
  if (!bodyGuard.ok) return bodyGuard.response;

  try {
    const caller = await getAuthenticatedUser(req);
    if (!caller.is_system_admin) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `update-remote-config:${caller.id}`, 60, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = JSON.parse(bodyGuard.text);
    const key = body.key as string | undefined;
    const value = body.value;
    const changeReason = (body.change_reason ?? body.changeReason) as string | undefined;
    if (!key || value === undefined) {
      return jsonResponse({ error: "missing_fields" }, 400);
    }

    const { data: entry, error: entryError } = await admin
      .from("remote_config_entries")
      .select("id, category, value_type, value_json")
      .eq("key", key)
      .is("deleted_at", null)
      .maybeSingle();
    if (entryError) throw entryError;
    if (!entry) return jsonResponse({ error: "unknown_key" }, 404);

    if (!typeMatches(value, entry.value_type as ValueType)) {
      return jsonResponse(
        { error: "malformed_value", message: `${key}: expected type '${entry.value_type}'` },
        400,
      );
    }
    const refinementError = categoryRefinementError(entry.category, key, value);
    if (refinementError) {
      return jsonResponse({ error: "malformed_value", message: refinementError }, 400);
    }

    const beforeJson = entry.value_json;

    const { error: updateError } = await admin
      .from("remote_config_entries")
      .update({ value_json: value, updated_by: caller.id })
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
      value_json: value,
      changed_by: caller.id,
      change_reason: changeReason ?? null,
    });

    await admin.from("remote_config_audit").insert({
      entry_id: entry.id,
      action: "updated",
      actor_id: caller.id,
      before_json: beforeJson,
      after_json: value,
    });

    return jsonResponse({ success: true, key, value, version: nextVersion }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "update_remote_config_failed", message }, 500);
  }
});
