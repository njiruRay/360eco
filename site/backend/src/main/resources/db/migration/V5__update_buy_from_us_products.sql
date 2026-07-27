-- V5__update_buy_from_us_products.sql
-- Align the catalogue with the approved "Buy From Us" page (4 products) and blank
-- out placeholder images (real product photos to be added later).

-- Emerald Glass Cullet
UPDATE products SET
    description   = 'Pure, crushed glass cullet for architectural finishes and industrial manufacturing.',
    price         = 40.00, unit = 'kg', min_order_qty = 50, is_visible = TRUE, updated_at = now()
WHERE slug = 'emerald-glass-cullet';

-- High-Density Briquettes
UPDATE products SET
    description   = 'Carbon-neutral heating solution made from pressed organic agricultural waste.',
    price         = 25.00, unit = 'kg', min_order_qty = 100, is_visible = TRUE, updated_at = now()
WHERE slug = 'high-density-briquettes';

-- Sterilized Amber Bottles
UPDATE products SET
    description   = 'Reused 500ml amber bottles, sterilized and ready for beverage or pharmaceutical use.',
    price         = 15.00, unit = 'pc', min_order_qty = 24, is_visible = TRUE, updated_at = now()
WHERE slug = 'sterilized-amber-bottles';

-- Retire "Clear Glass Cullet" by repurposing the row into "Pristine White Cullet".
UPDATE products SET
    name          = 'Pristine White Cullet',
    slug          = 'pristine-white-cullet',
    description   = 'Ultra-clear glass chips suitable for high-end terrazzo flooring and decorative landscaping.',
    price         = 55.00, unit = 'kg', min_order_qty = 20,
    category_id   = (SELECT id FROM categories WHERE slug = 'glass-cullet'),
    is_visible    = TRUE, updated_at = now()
WHERE slug = 'clear-glass-cullet';

-- Blank the image cards for now (remove seeded placeholder image URLs).
DELETE FROM product_images;
