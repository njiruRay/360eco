-- 20261028000002_security_and_functions.sql
-- 360 Econovations — who can do what from the website, plus the server-side
-- business logic that used to live in Spring Boot.
--
-- The publishable key ships inside the website, so EVERYTHING here assumes the
-- caller may be hostile. Two layers protect each table:
--   1. GRANTs   — which operations (and which columns) the website roles may touch
--   2. Policies — which rows those operations may touch (Row Level Security)
-- Roles: anon = not signed in, authenticated = signed-in customer.
-- Staff work in the Supabase dashboard, which bypasses both layers.
--
-- Run once in: Supabase dashboard → SQL Editor → New query → paste → Run.
-- Safe to re-run.

BEGIN;

-- =========================================================
-- 0. Start from zero: the website roles get nothing by default
-- =========================================================

REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;

-- Tables created later in the dashboard are locked too, until granted on purpose.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES    FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated;

-- =========================================================
-- 1. Public catalogue & content (read-only for everyone)
-- =========================================================

GRANT SELECT ON categories, products, product_images, page_content TO anon, authenticated;

DROP POLICY IF EXISTS "categories readable by all" ON categories;
CREATE POLICY "categories readable by all" ON categories
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "visible products readable by all" ON products;
CREATE POLICY "visible products readable by all" ON products
    FOR SELECT TO anon, authenticated USING (is_visible);

DROP POLICY IF EXISTS "images of visible products readable by all" ON product_images;
CREATE POLICY "images of visible products readable by all" ON product_images
    FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM products p WHERE p.id = product_id AND p.is_visible));

DROP POLICY IF EXISTS "page content readable by all" ON page_content;
CREATE POLICY "page content readable by all" ON page_content
    FOR SELECT TO anon, authenticated USING (true);

-- Settings: only rows explicitly marked public are visible to the website,
-- so a future private setting can't leak by accident.
ALTER TABLE site_settings ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE site_settings SET is_public = TRUE
WHERE key IN ('delivery_fee_default', 'impact_glass_tonnes', 'impact_households',
              'impact_jobs_created', 'impact_partner_clubs');

GRANT SELECT ON site_settings TO anon, authenticated;

DROP POLICY IF EXISTS "public settings readable by all" ON site_settings;
CREATE POLICY "public settings readable by all" ON site_settings
    FOR SELECT TO anon, authenticated USING (is_public);

-- =========================================================
-- 2. Customer's own data
-- =========================================================

-- Profiles: created by the sign-up trigger; customers may read and edit
-- their own name/phone only (email is managed by Supabase Auth).
GRANT SELECT ON profiles TO authenticated;
GRANT UPDATE (full_name, phone) ON profiles TO authenticated;

DROP POLICY IF EXISTS "own profile readable" ON profiles;
CREATE POLICY "own profile readable" ON profiles
    FOR SELECT TO authenticated USING (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "own profile editable" ON profiles;
CREATE POLICY "own profile editable" ON profiles
    FOR UPDATE TO authenticated
    USING (id = (SELECT auth.uid())) WITH CHECK (id = (SELECT auth.uid()));

-- Addresses: full CRUD on own rows. user_id is filled in automatically
-- (column default auth.uid()) and can't be set or changed by the caller.
GRANT SELECT, DELETE ON addresses TO authenticated;
GRANT INSERT (label, sub_county, town, street, is_default) ON addresses TO authenticated;
GRANT UPDATE (label, sub_county, town, street, is_default) ON addresses TO authenticated;

DROP POLICY IF EXISTS "own addresses" ON addresses;
CREATE POLICY "own addresses" ON addresses
    FOR ALL TO authenticated
    USING (user_id = (SELECT auth.uid())) WITH CHECK (user_id = (SELECT auth.uid()));

-- Only one default address per customer: setting one clears the others.
CREATE OR REPLACE FUNCTION public.addresses_single_default()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    UPDATE public.addresses
       SET is_default = FALSE
     WHERE user_id = NEW.user_id AND id <> NEW.id AND is_default;
    RETURN NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.addresses_single_default() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS addresses_single_default ON addresses;
CREATE TRIGGER addresses_single_default
    AFTER INSERT OR UPDATE OF is_default ON addresses
    FOR EACH ROW WHEN (NEW.is_default)
    EXECUTE FUNCTION public.addresses_single_default();

-- Orders: customers can READ their own orders. Nobody writes orders directly;
-- place_order() below is the only way in.
GRANT SELECT ON orders, order_items TO authenticated;

DROP POLICY IF EXISTS "own orders readable" ON orders;
CREATE POLICY "own orders readable" ON orders
    FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "own order items readable" ON order_items;
CREATE POLICY "own order items readable" ON order_items
    FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM orders o WHERE o.id = order_id AND o.user_id = (SELECT auth.uid())));

