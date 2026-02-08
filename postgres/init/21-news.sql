
CREATE TABLE IF NOT EXISTS news (
    id UUID DEFAULT uuidv7(),
    provider_id UUID, 
    source TEXT NOT NULL,
    authors TEXT[] NOT NULL,
    
    title TEXT NOT NULL,
    url TEXT NOT NULL,

    content TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',

    published_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (id, published_at),
    CONSTRAINT unique_url UNIQUE (url, published_at),
    FOREIGN KEY (provider_id) REFERENCES news_providers(id) ON DELETE SET NULL
);

SELECT create_hypertable('news', 'published_at', if_not_exists => TRUE);
CALL set_auto_update('news');