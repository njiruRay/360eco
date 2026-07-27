-- db-setup.sql
-- One-time setup: create the application role and database.
-- Run this ONCE as the PostgreSQL superuser (postgres). It is NOT a Flyway
-- migration — the app's tables are created by Flyway on first boot.
--
-- The password below is a LOCAL-DEVELOPMENT value only. Change it for any
-- non-local environment and update backend/src/main/resources/application-local.properties.

CREATE ROLE econovations WITH LOGIN PASSWORD 'econovations';

CREATE DATABASE econovations OWNER econovations;

-- Ensure the app role can create tables in the public schema (PG15+ tightened
-- default public-schema privileges).
\connect econovations
GRANT ALL ON SCHEMA public TO econovations;
