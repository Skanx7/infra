CREATE TABLE IF NOT EXISTS news_summaries (
    news_id UUID NOT NULL,
    published_at TIMESTAMPTZ NOT NULL,

    llm_model TEXT,
    summary TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (news_id, published_at)
);

CREATE INDEX IF NOT EXISTS news_summaries_published_at_idx ON news_summaries (published_at DESC);
SELECT create_hypertable('news_summaries', 'published_at', if_not_exists => TRUE);

CALL set_auto_update('news_summaries');