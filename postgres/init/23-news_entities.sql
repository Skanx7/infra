CREATE TABLE IF NOT EXISTS content.news_entities (    
    news_id UUID NOT NULL,
    published_at TIMESTAMPTZ NOT NULL,

    chunk_index INT NOT NULL DEFAULT 0,
    entity_name TEXT NOT NULL,
    ticker TEXT,
    entity_type TEXT,

    llm_sentiment_score FLOAT,
    llm_sentiment_reasoning TEXT,
    sentiment_score FLOAT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (news_id, published_at, entity_name)
);

CREATE INDEX IF NOT EXISTS news_entities_lookup_idx 
    ON content.news_entities (entity_name, published_at DESC);

CREATE INDEX IF NOT EXISTS news_entities_join_idx
    ON content.news_entities (news_id, chunk_index);

SELECT create_hypertable('content.news_entities', 'published_at', if_not_exists => TRUE);

CALL set_auto_update('content.news_entities');