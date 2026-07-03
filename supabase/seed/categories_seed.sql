-- KYNZA — Category & Service Template Seed (Part 5, docs/CATALOG_ARCHITECTURE.md)
--
-- DRAFT — NOT applied to the remote project. Depends on the tables created by
-- supabase/migrations/20260703130000_catalog_schema.sql (also drafted, not applied).
-- Run this only after that migration has been reviewed and manually applied.
--
-- Idempotent: every INSERT is ON CONFLICT (slug) DO NOTHING / ON CONFLICT DO NOTHING,
-- safe to run twice without duplicating rows (verified by design — see
-- docs/CATALOG_EXTENSION_GUIDE.md's "run it twice" acceptance check).
--
-- Generated systematically from two small config tables (category list + band
-- pricing/naming rules) rather than 72 hand-typed INSERT blocks, per the brief's
-- own maintainability requirement. Pricing anchored to the one real, verified
-- data point in this codebase (test/unit/booking_flow_notifier_test.dart: a
-- 30-minute "Coiffure Homme" service priced at 10 000 BIF) and extrapolated by
-- service-type band from there — NOT pulled from a live data export (no
-- production-database read was performed for this pass; treat these as sane
-- placeholder defaults for owners to adjust, not observed market prices).

DO $$
DECLARE
  cat RECORD;
  band RECORD;
  top_id UUID;
  sub1_id UUID;
  sub2_id UUID;
  tier1_mult_price CONSTANT NUMERIC := 1.0;
  tier1_mult_dur   CONSTANT NUMERIC := 1.0;
  tier2_mult_price CONSTANT NUMERIC := 1.6;
  tier2_mult_dur   CONSTANT NUMERIC := 1.3;
BEGIN

  -- ===== Band config: pricing/duration base + name fragments + suggested variants =====
  CREATE TEMP TABLE _band_config (
    band TEXT PRIMARY KEY,
    fragment1 TEXT, fragment2 TEXT,
    base_duration_min INT, base_price_bif INT,
    variants JSONB
  ) ON COMMIT DROP;

  INSERT INTO _band_config VALUES
    ('HAIR_WOMEN', 'Shampooing & Brushing', 'Coupe & Coiffage', 45, 15000,
      '[{"name":"Cheveux courts","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Cheveux mi-longs","duration_delta_minutes":15,"price_delta_bif":3000},
        {"name":"Cheveux longs","duration_delta_minutes":30,"price_delta_bif":6000}]'::jsonb),
    ('HAIR_MEN', 'Coupe Classique', 'Coupe & Barbe', 30, 10000,
      '[{"name":"Cheveux courts","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Dégradé précis","duration_delta_minutes":10,"price_delta_bif":2000}]'::jsonb),
    ('HAIR_KIDS', 'Coupe Enfant', 'Coupe & Coiffure', 25, 7000,
      '[{"name":"Moins de 6 ans","duration_delta_minutes":-5,"price_delta_bif":-1000},
        {"name":"6-12 ans","duration_delta_minutes":0,"price_delta_bif":0}]'::jsonb),
    ('WELLNESS_SPA', 'Séance Découverte', 'Séance Signature', 60, 25000,
      '[{"name":"30 min","duration_delta_minutes":-30,"price_delta_bif":-10000},
        {"name":"60 min","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"90 min","duration_delta_minutes":30,"price_delta_bif":12000}]'::jsonb),
    ('FACE_SKIN', 'Soin Express', 'Soin Complet', 45, 20000,
      '[{"name":"Formule Standard","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Formule Premium","duration_delta_minutes":15,"price_delta_bif":8000}]'::jsonb),
    ('MAKEUP', 'Maquillage Naturel', 'Maquillage Glamour', 60, 18000,
      '[{"name":"Formule Standard","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Avec essai préalable","duration_delta_minutes":45,"price_delta_bif":10000}]'::jsonb),
    ('NAILS', 'Manucure', 'Pose de Vernis Semi-Permanent', 40, 8000,
      '[{"name":"Mains","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Pieds","duration_delta_minutes":10,"price_delta_bif":2000},
        {"name":"Mains + Pieds","duration_delta_minutes":25,"price_delta_bif":4000}]'::jsonb),
    ('HAIR_REMOVAL', 'Zone Ciblée', 'Zones Multiples', 30, 9000,
      '[{"name":"Une zone","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Zones multiples","duration_delta_minutes":20,"price_delta_bif":5000}]'::jsonb),
    ('BODY_ART', 'Format Standard', 'Format Personnalisé', 60, 20000,
      '[{"name":"Petit format (< 5cm)","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Format moyen","duration_delta_minutes":30,"price_delta_bif":15000},
        {"name":"Grand format","duration_delta_minutes":90,"price_delta_bif":40000}]'::jsonb),
    ('LIFESTYLE', 'Séance Découverte', 'Séance Approfondie', 45, 15000,
      '[{"name":"Formule Standard","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Formule Premium","duration_delta_minutes":15,"price_delta_bif":8000}]'::jsonb),
    ('PREMIUM_NICHE', 'Formule Essentielle', 'Formule Signature', 45, 20000,
      '[{"name":"Formule Standard","duration_delta_minutes":0,"price_delta_bif":0},
        {"name":"Formule Premium","duration_delta_minutes":20,"price_delta_bif":10000}]'::jsonb)
  ;

  -- ===== Category config: 72 top-level categories (>= 70 required) =====
  CREATE TEMP TABLE _cat_config (
    slug TEXT PRIMARY KEY, name_fr TEXT, gender_scope TEXT, band TEXT, sort_order INT
  ) ON COMMIT DROP;

  INSERT INTO _cat_config VALUES
    ('coiffure-femme', 'Coiffure Femme', 'femme', 'HAIR_WOMEN', 10),
    ('coiffure-homme', 'Coiffure Homme', 'homme', 'HAIR_MEN', 20),
    ('barbershop', 'Barbershop', 'homme', 'HAIR_MEN', 30),
    ('braids-tresses-africaines', 'Braids & Tresses Africaines', 'mixte', 'HAIR_WOMEN', 40),
    ('locks', 'Locks', 'mixte', 'HAIR_WOMEN', 50),
    ('twists', 'Twists', 'mixte', 'HAIR_WOMEN', 60),
    ('cornrows', 'Cornrows', 'mixte', 'HAIR_WOMEN', 70),
    ('extensions', 'Extensions', 'femme', 'HAIR_WOMEN', 80),
    ('perruques', 'Perruques', 'femme', 'HAIR_WOMEN', 90),
    ('coloration', 'Coloration', 'mixte', 'HAIR_WOMEN', 100),
    ('defrisage', 'Défrisage', 'femme', 'HAIR_WOMEN', 110),
    ('traitements-capillaires', 'Traitements Capillaires', 'mixte', 'HAIR_WOMEN', 120),
    ('lissage', 'Lissage', 'femme', 'HAIR_WOMEN', 130),
    ('brushing', 'Brushing', 'femme', 'HAIR_WOMEN', 140),
    ('coupe', 'Coupe', 'mixte', 'HAIR_WOMEN', 150),
    ('coiffure-enfant', 'Coiffure Enfant', 'enfant', 'HAIR_KIDS', 160),
    ('coiffure-mariage', 'Coiffure Mariage', 'femme', 'HAIR_WOMEN', 170),
    ('spa', 'Spa', 'mixte', 'WELLNESS_SPA', 180),
    ('massage', 'Massage', 'mixte', 'WELLNESS_SPA', 190),
    ('hammam', 'Hammam', 'mixte', 'WELLNESS_SPA', 200),
    ('sauna', 'Sauna', 'mixte', 'WELLNESS_SPA', 210),
    ('jacuzzi', 'Jacuzzi', 'mixte', 'WELLNESS_SPA', 220),
    ('soins-visage', 'Soins Visage', 'mixte', 'FACE_SKIN', 230),
    ('peeling', 'Peeling', 'mixte', 'FACE_SKIN', 240),
    ('hydrafacial', 'Hydrafacial', 'mixte', 'FACE_SKIN', 250),
    ('maquillage', 'Maquillage', 'femme', 'MAKEUP', 260),
    ('ongles-manucure', 'Ongles & Manucure', 'femme', 'NAILS', 270),
    ('pedicure', 'Pédicure', 'mixte', 'NAILS', 280),
    ('epilation', 'Épilation', 'femme', 'HAIR_REMOVAL', 290),
    ('sourcils', 'Sourcils', 'femme', 'HAIR_REMOVAL', 300),
    ('cils', 'Cils', 'femme', 'HAIR_REMOVAL', 310),
    ('tatouage', 'Tatouage', 'mixte', 'BODY_ART', 320),
    ('piercing', 'Piercing', 'mixte', 'BODY_ART', 330),
    ('parfum', 'Parfum', 'mixte', 'LIFESTYLE', 340),
    ('bien-etre', 'Bien-être', 'mixte', 'WELLNESS_SPA', 350),
    ('nutrition', 'Nutrition', 'mixte', 'LIFESTYLE', 360),
    ('yoga', 'Yoga', 'mixte', 'LIFESTYLE', 370),
    ('meditation', 'Méditation', 'mixte', 'LIFESTYLE', 380),
    ('dermatologie-esthetique', 'Dermatologie Esthétique', 'mixte', 'FACE_SKIN', 390),
    ('blanchiment-dentaire', 'Blanchiment Dentaire', 'mixte', 'FACE_SKIN', 400),
    ('cryotherapie', 'Cryothérapie', 'mixte', 'WELLNESS_SPA', 410),
    ('bronzage', 'Bronzage', 'mixte', 'FACE_SKIN', 420),
    ('relooking', 'Relooking', 'mixte', 'MAKEUP', 430),
    ('conseil-beaute', 'Conseil Beauté', 'mixte', 'MAKEUP', 440),
    ('photographie-beaute', 'Photographie Beauté', 'mixte', 'LIFESTYLE', 450),
    ('consultation-beaute', 'Consultation Beauté', 'mixte', 'LIFESTYLE', 460),
    ('beaute-africaine', 'Beauté Africaine', 'mixte', 'PREMIUM_NICHE', 470),
    ('beaute-orientale', 'Beauté Orientale', 'mixte', 'PREMIUM_NICHE', 480),
    ('beaute-premium', 'Beauté Premium', 'mixte', 'PREMIUM_NICHE', 490),
    ('beaute-vip', 'Beauté VIP', 'mixte', 'PREMIUM_NICHE', 500),
    ('beaute-homme-premium', 'Beauté Homme Premium', 'homme', 'PREMIUM_NICHE', 510),
    ('beaute-enfant', 'Beauté Enfant', 'enfant', 'PREMIUM_NICHE', 520),
    ('beaute-senior', 'Beauté Senior', 'mixte', 'PREMIUM_NICHE', 530),
    ('beaute-express', 'Beauté Express', 'mixte', 'PREMIUM_NICHE', 540),
    ('beaute-a-domicile', 'Beauté à Domicile', 'mixte', 'PREMIUM_NICHE', 550),
    ('beaute-entreprise', 'Beauté Entreprise', 'mixte', 'PREMIUM_NICHE', 560),
    ('soins-des-mains', 'Soins des Mains', 'mixte', 'NAILS', 570),
    ('soins-des-pieds', 'Soins des Pieds', 'mixte', 'NAILS', 580),
    ('coloration-homme', 'Coloration Homme', 'homme', 'HAIR_MEN', 590),
    ('extensions-de-cils', 'Extensions de Cils', 'femme', 'HAIR_REMOVAL', 600),
    ('microblading-sourcils', 'Microblading Sourcils', 'femme', 'HAIR_REMOVAL', 610),
    ('massage-prenatal', 'Massage Prénatal', 'femme', 'WELLNESS_SPA', 620),
    ('reflexologie', 'Réflexologie', 'mixte', 'WELLNESS_SPA', 630),
    ('onglerie-enfant', 'Onglerie Enfant', 'enfant', 'NAILS', 640),
    ('coiffure-evenementielle', 'Coiffure Événementielle', 'femme', 'HAIR_WOMEN', 650),
    ('soins-capillaires-homme', 'Soins Capillaires Homme', 'homme', 'HAIR_MEN', 660),
    ('epilation-homme', 'Épilation Homme', 'homme', 'HAIR_REMOVAL', 670),
    ('maquillage-permanent', 'Maquillage Permanent', 'femme', 'MAKEUP', 680),
    ('spa-duo', 'Spa Duo', 'mixte', 'WELLNESS_SPA', 690),
    ('rasage-traditionnel', 'Rasage Traditionnel', 'homme', 'HAIR_MEN', 700),
    ('coaching-image', 'Coaching Image', 'mixte', 'MAKEUP', 710),
    -- Catch-all: the free-text "Autre" fallback category. Owners can always skip
    -- category_id entirely (services.category free text keeps working), but this
    -- gives the picker UI an explicit "Autre" leaf too.
    ('autres', 'Autres', 'mixte', 'PREMIUM_NICHE', 9999)
  ;

  -- ===== Generate: top-level category -> 2 sub-categories -> 2 service_templates each =====
  FOR cat IN SELECT * FROM _cat_config ORDER BY sort_order LOOP
    SELECT * INTO band FROM _band_config WHERE _band_config.band = cat.band;

    INSERT INTO public.categories (slug, name_fr, gender_scope, icon, sort_order)
    VALUES (cat.slug, cat.name_fr, cat.gender_scope, 'ic_' || replace(cat.slug, '-', '_'), cat.sort_order)
    ON CONFLICT (slug) DO NOTHING
    RETURNING id INTO top_id;

    -- ON CONFLICT DO NOTHING skips RETURNING on a duplicate — re-select if so,
    -- so re-running this script is safe AND still resolves sub-category parents.
    IF top_id IS NULL THEN
      SELECT id INTO top_id FROM public.categories WHERE slug = cat.slug;
    END IF;

    INSERT INTO public.categories (parent_id, slug, name_fr, gender_scope, sort_order)
    VALUES (top_id, cat.slug || '-classique', cat.name_fr || ' — Classique', cat.gender_scope, 1)
    ON CONFLICT (slug) DO NOTHING
    RETURNING id INTO sub1_id;
    IF sub1_id IS NULL THEN
      SELECT id INTO sub1_id FROM public.categories WHERE slug = cat.slug || '-classique';
    END IF;

    INSERT INTO public.categories (parent_id, slug, name_fr, gender_scope, sort_order)
    VALUES (top_id, cat.slug || '-premium', cat.name_fr || ' — Premium', cat.gender_scope, 2)
    ON CONFLICT (slug) DO NOTHING
    RETURNING id INTO sub2_id;
    IF sub2_id IS NULL THEN
      SELECT id INTO sub2_id FROM public.categories WHERE slug = cat.slug || '-premium';
    END IF;

    -- Tier 1 (Classique) — 2 service templates at base price/duration
    INSERT INTO public.service_templates
      (category_id, name, gender_scope, default_duration_minutes, default_price_bif, default_variants)
    VALUES
      (sub1_id, band.fragment1 || ' — ' || cat.name_fr, cat.gender_scope,
        round(band.base_duration_min * tier1_mult_dur)::INT,
        round(band.base_price_bif * tier1_mult_price)::INT, band.variants),
      (sub1_id, band.fragment2 || ' — ' || cat.name_fr, cat.gender_scope,
        round(band.base_duration_min * tier1_mult_dur)::INT,
        round(band.base_price_bif * tier1_mult_price)::INT, band.variants)
    ON CONFLICT (category_id, name) DO NOTHING;

    -- Tier 2 (Premium) — same 2 fragments, scaled price/duration
    INSERT INTO public.service_templates
      (category_id, name, gender_scope, default_duration_minutes, default_price_bif, default_variants)
    VALUES
      (sub2_id, band.fragment1 || ' — ' || cat.name_fr || ' (Premium)', cat.gender_scope,
        round(band.base_duration_min * tier2_mult_dur)::INT,
        round(band.base_price_bif * tier2_mult_price)::INT, band.variants),
      (sub2_id, band.fragment2 || ' — ' || cat.name_fr || ' (Premium)', cat.gender_scope,
        round(band.base_duration_min * tier2_mult_dur)::INT,
        round(band.base_price_bif * tier2_mult_price)::INT, band.variants)
    ON CONFLICT (category_id, name) DO NOTHING;

  END LOOP;

END $$;
