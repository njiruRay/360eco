-- V3__add_user_password.sql
-- Storefront authentication: registered customers need a password.
-- Nullable so guest checkout (which never creates a users row) is unaffected,
-- and any future admin-created customer records remain valid without a password.

ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);
