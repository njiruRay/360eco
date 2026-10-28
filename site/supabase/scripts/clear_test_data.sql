-- =============================================================================
-- 360 Econovations — clear test data before going live
--
-- Deletes: every order (and its items), every contact-form message, and EVERY
-- customer account with its profile and saved addresses. Order references and
-- ids start again from 1.
-- Keeps: products, categories, product images, page content, site settings,
-- clubs and waste collections.
--
-- To keep one account (e.g. your own), change the DELETE FROM auth.users line to:
--     DELETE FROM auth.users WHERE email <> 'you@example.com';
-- (Saved addresses are cleared for everyone, including a kept account.)
--
-- This cannot be undone. Run in the Supabase SQL Editor; the last result shows
-- what is left (all zeros unless you kept an account).
-- =============================================================================

BEGIN;

TRUNCATE public.order_items, public.orders, public.contact_submissions, public.addresses RESTART IDENTITY;

-- Profiles are removed with their auth user (ON DELETE CASCADE).
DELETE FROM auth.users;

COMMIT;

SELECT (SELECT count(*) FROM public.orders)              AS orders,
       (SELECT count(*) FROM public.order_items)         AS order_items,
       (SELECT count(*) FROM public.contact_submissions) AS messages,
       (SELECT count(*) FROM auth.users)                 AS accounts,
       (SELECT count(*) FROM public.profiles)            AS profiles,
       (SELECT count(*) FROM public.addresses)           AS addresses,
       (SELECT count(*) FROM public.products)            AS products_kept;
