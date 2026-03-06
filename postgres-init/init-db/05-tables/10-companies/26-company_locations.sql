CREATE TABLE IF NOT EXISTS companies.company_locations (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    company_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,

    location_type TEXT,
    address TEXT,
    city_id UUID REFERENCES world.cities(id) ON DELETE SET NULL,
    state TEXT,
    country_iso2 CHAR(2) REFERENCES world.countries(iso2),
    coordinates geometry(Point, 4326),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_locations_country ON companies.company_locations(country_iso2);

CALL set_auto_update('companies.company_locations');