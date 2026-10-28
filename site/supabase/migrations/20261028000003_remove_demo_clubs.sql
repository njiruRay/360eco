-- =============================================================================
-- 360 Econovations — remove the demo clubs and waste collections
--
-- The reset seeded 3 made-up clubs and 4 waste collections so the Impact
-- figures had something to show. They go now; real clubs are added in the
-- Table Editor. Run once in the Supabase SQL Editor.
--
-- With the tables empty the live counts would read "0+ partner clubs", so
-- get_impact() now shows whichever is larger: the real count or the figure
-- in site_settings (impact_partner_clubs, impact_waste_kg). Once real records
-- pass those figures the live numbers take over by themselves.
-- =============================================================================

BEGIN;

TRUNCATE clubs, waste_collections, processing_batches RESTART IDENTITY;

INSERT INTO site_settings (key, value, is_public) VALUES ('impact_waste_kg', '0', TRUE)
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.get_impact()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    WITH s AS (
        SELECT key, CASE WHEN value ~ '^\s*\d+(\.\d+)?\s*$' THEN trim(value)::NUMERIC END AS num
          FROM public.site_settings
    )
    SELECT jsonb_build_object(
        'glassTonnesDiverted', coalesce((SELECT num FROM s WHERE key = 'impact_glass_tonnes'), 0),
        'householdsReached',   coalesce((SELECT floor(num)::BIGINT FROM s WHERE key = 'impact_households'), 0),
        'jobsCreated',         coalesce((SELECT floor(num)::BIGINT FROM s WHERE key = 'impact_jobs_created'), 0),
        'partnerClubs',        greatest(
                                   (SELECT count(*) FROM public.clubs WHERE status = 'active'),
                                   coalesce((SELECT floor(num)::BIGINT FROM s WHERE key = 'impact_partner_clubs'), 0)),
        'totalWasteKg',        greatest(
                                   coalesce((SELECT sum(weight_kg) FROM public.waste_collections), 0),
                                   coalesce((SELECT num FROM s WHERE key = 'impact_waste_kg'), 0))
    );
$$;
REVOKE ALL ON FUNCTION public.get_impact() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_impact() TO anon, authenticated;

COMMIT;
