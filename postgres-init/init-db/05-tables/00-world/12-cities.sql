CREATE TABLE IF NOT EXISTS world.cities (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    country_iso2 CHAR(2) NOT NULL REFERENCES world.countries(iso2) ON DELETE CASCADE,
    subdivision_name TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    geom geometry(Point, 4326),
    timezone TEXT,
    population INT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cities_country ON world.cities(country_iso2);
CREATE INDEX IF NOT EXISTS idx_cities_name ON world.cities(name);
CREATE INDEX IF NOT EXISTS idx_cities_timezone ON world.cities(timezone);
CREATE INDEX IF NOT EXISTS idx_cities_geo ON world.cities USING GIST(geom);
