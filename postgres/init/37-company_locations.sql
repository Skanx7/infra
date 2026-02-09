CREATE TABLE IF NOT EXISTS assets.company_locations (
    id SERIAL PRIMARY KEY,
    company_id UUID REFERENCES assets.companies(id) ON DELETE CASCADE,
    
    location_type TEXT, -- 'headquarters', 'operational', 'rd_center', 'data_center'
    is_primary BOOLEAN DEFAULT FALSE,
    
    city TEXT REFERENCES world.cities(name) ON DELETE SET NULL,
    state TEXT REFERENCES world.cities(subdivision_name) ON DELETE SET NULL,
    country_iso2 CHAR(2) REFERENCES world.countries(iso2),
    postal_code TEXT,
    coordinates POINT, 
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_locations_country ON assets.company_locations(country_iso2);

CALL set_auto_update('assets.company_locations');