-- ================================================================
-- PHASE 3 — Enterprise Data Platform
-- Sub-migration 3/4: backup_jobs table + kynza-backups storage bucket
--
-- Design:
--   • create-backup Edge Function (service_role) writes salon data
--     as JSON to kynza-backups storage and records the job here.
--   • Rate limit enforced by the Edge Function (max 1 backup per 6h).
--   • Last 90 days of bookings/reviews are exported; reference tables
--     (services, staff, clients) are exported in full (soft-deleted
--     rows included — this is a data archive, not a filtered view).
--   • No physical DOWNLOAD button in V1: the signed URL approach is
--     used to let the owner see the backup is there and retrieve it
--     via support if needed. The storage object is the real backup.
-- ================================================================

-- ── 1. backup_jobs ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.backup_jobs (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id         UUID        NOT NULL REFERENCES public.salons(id),
  initiated_by     UUID        NOT NULL REFERENCES public.users(id),
  status           TEXT        NOT NULL DEFAULT 'pending'
                               CHECK (status IN ('pending','running','completed','failed')),
  storage_path     TEXT,
  file_size_bytes  BIGINT,
  error_message    TEXT,
  tables_included  TEXT[]      NOT NULL DEFAULT '{}',
  records_exported INT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_backup_jobs_salon
  ON public.backup_jobs (salon_id, created_at DESC);

ALTER TABLE public.backup_jobs ENABLE ROW LEVEL SECURITY;

-- Owner and manager can view their salon's backups
CREATE POLICY "backup_jobs_owner_manager_select" ON public.backup_jobs
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner',   salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- No INSERT/UPDATE/DELETE from authenticated clients:
-- only the create-backup Edge Function (service_role) writes here.

-- ── 2. Storage bucket: kynza-backups (private) ───────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('kynza-backups', 'kynza-backups', false)
ON CONFLICT (id) DO NOTHING;

-- Path convention: salon/{salon_id}/{timestamp_ms}.json
-- Owner can read (to generate a signed URL for download)
CREATE POLICY "kynza_backups_owner_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kynza-backups'
    AND public.has_role(
      auth.uid(),
      'owner',
      ((storage.foldername(name))[2])::uuid
    )
  );

-- Only service_role (Edge Function) can INSERT/UPDATE/DELETE.
-- No authenticated write policy — prevents clients from injecting
-- or overwriting backup objects.