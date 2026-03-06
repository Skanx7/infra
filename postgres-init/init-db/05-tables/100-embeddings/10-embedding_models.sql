CREATE TABLE IF NOT EXISTS embeddings.embedding_models (
    model_key TEXT PRIMARY KEY,   -- (ex: 'bge-m3', 'openai-v3')
    model_name TEXT NOT NULL,     -- (ex: 'BAAI/bge-m3')
    embedding_dim INTEGER NOT NULL,  -- embedding_dim
    provider TEXT DEFAULT 'local',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CALL set_auto_update('embeddings.embedding_models');