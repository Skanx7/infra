CREATE TABLE IF NOT EXISTS markets.markets (
    market_id UUID PRIMARY KEY DEFAULT uuidv7(),
    
    mic CHAR(4) UNIQUE NOT NULL,
    operating_mic CHAR(4),
    
    name TEXT NOT NULL,
    acronym VARCHAR(20),
    
    country_code CHAR(2),
    city TEXT,
    
    timezone TEXT NOT NULL,
    base_currency_code CHAR(3),
    
    website_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_markets_mic ON markets.markets(mic);
CREATE INDEX idx_markets_acronym ON markets.markets(acronym);

CALL set_auto_update('markets.markets');