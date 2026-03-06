CREATE TABLE IF NOT EXISTS assets.instruments (
    instrument_id UUID PRIMARY KEY DEFAULT uuidv7(),
    
    company_id UUID REFERENCES companies.companies(company_id) ON DELETE CASCADE,
    underlying_instrument_id UUID REFERENCES assets.instruments(instrument_id) ON DELETE SET NULL,

    name TEXT NOT NULL,                                 
    type_code VARCHAR(10) NOT NULL REFERENCES assets.instruments_type(type_code) ON DELETE RESTRICT,
    
    issue_date DATE,                                    
    maturity_date DATE,                                 
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CALL set_auto_update('assets.instruments');


CREATE INDEX idx_instruments_stocks 
ON assets.instruments(company_id) 
WHERE type_code = 'S';

CREATE INDEX idx_instruments_options 
ON assets.instruments(underlying_instrument_id) 
WHERE type_code = 'O';