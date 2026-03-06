CREATE TABLE IF NOT EXISTS world.subdivisions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    country_iso2 CHAR(2) NOT NULL REFERENCES world.countries(iso2) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subdiv_country ON world.subdivisions(country_iso2);
CREATE INDEX IF NOT EXISTS idx_subdiv_code ON world.subdivisions(country_iso2, code);
CREATE INDEX IF NOT EXISTS idx_subdiv_name ON world.subdivisions(name);
