CREATE TABLE IF NOT EXISTS assets.news_providers (
    provider_id UUID PRIMARY KEY DEFAULT uuidv7(),
    name TEXT NOT NULL UNIQUE,
    domain TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CALL set_auto_update('assets.news_providers');
