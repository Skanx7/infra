CREATE ENUM IF NOT EXISTS markets.holiday_status AS ('CLOSED', 'EARLY_CLOSE');

CREATE TABLE IF NOT EXISTS markets.holidays (
    holiday_id UUID PRIMARY KEY DEFAULT uuidv7(),
    market_id UUID NOT NULL REFERENCES markets.markets(market_id) ON DELETE CASCADE,
    holiday_date DATE NOT NULL,
    name TEXT,
    status markets.holiday_status DEFAULT 'CLOSED',
    early_close_time TIME,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),       

    UNIQUE (market_id, holiday_date)
);

CREATE INDEX idx_holidays_market ON markets.holidays(market_id);
CALL set_auto_update('markets.holidays');