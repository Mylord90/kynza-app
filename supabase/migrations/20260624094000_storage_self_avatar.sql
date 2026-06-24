-- Lets any authenticated user upload/replace their own avatar at
-- user/{auth.uid()}/avatar/{uuid}.{ext} in the existing kynza-media
-- bucket — distinct from the salon/{salonId}/... write policies which
-- only owner/manager can touch (20260623201000_storage_kynza_media.sql).
-- Read stays covered by the existing public-read policy on the bucket.
CREATE POLICY "kynza_media_self_avatar_write" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'kynza-media'
    AND (storage.foldername(name))[1] = 'user'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "kynza_media_self_avatar_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'kynza-media'
    AND (storage.foldername(name))[1] = 'user'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );