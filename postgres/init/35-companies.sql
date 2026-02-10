CREATE TABLE IF NOT EXISTS assets.companies (

    company_id UUID PRIMARY KEY DEFAULT uuidv7(),
    ticker TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,               -- 'Apple Inc.'
    short_name TEXT,                  -- 'Apple'
    
    isin VARCHAR(12),                 -- International Securities Identification Number
    lei VARCHAR(20),                  -- Legal Entity Identifier
    cik VARCHAR(10),                  -- CIK for SEC filings
    identifiers JSONB DEFAULT '{}'::jsonb, -- for the sparser ones we put them in here 
    
    -- metadata
    country_code CHAR(2) REFERENCES world.countries(iso2),

    
    -- metadata
    headquarters_country CHAR(2) REFERENCES world.countries(iso2),
    headquarters_city TEXT,
    website TEXT,                     -- 'https://www.apple.com'
    founding_year INTEGER,            -- 1976
    employees_count INTEGER,          -- Useful for normalizing metrics (Revenue/Employee)
    
    exchange VARCHAR(10),             -- 'NASDAQ', 'NYSE'
    currency VARCHAR(3) DEFAULT 'USD',
    is_sp500 BOOLEAN DEFAULT FALSE,
    
    is_active BOOLEAN DEFAULT TRUE,
    delisted_date DATE,

    description TEXT,                 -- "Designs, manufactures, and markets smartphones..."
    keywords TEXT[],                  -- ARRAY['Consumer Electronics', 'AI', 'Services']

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()

);

CREATE INDEX idx_companies_isin ON assets.companies(isin);

-- Index for simple text search (before vector)
CREATE INDEX idx_companies_name_trgm ON assets.companies USING GIN (name gin_trgm_ops);
CREATE INDEX idx_companies_short_name_trgm ON assets.companies USING GIN (short_name gin_trgm_ops);

-- Trigger for updated_at
CALL set_auto_update('assets.companies');