-- V6__add_order_delivery_location.sql
-- Capture a precise delivery location (map pin) alongside the existing
-- free-text sub-county. lat/lng are nullable so guest/legacy orders still work.
ALTER TABLE orders ADD COLUMN delivery_address VARCHAR(255);
ALTER TABLE orders ADD COLUMN delivery_lat     NUMERIC(9,6);
ALTER TABLE orders ADD COLUMN delivery_lng     NUMERIC(9,6);
