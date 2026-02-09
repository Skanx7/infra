CREATE TABLE IF NOT EXISTS assets.markets (
    market_id UUID PRIMARY KEY DEFAULT uuidv7(),
    mic_code VARCHAR(6) NOT NULL UNIQUE,
    country_code VARCHAR(2) NOT NULL,
    description TEXT,
    city TEXT,
    website TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()

);

CALL set_auto_update('assets.markets');