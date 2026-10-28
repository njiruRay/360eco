-- 20261028000001_reset_and_schema.sql
-- 360 Econovations — Supabase-only schema (replaces the Spring Boot / Flyway V1–V7).
--
-- WHAT THIS DOES
--   1. Wipes every table the old backend created (all data is test data).
--   2. Recreates the schema for a frontend-only site:
--        - customer accounts live in Supabase Auth (auth.users); public.profiles
--          holds their name/phone and is created automatically on sign-up
--        - admin_users, password_reset_tokens and password columns are gone
--          (staff edit data in the Supabase dashboard; Auth handles passwords)
--   3. Re-seeds the catalogue, settings, page content and demo supply-chain data.
--
-- Row Level Security is switched ON for every table with NO policies yet, so the
-- website can read nothing until the Phase 2 script adds the access rules.
--
-- Run once in: Supabase dashboard → SQL Editor → New query → paste → Run.

BEGIN;

-- =========================================================
-- 1. Wipe the old Spring Boot schema
-- =========================================================

DROP TABLE IF EXISTS
    password_reset_tokens,
    order_items,
    orders,
    processing_batches,
    waste_collections,
    clubs,
    product_images,
    products,
    categories,
    addresses,
    profiles,
    page_content,
    site_settings,
    contact_submissions,
    admin_users,
    users,
    flyway_schema_history
CASCADE;

-- =========================================================
-- Shared helper: keep updated_at current on every edit
-- (including edits made in the dashboard Table Editor)
-- =========================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- =========================================================
-- Domain 1: People
-- =========================================================

-- One row per Supabase Auth user. Login email/password live in auth.users.
CREATE TABLE profiles (
    id         UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name  VARCHAR(150) NOT NULL,
    email      VARCHAR(255) NOT NULL,
    phone      VARCHAR(30),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    UUID         NOT NULL DEFAULT auth.uid() REFERENCES profiles(id) ON DELETE CASCADE,
    label      VARCHAR(80),
    sub_county VARCHAR(100) NOT NULL,
    town       VARCHAR(100),
    street     VARCHAR(150),
    is_default BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);

-- Create the profile automatically when someone signs up. The site passes
-- full_name and phone as sign-up metadata.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, phone)
    VALUES (
        NEW.id,
        COALESCE(NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''), split_part(NEW.email, '@', 1)),
        NEW.email,
        NULLIF(trim(NEW.raw_user_meta_data ->> 'phone'), '')
    );
    RETURN NEW;
END;
$$;
-- Trigger-only: must not be callable from the website.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =========================================================
-- Domain 2: Products & Inventory
-- =========================================================

