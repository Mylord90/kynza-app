-- KYNZA Enterprise Final Certification Pass — CP5 (Phase 4, Scalability)
-- Synthetic data generator — REUSABLE, NEVER RUN AGAINST PRODUCTION.
-- Executed only against kynza-dr-scratch (hzjmyeptytvjmzbnsmwp) for this checkpoint's
-- real 1,000-salon-scale test. Ratios scale linearly with the brief's target ceiling
-- (10,000 salons / 50,000 clients / 100,000 bookings): at 1,000 salons this generates
-- 5,000 clients (5/salon) and 10,000 bookings (10/salon), plus 3,000 staff (3/salon)
-- and 5,000 services (5/salon) to support realistic FK joins.
--
-- All synthetic rows are tagged so they can be identified and purged independently of
-- any real seed/test data already in the target project:
--   salons.name LIKE 'CP5-SYN-SALON-%'
--   users.email LIKE 'cp5-syn-%@kynza-load-test.local'

BEGIN;

-- ─── 1,000 synthetic owner auth users + public.users (needed before salons: ─
-- the existing init_owner_journey() trigger requires a non-null owner_id) ───
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
SELECT
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  'cp5-syn-owner-' || i || '@kynza-load-test.local',
  '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y5wJa6sdRnp/rGx3Wp5bBqz.ol.OG', now(),
  now(), now(), '{"provider":"email","providers":["email"]}', '{}', false, '', '', '', ''
FROM generate_series(1, 1000) AS i;

UPDATE public.users SET role = 'owner'
WHERE email LIKE 'cp5-syn-owner-%@kynza-load-test.local';

-- ─── 1,000 synthetic salons, one owner each ─────────────────────────────────
WITH owner_pool AS (
  SELECT id AS owner_id, row_number() OVER () AS rn FROM public.users
  WHERE email LIKE 'cp5-syn-owner-%@kynza-load-test.local'
)
INSERT INTO public.salons (id, name, owner_id, plan, country_code, currency, is_online)
SELECT gen_random_uuid(), 'CP5-SYN-SALON-' || op.rn, op.owner_id, 'free', 'BI', 'BIF', true
FROM owner_pool op;

-- ─── 5,000 synthetic services (5 per salon) ────────────────────────────────
INSERT INTO public.services (id, salon_id, name, category, duration_min, price_bif, is_active)
SELECT gen_random_uuid(), s.id, 'CP5-SYN-SERVICE-' || row_number() OVER (), 'coiffure', 45, 15000, true
FROM public.salons s
CROSS JOIN generate_series(1, 5) AS svc_n
WHERE s.name LIKE 'CP5-SYN-SALON-%';

-- ─── 3,000 synthetic staff auth users + public.users + staff_profiles ──────
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
SELECT
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  'cp5-syn-staff-' || i || '@kynza-load-test.local',
  -- fixed dummy hash — these synthetic users are never signed into, only referenced by FK
  '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y5wJa6sdRnp/rGx3Wp5bBqz.ol.OG', now(),
  now(), now(), '{"provider":"email","providers":["email"]}', '{}', false, '', '', '', ''
FROM generate_series(1, 3000) AS i;

-- public.users rows auto-created by the existing on-auth-user-created trigger, so
-- only role/salon_id need to be set afterward for the staff subset.
WITH staff_salons AS (
  SELECT id AS salon_id, row_number() OVER () AS rn FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%'
),
staff_users AS (
  SELECT id AS user_id, row_number() OVER () AS rn FROM public.users
  WHERE email LIKE 'cp5-syn-staff-%@kynza-load-test.local'
)
UPDATE public.users u
SET role = 'staff', salon_id = ss.salon_id
FROM staff_users su
JOIN staff_salons ss ON ss.rn = ((su.rn - 1) / 3) + 1  -- 3 staff per salon
WHERE u.id = su.user_id;

