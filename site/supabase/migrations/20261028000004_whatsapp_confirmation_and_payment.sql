-- =============================================================================
-- 360 Econovations — orders are confirmed on WhatsApp; drop "cash in person"
--
-- 1. Payment is Cash on Delivery or Bitcoin only. Existing cash_in_person
--    (test) orders become cash_on_delivery.
-- 2. After placing an order the customer sends it to the business WhatsApp
--    from the confirmation page. Tapping that button calls
--    confirm_order_whatsapp(), which stamps orders.whatsapp_sent_at; the site
--    then shows the order as confirmed (confirmation page and My Orders).
--    In the Table Editor, an empty whatsapp_sent_at means the customer never
--    opened WhatsApp — give them a call.
--
-- Run once in the Supabase SQL Editor. Safe to re-run.
-- =============================================================================

BEGIN;

-- =========================================================
-- 1. Cash on Delivery or Bitcoin only
-- =========================================================

UPDATE public.orders SET payment_method = 'cash_on_delivery' WHERE payment_method = 'cash_in_person';
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_payment_method_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_payment_method_check
    CHECK (payment_method IN ('cash_on_delivery', 'bitcoin'));

-- =========================================================
-- 2. Confirmed on WhatsApp
-- =========================================================

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS whatsapp_sent_at TIMESTAMPTZ;

-- Same as 20261028000002, plus whatsappSentAt.
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
        'whatsappSentAt',    o.whatsapp_sent_at,
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

-- Record that the customer opened WhatsApp with their order. Keeps the first
-- time it happened. Returns the order, or NULL if the reference is unknown.
CREATE OR REPLACE FUNCTION public.confirm_order_whatsapp(p_reference TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_order_id BIGINT;
BEGIN
    UPDATE public.orders
       SET whatsapp_sent_at = coalesce(whatsapp_sent_at, now())
     WHERE reference = upper(trim(p_reference))
    RETURNING id INTO v_order_id;
    IF v_order_id IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN public.order_json(v_order_id);
END;
$$;
REVOKE ALL ON FUNCTION public.confirm_order_whatsapp(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_order_whatsapp(TEXT) TO anon, authenticated;

-- =========================================================
-- 3. place_order: same as 20261028000002, without cash_in_person
-- =========================================================

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
       OR p_payment_method NOT IN ('cash_on_delivery', 'bitcoin') THEN
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

COMMIT;
