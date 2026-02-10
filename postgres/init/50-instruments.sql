CREATE TABLE IF NOT EXISTS assets.instruments_type(
    type_code VARCHAR(10) NOT NULL UNIQUE,
    label TEXT NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS assets.instruments(
    instrument_id UUID PRIMARY KEY DEFAULT uuidv7(),
    company_id UUID REFERENCES assets.companies(company_id) ON DELETE CASCADE,

    instrument_code VARCHAR(50) NOT NULL UNIQUE,
    market_id UUID REFERENCES assets.markets(market_id) ON DELETE SET NULL,
    name TEXT NOT NULL,

    type_code VARCHAR(5) NOT NULL REFERENCES assets.instruments_type(type_code) ON DELETE RESTRICT,
    currency_code VARCHAR(3),
    country_code VARCHAR(2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CALL set_auto_update('assets.instruments');

INSERT INTO assets.instruments_type (type_code, label) VALUES
('S', 'Stock'),
('O', 'Option'),
('C', 'Commodity'),
('D', 'Debt')
ON CONFLICT (type_code) DO NOTHING;