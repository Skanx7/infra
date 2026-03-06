CREATE TABLE IF NOT EXISTS companies.companies (
    company_id UUID PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL,
    short_name TEXT,
    country_code CHAR(2) REFERENCES world.countries(iso2),
    
    company_metadata JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,

    description TEXT,
    keywords TEXT[],

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_companies_name_trgm ON companies.companies USING GIN (name gin_trgm_ops);
CREATE INDEX idx_companies_short_name_trgm ON companies.companies USING GIN (short_name gin_trgm_ops);

CALL set_auto_update('companies.companies');