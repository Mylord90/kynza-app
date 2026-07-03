-- DRAFT — reviewed but NOT applied to the remote project (Part 6,
-- docs/FEATURE_FLAGS.md). Data-only (INSERT ... ON CONFLICT DO NOTHING against the
-- EXISTING feature_flags table from 20260630110000_phase4_feature_flags.sql — no
-- schema change, no existing row touched). Lower risk than Part 5's schema
-- migration, but still left in draft form per the same "no local Docker, db push
-- hits the live project directly" caution — apply after review.
--
-- Adds the flags named in the Part 6 registry brief that don't already exist.
-- Real shipped features default to is_enabled=true, rollout=100. Confirmed
-- unimplemented capabilities (no matching Flutter/Edge Function code found
-- anywhere in this repo — see docs/FEATURE_FLAGS.md for the per-flag evidence)
-- default to is_enabled=false, so flipping one on does not silently "enable" a
-- feature that doesn't exist yet.

INSERT INTO public.feature_flags (key, name, description, is_enabled, rollout_percentage) VALUES
  ('feature_google_maps', 'Google Maps', 'Carte interactive pour la découverte de salons — NON implémenté (aucune dépendance google_maps_flutter dans pubspec.yaml).', false, 0),
  ('feature_proxipay', 'ProxiPay', 'Paiement QR en personne — déjà en production (proxipay_sessions + 2 Edge Functions).', true, 100),
  ('feature_ble', 'ProxiPay via Bluetooth', 'Transport BLE pour ProxiPay — NON implémenté (aucun package Bluetooth dans pubspec.yaml, aucune classe TransportDetector).', false, 0),
  ('feature_nfc', 'ProxiPay via NFC', 'Transport NFC pour ProxiPay — NON implémenté (même constat que BLE).', false, 0),
  ('feature_qr', 'Scan QR (ProxiPay + fidélité)', 'mobile_scanner + qr_flutter — déjà en production.', true, 100),
  ('feature_notifications', 'Notifications', 'Push FCM + WhatsApp + in-app — déjà en production.', true, 100),
  ('feature_reviews', 'Avis clients', 'Déjà en production (Phase 3A).', true, 100),
  ('feature_marketing', 'Marketing', 'Promotions, contacts, partage — déjà en production (Phase 3A).', true, 100),
  ('feature_referrals', 'Parrainage', 'Déjà en production (Phase 3B).', true, 100),
  ('feature_loyalty', 'Fidélité', 'Cartes de tampons + QR — déjà en production.', true, 100),
  ('feature_commissions', 'Commissions équipe', 'Déjà en production (Phase 5).', true, 100),
  ('feature_dashboard', 'Dashboard analytique', 'fl_chart, réservé Owner — déjà en production (Phase 4).', true, 100),
  ('feature_pdf', 'Export PDF', 'pdf + printing — déjà en production.', true, 100),
  ('feature_csv', 'Export CSV', 'CsvExporter — déjà en production.', true, 100),
  ('feature_export', 'Sauvegarde / export salon', 'create-backup Edge Function — déjà en production, cooldown 1/6h.', true, 100),
  ('feature_crashlytics', 'Crashlytics', 'CrashReportingService — technique, toujours actif, pas un flag utilisateur.', true, 100),
  ('feature_i18n', 'FR/EN', 'Pipeline i18n câblé mais seulement partiellement retrofitté (~2 clés sur 100+ écrans — dette connue).', true, 100),
  ('feature_chat', 'Messagerie in-app', 'NON implémenté — aucun dossier chat/messaging dans lib/features.', false, 0),
  ('feature_ai', 'Fonctionnalités IA', 'NON implémenté — le flag DB existant `ai_scheduling` (préexistant, distinct de celui-ci) n''est lu par aucun code non plus.', false, 0),
  ('feature_offline', 'Mode hors-ligne étendu', 'Partiel seulement — 2 boxes Hive (session, permissions), pas de file outbox. Voir docs/OFFLINE_STRATEGY.md.', true, 100),
  ('feature_sync', 'Synchronisation en arrière-plan', 'NON implémenté comme mécanisme dédié — aucune OutboxSyncService dans lib/.', false, 0),
  ('feature_subscriptions', 'Abonnements / Billing', 'Déjà en production (Phase 6) — check-subscription (expiry auto) reste non câblé, voir EDGE_FUNCTIONS_REFERENCE.md.', true, 100),
  ('feature_staff', 'Rôle Staff', 'Déjà en production.', true, 100),
  ('feature_owner', 'Rôle Owner', 'Déjà en production.', true, 100),
  ('feature_manager', 'Rôle Manager', 'Route guards et accès partagé en production, MAIS le home shell Manager est un stub UI (5 onglets, même empty-state statique) — voir WORKFLOWS.md §3.3.', true, 100),
  ('feature_support', 'Rôle Client Support', 'NON implémenté — aucun rôle CLIENT_SUPPORT dans UserRole enum, RLS, ou permission_groups.base_role. Voir WORKFLOWS.md §3.5.', false, 0),
  ('leapa_enabled', 'Leapa (Mobile Money) go-live', 'AUCUN flag de ce nom trouvé dans le code — Leapa est déjà inconditionnellement actif via les secrets Vault (LEAPA_API_KEY etc.), pas gated par un flag. Ajouté ici pour permettre un futur kill-switch propre sans redéploiement.', true, 100),
  ('feature_app_check', 'App Check / Play Integrity', 'NON activé — scaffold Phase 10 uniquement (double-gate Env.appCheckEnabled + ce flag, les deux inertes par défaut). Aucune dépendance firebase_app_check dans pubspec.yaml ; les Edge Functions create-booking/proxipay-confirm ne font que logger la présence du header, jamais bloquer. Voir docs/security/APP_CHECK_ARCHITECTURE.md.', false, 0)
ON CONFLICT (key) DO NOTHING;