CREATE TABLE categories (
    id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE products (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(150)  NOT NULL,
    slug           VARCHAR(180)  NOT NULL UNIQUE,
    description    TEXT,
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    unit           VARCHAR(20)   NOT NULL DEFAULT 'kg',
    category_id    BIGINT        REFERENCES categories(id) ON DELETE SET NULL,
    stock_quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    min_order_qty  NUMERIC(12,2) NOT NULL DEFAULT 1 CHECK (min_order_qty > 0),
    is_visible     BOOLEAN       NOT NULL DEFAULT TRUE,
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE TRIGGER products_set_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE product_images (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT       NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    url        VARCHAR(500) NOT NULL,
    is_primary BOOLEAN      NOT NULL DEFAULT FALSE,
    sort_order INT          NOT NULL DEFAULT 0
);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- =========================================================
-- Domain 3: Waste Supply Chain (dashboard-only, never exposed to the site)
-- =========================================================

CREATE TABLE clubs (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           VARCHAR(150) NOT NULL,
    sub_county     VARCHAR(100),
    contact_person VARCHAR(150),
    phone          VARCHAR(30),
    status         VARCHAR(20)  NOT NULL DEFAULT 'onboarding'
                     CHECK (status IN ('active', 'onboarding', 'inactive')),
    joined_at      DATE         NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE waste_collections (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    club_id         BIGINT        NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    collection_date DATE          NOT NULL DEFAULT CURRENT_DATE,
    material_type   VARCHAR(20)   NOT NULL
                      CHECK (material_type IN ('glass', 'biomass', 'bottles')),
    weight_kg       NUMERIC(12,2) NOT NULL CHECK (weight_kg >= 0),
    sub_county      VARCHAR(100),
    notes           TEXT
);
CREATE INDEX idx_waste_collections_club_id ON waste_collections(club_id);

CREATE TABLE processing_batches (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collection_id  BIGINT        REFERENCES waste_collections(id) ON DELETE SET NULL,
    product_id     BIGINT        REFERENCES products(id) ON DELETE SET NULL,
    input_weight   NUMERIC(12,2) NOT NULL CHECK (input_weight > 0),
    output_weight  NUMERIC(12,2) NOT NULL CHECK (output_weight >= 0),
    yield_pct      NUMERIC(6,2)  GENERATED ALWAYS AS (round(output_weight / input_weight * 100, 2)) STORED,
    processed_date DATE          NOT NULL DEFAULT CURRENT_DATE
);

-- =========================================================
-- Domain 4: Orders & Commerce
-- Rows are only ever written by the place_order() function (Phase 2),
-- which snapshots prices and computes totals server-side.
-- =========================================================

CREATE TABLE orders (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference           VARCHAR(30)   NOT NULL UNIQUE,
    -- Nullable: guest checkout is allowed.
    user_id             UUID          REFERENCES profiles(id) ON DELETE SET NULL,
    customer_name       VARCHAR(150)  NOT NULL,
    customer_phone      VARCHAR(30)   NOT NULL,
    delivery_sub_county VARCHAR(100),
    delivery_address    VARCHAR(255),
    delivery_lat        NUMERIC(9,6),
    delivery_lng        NUMERIC(9,6),
    status              VARCHAR(20)   NOT NULL DEFAULT 'received'
                          CHECK (status IN ('received', 'processing', 'out_for_delivery', 'delivered', 'cancelled')),
    -- Cash only (+ bitcoin). No payment gateway / no M-Pesa.
    payment_method      VARCHAR(20)   NOT NULL
                          CHECK (payment_method IN ('cash_on_delivery', 'cash_in_person', 'bitcoin')),
    subtotal            NUMERIC(12,2) NOT NULL DEFAULT 0,
    delivery_fee        NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount        NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);

CREATE TABLE order_items (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     BIGINT        NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id   BIGINT        REFERENCES products(id) ON DELETE SET NULL,
    -- Snapshots: name/price/unit captured at purchase time so later product
    -- edits never change order history.
    product_name VARCHAR(150)  NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL,
    quantity     NUMERIC(12,2) NOT NULL CHECK (quantity > 0),
    unit         VARCHAR(20)   NOT NULL,
    subtotal     NUMERIC(12,2) NOT NULL
);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- =========================================================
-- Domain 5: Content & Settings
-- =========================================================

CREATE TABLE contact_submissions (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(150) NOT NULL,
    email      VARCHAR(255),
    phone      VARCHAR(30),
    message    TEXT         NOT NULL,
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE site_settings (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    key        VARCHAR(100) NOT NULL UNIQUE,
    value      TEXT,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE TRIGGER site_settings_set_updated_at
    BEFORE UPDATE ON site_settings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE page_content (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    page_slug   VARCHAR(100) NOT NULL,
    section_key VARCHAR(100) NOT NULL,
    content     JSONB        NOT NULL DEFAULT '{}'::jsonb,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (page_slug, section_key)
);
CREATE TRIGGER page_content_set_updated_at
    BEFORE UPDATE ON page_content
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =========================================================
-- Lock everything down until Phase 2 adds the access rules
-- =========================================================

ALTER TABLE profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE products            ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images      ENABLE ROW LEVEL SECURITY;
ALTER TABLE clubs               ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_collections   ENABLE ROW LEVEL SECURITY;
ALTER TABLE processing_batches  ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders              ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_content        ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- Seed data (final state of the old V2 + V4 + V5 migrations)
-- =========================================================

INSERT INTO categories (name, slug) VALUES
    ('Glass Cullet', 'glass-cullet'),
    ('Briquettes',   'briquettes'),
    ('Bottles',      'bottles');

-- No product_images yet: cards render blank until real photos are added.
INSERT INTO products (name, slug, description, price, unit, category_id, stock_quantity, min_order_qty, is_visible)
VALUES
    ('Emerald Glass Cullet', 'emerald-glass-cullet',
     'Pure, crushed glass cullet for architectural finishes and industrial manufacturing.',
     40.00, 'kg', (SELECT id FROM categories WHERE slug = 'glass-cullet'), 1500, 50, TRUE),
    ('Pristine White Cullet', 'pristine-white-cullet',
     'Ultra-clear glass chips suitable for high-end terrazzo flooring and decorative landscaping.',
     55.00, 'kg', (SELECT id FROM categories WHERE slug = 'glass-cullet'), 1200, 20, TRUE),
    ('High-Density Briquettes', 'high-density-briquettes',
     'Carbon-neutral heating solution made from pressed organic agricultural waste.',
     25.00, 'kg', (SELECT id FROM categories WHERE slug = 'briquettes'), 3000, 100, TRUE),
    ('Sterilized Amber Bottles', 'sterilized-amber-bottles',
     'Reused 500ml amber bottles, sterilized and ready for beverage or pharmaceutical use.',
     15.00, 'pc', (SELECT id FROM categories WHERE slug = 'bottles'), 800, 24, TRUE);

INSERT INTO site_settings (key, value) VALUES
    ('delivery_fee_default', '200'),
    ('impact_glass_tonnes',  '42.5'),
    ('impact_households',    '210'),
    ('impact_jobs_created',  '14'),
    ('impact_partner_clubs', '10');

INSERT INTO page_content (page_slug, section_key, content) VALUES
    ('sell_to_us', 'buying_prices', '{
        "title": "We Buy Your Used Bottles",
        "currency": "KES",
        "items": [
            {"type": "Beer bottle (500ml)",        "price": 4},
            {"type": "Beer bottle (330ml)",        "price": 3},
            {"type": "Spirit bottle (750ml)",      "price": 6},
            {"type": "Spirit bottle (250ml)",      "price": 4},
            {"type": "Wine bottle (750ml)",        "price": 7},
            {"type": "Soda bottle (glass, 300ml)", "price": 3},
            {"type": "Soda bottle (glass, 500ml)", "price": 4},
            {"type": "Water bottle (glass, 750ml)","price": 5},
            {"type": "Juice bottle (glass)",       "price": 4},
            {"type": "Amber pharmaceutical bottle","price": 5}
        ],
        "organic_waste": {"status": "coming_soon", "note": "Organic waste buying coming soon"}
    }'::jsonb),
    ('home', 'hero', '{
        "videoUrl": "/glass-hero.mp4",
        "heading": "Turning Waste Into Value.",
        "subtext": "We partner with local clubs and manage waste across Kenya to transform discarded glass and biomass into premium cullet and eco-friendly briquettes."
    }'::jsonb);

-- Demo supply-chain data (feeds the live "partner clubs" and "total waste"
-- figures on the Impact page). Replace with real clubs in the Table Editor.
INSERT INTO clubs (name, sub_county, contact_person, phone, status, joined_at) VALUES
    ('Embu Youth Green Club',      'Manyatta',  'Grace Wanjiru', '0712000001', 'active',     DATE '2025-11-03'),
    ('Runyenjes Eco Warriors',     'Runyenjes', 'Peter Njeru',   '0712000002', 'active',     DATE '2026-01-15'),
    ('Kianjokoma Community Group', 'Manyatta',  'Mary Karimi',   '0712000003', 'onboarding', DATE '2026-04-20');

INSERT INTO waste_collections (club_id, collection_date, material_type, weight_kg, sub_county, notes)
SELECT c.id, v.collection_date, v.material_type, v.weight_kg, c.sub_county, v.notes
FROM (VALUES
    ('Embu Youth Green Club',  DATE '2026-05-10', 'glass',   420.00, 'First quarter glass haul'),
    ('Embu Youth Green Club',  DATE '2026-06-14', 'bottles', 180.00, 'Reusable bottles sorted'),
    ('Runyenjes Eco Warriors', DATE '2026-05-22', 'glass',   360.00, NULL),
    ('Runyenjes Eco Warriors', DATE '2026-06-30', 'biomass', 540.00, 'Farm residue for briquettes')
) AS v(club_name, collection_date, material_type, weight_kg, notes)
JOIN clubs c ON c.name = v.club_name;

COMMIT;
