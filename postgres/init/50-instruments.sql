CREATE TABLE IF NOT EXISTS instruments(
    instrument_id UUID PRIMARY KEY DEFAULT uuidv7(),
    company_id UUID REFERENCES assets.companies(company_id) ON DELETE CASCADE,

    instrument_code VARCHAR(50) NOT NULL UNIQUE,
    market_id UUID,
    name TEXT NOT NULL,

    type_code VARCHAR(5) NOT NULL REFERENCES instruments_type(type_code) ON DELETE RESTRICT,
    market_id UUID REFERENCES assets.markets(market_id) ON DELETE SET NULL,

    currency_code VARCHAR(3) NOT NULL REFERENCES world.countries(currency) ON DELETE RESTRICT,
    country_code VARCHAR(2) NOT NULL REFERENCES world.countries(iso2) ON DELETE RESTRICT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
)

CALL set_auto_update('instruments');



-- just to not forget the abbreviations

CREATE TABLE IF NOT EXISTS instruments_type(
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