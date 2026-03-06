CREATE TABLE IF NOT EXISTS assets.instrument_identifiers (
    mapping_id UUID PRIMARY KEY DEFAULT uuidv7(),
    instrument_id UUID NOT NULL REFERENCES assets.instruments(instrument_id) ON DELETE CASCADE,
    
    identifier_type VARCHAR(20) NOT NULL,   -- 'TICKER', 'ISIN', 'CUSIP', 'FIGI'
    identifier_value VARCHAR(50) NOT NULL, 
    
    market_id UUID REFERENCES markets.markets(market_id) ON DELETE CASCADE, 

    currency_code VARCHAR(3),

    valid_from DATE,
    valid_to DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE (instrument_id, identifier_type, identifier_value, market_id, currency_code, valid_from)
);

CREATE INDEX idx_inst_identifiers_search ON assets.instrument_identifiers(identifier_type, identifier_value);

CALL set_auto_update('assets.instrument_identifiers');