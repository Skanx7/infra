CREATE IF NOT EXISTS TABLE instruments(
    instrument_id UUID DEFAULT uuidv7(),
    company_id UUID,

    instrument_code VARCHAR(50) NOT NULL UNIQUE,
    market_id UUID,
    name TEXT NOT NULL,
    type_code VARCHAR(5) NOT NULL,
    market_id UUID,

    currency_code VARCHAR(3) NOT NULL,
    country_code VARCHAR(2) NOT NULL,

    PRIMARY KEY (instrument_id)
    FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE,
    FOREIGN KEY (type_code) REFERENCES instruments_type(type_code) ON DELETE RESTRICT,
    FOREIGN KEY (market_id) REFERENCES markets(market_id) ON DELETE SET NULL
);




-- just to not forget the abbreviations

CREATE IF NOT EXISTS TABLE instruments_type(
    type_code VARCHAR(10) NOT NULL UNIQUE,
    label TEXT NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO instruments_type (type_code, label) VALUES
('S', 'Stock'),
('O', 'Option'),
('C', 'Commodity'),
('D', 'Debt')
ON CONFLICT (type_code) DO NOTHING;