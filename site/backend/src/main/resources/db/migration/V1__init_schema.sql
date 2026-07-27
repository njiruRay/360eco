-- V1__init_schema.sql
-- 360 Econovations — initial database schema.
-- 14 tables across 5 domains. Enum-style columns are modelled as VARCHAR + CHECK
-- constraints so they map cleanly to JPA @Enumerated(EnumType.STRING) in Phase 2.
-- Primary keys use identity columns; timestamps are timestamptz.

-- =========================================================
-- Domain 1: Auth & People
-- =========================================================

CREATE TABLE users (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name  VARCHAR(150) NOT NULL,
    email      VARCHAR(255) NOT NULL UNIQUE,
    phone      VARCHAR(30),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label      VARCHAR(80),
    sub_county VARCHAR(100) NOT NULL,
    town       VARCHAR(100),
    street     VARCHAR(150),
    is_default BOOLEAN      NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_addresses_user_id ON addresses(user_id);

CREATE TABLE admin_users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name          VARCHAR(150) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'viewer'
                    CHECK (role IN ('super_admin', 'manager', 'viewer')),
    last_login    TIMESTAMPTZ
);

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
    min_order_qty  NUMERIC(12,2) NOT NULL DEFAULT 1,
    is_visible     BOOLEAN       NOT NULL DEFAULT TRUE,
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);
CREATE INDEX idx_products_category_id ON products(category_id);

CREATE TABLE product_images (
    id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT       NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    url        VARCHAR(500) NOT NULL,
    is_primary BOOLEAN      NOT NULL DEFAULT FALSE,
    sort_order INT          NOT NULL DEFAULT 0
);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- =========================================================
-- Domain 3: Waste Supply Chain
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
    -- yield_pct is derived from input/output weights (input_weight > 0 guaranteed above).
    yield_pct      NUMERIC(6,2)  GENERATED ALWAYS AS (round(output_weight / input_weight * 100, 2)) STORED,
    processed_date DATE          NOT NULL DEFAULT CURRENT_DATE
);

-- =========================================================
-- Domain 4: Orders & Commerce
-- =========================================================

CREATE TABLE orders (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reference           VARCHAR(30)   NOT NULL UNIQUE,
    -- Nullable: guest checkout is allowed.
    user_id             BIGINT        REFERENCES users(id) ON DELETE SET NULL,
    customer_name       VARCHAR(150)  NOT NULL,
    customer_phone      VARCHAR(30)   NOT NULL,
    delivery_sub_county VARCHAR(100),
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
    updated_by BIGINT       REFERENCES admin_users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE page_content (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    page_slug   VARCHAR(100) NOT NULL,
    section_key VARCHAR(100) NOT NULL,
    content     JSONB        NOT NULL DEFAULT '{}'::jsonb,
    updated_by  BIGINT       REFERENCES admin_users(id) ON DELETE SET NULL,
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (page_slug, section_key)
);
