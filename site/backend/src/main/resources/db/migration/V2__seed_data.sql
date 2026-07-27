-- V2__seed_data.sql
-- Initial reference/demo data for local development.
-- Idempotent where a natural unique key exists (ON CONFLICT DO NOTHING), so a
-- re-run on a partially seeded DB won't duplicate rows. Prices/URLs marked
-- "placeholder" are development values to refine later with real content.

-- ---------------------------------------------------------
-- Categories
-- ---------------------------------------------------------
INSERT INTO categories (name, slug) VALUES
    ('Glass Cullet', 'glass-cullet'),
    ('Briquettes',   'briquettes'),
    ('Bottles',      'bottles')
ON CONFLICT (slug) DO NOTHING;

-- ---------------------------------------------------------
-- Products (category linked by slug lookup)
-- ---------------------------------------------------------
INSERT INTO products (name, slug, description, price, unit, category_id, stock_quantity, min_order_qty, is_visible)
VALUES
    ('Emerald Glass Cullet', 'emerald-glass-cullet',
     'Crushed, cleaned emerald (green) glass cullet ready for remelting.',
     40.00, 'kg', (SELECT id FROM categories WHERE slug = 'glass-cullet'), 1500, 50, TRUE),
    ('Clear Glass Cullet', 'clear-glass-cullet',
     'Furnace-ready clear glass cullet, sorted and contaminant-free.',
     38.00, 'kg', (SELECT id FROM categories WHERE slug = 'glass-cullet'), 1200, 50, TRUE),
    ('High-Density Briquettes', 'high-density-briquettes',
     'Compressed biomass briquettes with high calorific value and low ash.',
     25.00, 'kg', (SELECT id FROM categories WHERE slug = 'briquettes'), 3000, 20, TRUE),
    ('Sterilized Amber Bottles', 'sterilized-amber-bottles',
     'Reclaimed amber bottles, sterilized and ready for reuse.',
     15.00, 'pc', (SELECT id FROM categories WHERE slug = 'bottles'), 800, 12, TRUE)
ON CONFLICT (slug) DO NOTHING;

-- ---------------------------------------------------------
-- Product images (one primary placeholder each)
-- ---------------------------------------------------------
INSERT INTO product_images (product_id, url, is_primary, sort_order)
SELECT p.id,
       'https://placehold.co/800x600/00652c/ffffff?text=' || replace(p.name, ' ', '+'),
       TRUE, 0
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM product_images pi WHERE pi.product_id = p.id
);

-- ---------------------------------------------------------
-- Site settings: delivery fee + impact stats (shown on Impact page)
-- ---------------------------------------------------------
INSERT INTO site_settings (key, value) VALUES
    ('delivery_fee_default',    '200'),
    ('impact_glass_tonnes',     '42.5'),
    ('impact_households',       '210'),
    ('impact_jobs_created',     '14'),
    ('impact_partner_clubs',    '10')
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------
-- Sell To Us buying prices (page content, JSONB) — placeholder KES prices
-- ---------------------------------------------------------
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
    }'::jsonb)
ON CONFLICT (page_slug, section_key) DO NOTHING;

-- ---------------------------------------------------------
-- Sample partner clubs + waste collections (supply-chain demo data)
-- ---------------------------------------------------------
INSERT INTO clubs (name, sub_county, contact_person, phone, status, joined_at) VALUES
    ('Embu Youth Green Club',       'Manyatta',  'Grace Wanjiru', '0712000001', 'active',     DATE '2025-11-03'),
    ('Runyenjes Eco Warriors',      'Runyenjes', 'Peter Njeru',   '0712000002', 'active',     DATE '2026-01-15'),
    ('Kianjokoma Community Group',  'Manyatta',  'Mary Karimi',   '0712000003', 'onboarding', DATE '2026-04-20');

INSERT INTO waste_collections (club_id, collection_date, material_type, weight_kg, sub_county, notes)
SELECT c.id, v.collection_date, v.material_type, v.weight_kg, c.sub_county, v.notes
FROM (VALUES
    ('Embu Youth Green Club',      DATE '2026-05-10', 'glass',   420.00, 'First quarter glass haul'),
    ('Embu Youth Green Club',      DATE '2026-06-14', 'bottles', 180.00, 'Reusable bottles sorted'),
    ('Runyenjes Eco Warriors',     DATE '2026-05-22', 'glass',   360.00, NULL),
    ('Runyenjes Eco Warriors',     DATE '2026-06-30', 'biomass', 540.00, 'Farm residue for briquettes')
) AS v(club_name, collection_date, material_type, weight_kg, notes)
JOIN clubs c ON c.name = v.club_name;
