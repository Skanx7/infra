CREATE TABLE IF NOT EXISTS world.countries (
    iso2 CHAR(2) PRIMARY KEY,
    name TEXT NOT NULL,
    continent TEXT,
    currency CHAR(3)
);

CREATE INDEX IF NOT EXISTS idx_countries_continent ON world.countries(continent);
CREATE INDEX IF NOT EXISTS idx_countries_name ON world.countries(name);
