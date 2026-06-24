-- ================================================================
-- KYNZA — Migration 006 — Storage bucket for salon media
-- Public read (logos/covers/portfolio must render in the public salon
-- discovery feed without auth) — write restricted to owner/manager of
-- the salon whose folder (salon/{salonId}/...) is being written to.
-- ================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('kynza-media', 'kynza-media', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "kynza_media_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'kynza-media');

CREATE POLICY "kynza_media_owner_manager_write" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'kynza-media'
    AND (
      public.has_role(auth.uid(), 'owner', ((storage.foldername(name))[2])::uuid)
      OR public.has_role(auth.uid(), 'manager', ((storage.foldername(name))[2])::uuid)
    )
  );

CREATE POLICY "kynza_media_owner_manager_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'kynza-media'
    AND (
      public.has_role(auth.uid(), 'owner', ((storage.foldername(name))[2])::uuid)
      OR public.has_role(auth.uid(), 'manager', ((storage.foldername(name))[2])::uuid)
    )
  );

CREATE POLICY "kynza_media_owner_manager_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'kynza-media'
    AND (
      public.has_role(auth.uid(), 'owner', ((storage.foldername(name))[2])::uuid)
      OR public.has_role(auth.uid(), 'manager', ((storage.foldername(name))[2])::uuid)
    )
  );