INSERT INTO public.staff_profiles (id, user_id, salon_id, role, display_name, is_active)
SELECT gen_random_uuid(), u.id, u.salon_id, 'staff', 'CP5-SYN-STAFF-' || row_number() OVER (), true
FROM public.users u
WHERE u.email LIKE 'cp5-syn-staff-%@kynza-load-test.local';

-- ─── 5,000 synthetic client auth users + public.users ──────────────────────
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
SELECT
  '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
  'cp5-syn-client-' || i || '@kynza-load-test.local',
  '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Y5wJa6sdRnp/rGx3Wp5bBqz.ol.OG', now(),
  now(), now(), '{"provider":"email","providers":["email"]}', '{}', false, '', '', '', ''
FROM generate_series(1, 5000) AS i;

-- ─── 10,000 synthetic bookings (10 per salon), spread across +/-30 days ────
WITH salon_pool AS (
  SELECT id AS salon_id, row_number() OVER () AS rn FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%'
),
staff_pool AS (
  SELECT sp.id AS staff_id, sp.salon_id, row_number() OVER (PARTITION BY sp.salon_id) AS staff_rn
  FROM public.staff_profiles sp
  JOIN public.users u ON u.id = sp.user_id
  WHERE u.email LIKE 'cp5-syn-staff-%@kynza-load-test.local'
),
service_pool AS (
  SELECT sv.id AS service_id, sv.salon_id, row_number() OVER (PARTITION BY sv.salon_id) AS svc_rn
  FROM public.services sv WHERE sv.name LIKE 'CP5-SYN-SERVICE-%'
),
client_pool AS (
  SELECT id AS client_id, row_number() OVER () AS rn FROM public.users
  WHERE email LIKE 'cp5-syn-client-%@kynza-load-test.local'
),
booking_seq AS (
  SELECT sp.salon_id, gs AS booking_n, row_number() OVER () AS global_rn
  FROM salon_pool sp CROSS JOIN generate_series(1, 10) AS gs
)
INSERT INTO public.bookings (
  id, salon_id, client_id, practitioner_id, service_id, status,
  start_time, end_time, buffer_end_time, amount_bif, payment_status
)
SELECT
  gen_random_uuid(),
  bs.salon_id,
  cp.client_id,
  stp.staff_id,
  svp.service_id,
  (ARRAY['confirmed','completed','pending_payment','cancelled'])[1 + (bs.global_rn % 4)],
  -- booking_n (1..10) is unique within a salon, so combined with the practitioner's own
  -- staff_rn this is guaranteed collision-free against uq_practitioner_slot even when two
  -- bookings in the same salon share a practitioner (every 3rd booking_n, by construction).
  now() + (bs.booking_n || ' days')::interval + (stp.staff_rn || ' hours')::interval,
  now() + (bs.booking_n || ' days')::interval + (stp.staff_rn || ' hours')::interval + interval '45 minutes',
  now() + (bs.booking_n || ' days')::interval + (stp.staff_rn || ' hours')::interval + interval '60 minutes',
  15000,
  'completed'
FROM booking_seq bs
JOIN staff_pool stp ON stp.salon_id = bs.salon_id AND stp.staff_rn = 1 + (bs.booking_n % 3)
JOIN service_pool svp ON svp.salon_id = bs.salon_id AND svp.svc_rn = 1 + (bs.booking_n % 5)
JOIN client_pool cp ON cp.rn = 1 + (bs.global_rn % 5000);

COMMIT;

-- ─── Purge script (run to remove ONLY this synthetic dataset) ──────────────
-- DELETE FROM public.bookings WHERE salon_id IN (SELECT id FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%');
-- DELETE FROM public.staff_profiles WHERE salon_id IN (SELECT id FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%');
-- DELETE FROM public.services WHERE salon_id IN (SELECT id FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%');
-- UPDATE public.salons SET owner_id = NULL WHERE name LIKE 'CP5-SYN-SALON-%';
-- DELETE FROM public.salons WHERE name LIKE 'CP5-SYN-SALON-%';
-- DELETE FROM auth.users WHERE email LIKE 'cp5-syn-%@kynza-load-test.local'; -- cascades to public.users