-- =========================================================
-- 3. Contact form: anyone may send, nobody may read back
-- =========================================================

ALTER TABLE contact_submissions DROP CONSTRAINT IF EXISTS contact_name_present;
ALTER TABLE contact_submissions ADD CONSTRAINT contact_name_present
    CHECK (length(trim(name)) > 0);
ALTER TABLE contact_submissions DROP CONSTRAINT IF EXISTS contact_message_length;
ALTER TABLE contact_submissions ADD CONSTRAINT contact_message_length
    CHECK (length(trim(message)) BETWEEN 1 AND 4000);

GRANT INSERT (name, email, phone, message) ON contact_submissions TO anon, authenticated;

DROP POLICY IF EXISTS "anyone can send a message" ON contact_submissions;
CREATE POLICY "anyone can send a message" ON contact_submissions
    FOR INSERT TO anon, authenticated WITH CHECK (NOT is_read);

-- clubs, waste_collections, processing_batches: no grants, no policies —
-- dashboard only. (RLS is already on from the schema script.)

-- =========================================================
-- 4. Business logic
-- =========================================================

-- One order as JSON, in the exact shape the website already expects
-- (same field names as the old Spring Boot OrderResponse). Internal helper.
CREATE OR REPLACE FUNCTION public.order_json(p_order_id BIGINT)
RETURNS JSONB
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
    SELECT jsonb_build_object(
        'id',                o.id,
        'reference',         o.reference,
        'customerName',      o.customer_name,
        'customerPhone',     o.customer_phone,
        'deliverySubCounty', o.delivery_sub_county,
        'deliveryAddress',   o.delivery_address,
        'deliveryLat',       o.delivery_lat,
        'deliveryLng',       o.delivery_lng,
        'status',            o.status,
        'paymentMethod',     o.payment_method,
        'subtotal',          o.subtotal,
        'deliveryFee',       o.delivery_fee,
        'totalAmount',       o.total_amount,
        'createdAt',         o.created_at,
        'items', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                       'productName', i.product_name,
                       'unitPrice',   i.unit_price,
                       'quantity',    i.quantity,
                       'unit',        i.unit,
                       'subtotal',    i.subtotal) ORDER BY i.id)
              FROM public.order_items i
             WHERE i.order_id = o.id), '[]'::jsonb)
    )
    FROM public.orders o
    WHERE o.id = p_order_id;
$$;
REVOKE ALL ON FUNCTION public.order_json(BIGINT) FROM PUBLIC, anon, authenticated;

