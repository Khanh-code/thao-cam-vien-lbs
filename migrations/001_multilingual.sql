BEGIN;
CREATE TABLE IF NOT EXISTS exhibit_translations (
    exhibit_id integer NOT NULL REFERENCES exhibits(id) ON DELETE CASCADE,
    language text NOT NULL CHECK(language IN ('vi', 'en')),
    name text NOT NULL CHECK(length(trim(name)) > 0),
    description text NOT NULL CHECK(length(trim(description)) > 0),
    audio_file text,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY(exhibit_id, language)
);
CREATE INDEX IF NOT EXISTS idx_exhibits_detection_geog
ON exhibits USING gist ((COALESCE(geom_poly::geography, geom::geography)));
COMMIT;
