-- V4__seed_home_hero.sql
-- Landing-page hero content, served via the existing generic content API
-- (GET /content/home/hero -> page_content.content JSONB). Storing the video
-- URL in the DB keeps the hero manageable without a frontend redeploy.
INSERT INTO page_content (page_slug, section_key, content) VALUES
    ('home', 'hero', '{
        "videoUrl": "/glass-hero.mp4",
        "heading": "Turning Waste Into Value.",
        "subtext": "We partner with local clubs and manage waste across Kenya to transform discarded glass and biomass into premium cullet and eco-friendly briquettes."
    }'::jsonb)
ON CONFLICT (page_slug, section_key) DO NOTHING;