-- Place an order (guest or signed in). Prices, totals and the delivery fee are
-- always taken from the database — whatever the browser sends is ignored.
-- p_items: [{"productId": 1, "quantity": 50}, ...]
CREATE OR REPLACE FUNCTION public.place_order(
    p_customer_name       TEXT,
    p_customer_phone      TEXT,
    p_payment_method      TEXT,
    p_items               JSONB,
    p_delivery_sub_county TEXT    DEFAULT NULL,
    p_delivery_address    TEXT    DEFAULT NULL,
    p_delivery_lat        NUMERIC DEFAULT NULL,
    p_delivery_lng        NUMERIC DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    ref_alphabet CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    v_reference    TEXT;
    v_order_id     BIGINT;
    v_line         JSONB;
    v_product_id   BIGINT;
    v_quantity     NUMERIC;
    v_product      public.products%ROWTYPE;
    v_subtotal     NUMERIC(12,2) := 0;
    v_delivery_fee NUMERIC(12,2);
BEGIN
    IF length(trim(coalesce(p_customer_name, ''))) = 0 THEN
        RAISE EXCEPTION 'Please enter your name';
    END IF;
    IF length(trim(coalesce(p_customer_phone, ''))) = 0 THEN
        RAISE EXCEPTION 'Please enter your phone number';
    END IF;
    IF p_payment_method IS NULL
       OR p_payment_method NOT IN ('cash_on_delivery', 'cash_in_person', 'bitcoin') THEN
        RAISE EXCEPTION 'Invalid payment method';
    END IF;
    IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Your cart is empty';
    END IF;
    IF jsonb_array_length(p_items) > 50 THEN
        RAISE EXCEPTION 'Too many items in one order';
    END IF;

    -- Unique ECN-XXXXXX reference
    FOR attempt IN 1..10 LOOP
        v_reference := 'ECN-';
        FOR i IN 1..6 LOOP
            v_reference := v_reference
                || substr(ref_alphabet, 1 + floor(random() * length(ref_alphabet))::INT, 1);
        END LOOP;
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.orders WHERE reference = v_reference);
        v_reference := NULL;
    END LOOP;
    IF v_reference IS NULL THEN
        RAISE EXCEPTION 'Could not generate an order reference, please try again';
    END IF;

    INSERT INTO public.orders (
        reference, user_id, customer_name, customer_phone,
        delivery_sub_county, delivery_address, delivery_lat, delivery_lng,
        status, payment_method)
    VALUES (
        v_reference, auth.uid(), trim(p_customer_name), trim(p_customer_phone),
        p_delivery_sub_county, p_delivery_address, p_delivery_lat, p_delivery_lng,
        'received', p_payment_method)
    RETURNING id INTO v_order_id;

    FOR v_line IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        BEGIN
            v_product_id := (v_line ->> 'productId')::BIGINT;
            v_quantity   := (v_line ->> 'quantity')::NUMERIC;
        EXCEPTION WHEN others THEN
            RAISE EXCEPTION 'Invalid item in cart';
        END;
        IF v_product_id IS NULL OR v_quantity IS NULL OR v_quantity < 0.01 THEN
            RAISE EXCEPTION 'Invalid item in cart';
        END IF;

        SELECT * INTO v_product FROM public.products WHERE id = v_product_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product not found: %', v_product_id;
        END IF;
        IF NOT v_product.is_visible THEN
            RAISE EXCEPTION 'Product is not available: %', v_product.name;
        END IF;
        IF v_quantity < v_product.min_order_qty THEN
            RAISE EXCEPTION 'Minimum order for % is % %',
                v_product.name, trim_scale(v_product.min_order_qty), v_product.unit;
        END IF;

        INSERT INTO public.order_items (
            order_id, product_id, product_name, unit_price, quantity, unit, subtotal)
        VALUES (
            v_order_id, v_product.id, v_product.name, v_product.price,
            v_quantity, v_product.unit, v_product.price * v_quantity);

        v_subtotal := v_subtotal + v_product.price * v_quantity;
    END LOOP;

    SELECT CASE WHEN value ~ '^\s*\d+(\.\d+)?\s*$' THEN trim(value)::NUMERIC ELSE 0 END
      INTO v_delivery_fee
      FROM public.site_settings WHERE key = 'delivery_fee_default';
    v_delivery_fee := coalesce(v_delivery_fee, 0);

    UPDATE public.orders
       SET subtotal = v_subtotal,
           delivery_fee = v_delivery_fee,
           total_amount = v_subtotal + v_delivery_fee
     WHERE id = v_order_id;

    RETURN public.order_json(v_order_id);
END;
$$;
REVOKE ALL ON FUNCTION public.place_order(TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, NUMERIC, NUMERIC)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.place_order(TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, NUMERIC, NUMERIC)
    TO anon, authenticated;

-- Track one order by its reference (the order confirmation page and guests
-- use this). Returns NULL if the reference doesn't exist.
CREATE OR REPLACE FUNCTION public.track_order(p_reference TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT public.order_json(o.id)
      FROM public.orders o
     WHERE o.reference = upper(trim(p_reference));
$$;
REVOKE ALL ON FUNCTION public.track_order(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.track_order(TEXT) TO anon, authenticated;

-- Impact page figures: curated numbers from site_settings plus live totals
-- from the (otherwise private) supply-chain tables.
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
        'partnerClubs',        (SELECT count(*) FROM public.clubs WHERE status = 'active'),
        'totalWasteKg',        coalesce((SELECT sum(weight_kg) FROM public.waste_collections), 0)
    );
$$;
REVOKE ALL ON FUNCTION public.get_impact() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_impact() TO anon, authenticated;

COMMIT;
