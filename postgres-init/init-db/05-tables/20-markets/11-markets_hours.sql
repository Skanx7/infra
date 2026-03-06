CREATE ENUM IF NOT EXISTS markets.session_type AS ('PRE', 'REGULAR', 'POST');

CREATE TABLE IF NOT EXISTS markets.operating_hours (
    schedule_id UUID PRIMARY KEY DEFAULT uuidv7(),
    exchange_id UUID NOT NULL REFERENCES markets.markets(market_id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), 
    session_type markets.session_type DEFAULT 'REGULAR',
    open_time TIME NOT NULL,  
    close_time TIME NOT NULL, 

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (exchange_id, day_of_week, session_type)
);

CREATE INDEX idx_operating_hours_exchange ON markets.operating_hours(exchange_id);

CALL set_auto_update('markets.operating_hours');