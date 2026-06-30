import { corsHeaders, handleOptions, jsonResponse } from "../_shared/cors.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

const BACKUP_COOLDOWN_SECONDS = 6 * 60 * 60; // 6 hours between backups
const LOOKBACK_DAYS = 90;

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  let user: { id: string; role: string; salon_id: string | null };
  try {
    user = await getAuthenticatedUser(req);
  } catch {
    return jsonResponse({ error: "unauthenticated" }, 401);
  }

  if (!user.salon_id) {
    return jsonResponse({ error: "no_salon" }, 403);
  }
  if (user.role !== "owner" && user.role !== "manager") {
    return jsonResponse({ error: "forbidden" }, 403);
  }

  const admin = createServiceRoleClient();
  const salonId = user.salon_id;

  // ── Rate limit: max 1 backup per 6 hours ─────────────────────────
  const { data: recentBackups } = await admin
    .from("backup_jobs")
    .select("id, created_at")
    .eq("salon_id", salonId)
    .in("status", ["pending", "running", "completed"])
    .gte(
      "created_at",
      new Date(Date.now() - BACKUP_COOLDOWN_SECONDS * 1000).toISOString(),
    )
    .limit(1);

  if (recentBackups && recentBackups.length > 0) {
    return jsonResponse(
      {
        error: "too_soon",
        message: "Un seul backup toutes les 6 heures est autorisé.",
        last_backup_at: recentBackups[0].created_at,
      },
      429,
    );
  }

  // ── Create the job record (status: running) ───────────────────────
  const { data: job, error: jobError } = await admin
    .from("backup_jobs")
    .insert({
      salon_id: salonId,
      initiated_by: user.id,
      status: "running",
    })
    .select("id")
    .single();

  if (jobError || !job) {
    return jsonResponse({ error: "job_create_failed" }, 500);
  }

  const jobId = job.id as string;

  try {
    const cutoff = new Date(
      Date.now() - LOOKBACK_DAYS * 24 * 60 * 60 * 1000,
    ).toISOString();

    // ── Export each table ───────────────────────────────────────────
    // Reference tables: full export (services, staff, clients)
    // Transactional tables: last 90 days (bookings, reviews)
    const [
      { data: salon },
      { data: services },
      { data: staffProfiles },
      { data: clients },
      { data: bookings },
      { data: reviews },
      { data: invoices },
    ] = await Promise.all([
      admin
        .from("salons")
        .select("*")
        .eq("id", salonId)
        .single(),
      admin
        .from("services")
        .select("*")
        .eq("salon_id", salonId),
      admin
        .from("staff_profiles")
        .select("*")
        .eq("salon_id", salonId),
      // Clients: users who have booked with this salon (distinct)
      admin
        .from("bookings")
        .select("client_id, users!inner(id, full_name, phone, email, created_at)")
        .eq("salon_id", salonId)
        .is("deleted_at", null),
      admin
        .from("bookings")
        .select("*")
        .eq("salon_id", salonId)
        .gte("created_at", cutoff),
      admin
        .from("reviews")
        .select("*")
        .eq("salon_id", salonId)
        .gte("created_at", cutoff),
      admin
        .from("invoices")
        .select("*")
        .eq("salon_id", salonId)
        .gte("created_at", cutoff),
    ]);

    // Deduplicate clients (same client can have multiple bookings)
    const uniqueClients = Array.from(
      new Map(
        (clients ?? []).map((b: Record<string, unknown>) => {
          const u = b["users"] as Record<string, unknown>;
          return [u?.["id"], u];
        }),
      ).values(),
    );

    const tables = ["salon", "services", "staff_profiles", "clients", "bookings", "reviews", "invoices"];
    const payload = {
      exported_at: new Date().toISOString(),
      salon_id: salonId,
      lookback_days: LOOKBACK_DAYS,
      data: {
        salon,
        services: services ?? [],
        staff_profiles: staffProfiles ?? [],
        clients: uniqueClients,
        bookings: bookings ?? [],
        reviews: reviews ?? [],
        invoices: invoices ?? [],
      },
    };

    const jsonBytes = new TextEncoder().encode(JSON.stringify(payload));
    const storagePath = `salon/${salonId}/${Date.now()}.json`;

    const { error: uploadError } = await admin.storage
      .from("kynza-backups")
      .upload(storagePath, jsonBytes, {
        contentType: "application/json",
        upsert: false,
      });

    if (uploadError) throw new Error(`storage_upload_failed: ${uploadError.message}`);

    const totalRecords =
      (services?.length ?? 0) +
      (staffProfiles?.length ?? 0) +
      uniqueClients.length +
      (bookings?.length ?? 0) +
      (reviews?.length ?? 0) +
      (invoices?.length ?? 0);

    await admin
      .from("backup_jobs")
      .update({
        status: "completed",
        storage_path: storagePath,
        file_size_bytes: jsonBytes.byteLength,
        tables_included: tables,
        records_exported: totalRecords,
        completed_at: new Date().toISOString(),
      })
      .eq("id", jobId);

    return jsonResponse({
      job_id: jobId,
      status: "completed",
      storage_path: storagePath,
      file_size_bytes: jsonBytes.byteLength,
      records_exported: totalRecords,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await admin
      .from("backup_jobs")
      .update({
        status: "failed",
        error_message: message,
        completed_at: new Date().toISOString(),
      })
      .eq("id", jobId);

    return jsonResponse({ error: "backup_failed", detail: message }, 500);
  }
});