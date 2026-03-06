CREATE OR REPLACE PROCEDURE embeddings.register_and_create_model(
    p_model_key TEXT,
    p_is_default BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
    dims INTEGER;
    table_name TEXT;
    full_table_name TEXT;
BEGIN
    SELECT embedding_dim INTO dims 
    FROM embeddings.embedding_models 
    WHERE model_key = p_model_key;

    IF dims IS NULL THEN
        RAISE EXCEPTION 'Model % not recognized', p_model_key;
    END IF;
    
    table_name := normalize_identifier(p_model_key || '_documents');
    full_table_name := format('embeddings.%I', table_name);

    INSERT INTO embeddings.embedding_registry (model_key, is_default)
    VALUES (p_model_key, p_is_default)
    ON CONFLICT (model_key) DO UPDATE SET is_default = EXCLUDED.is_default;

    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %s (
            record_id UUID NOT NULL,
            published_at TIMESTAMPTZ NOT NULL,
            content_type TEXT NOT NULL,
            chunk_content TEXT,
            chunk_index INTEGER NOT NULL DEFAULT 0,
            embedding vector(%s),
            
            metadata JSONB DEFAULT ''{}''::jsonb,
            fts tsvector GENERATED ALWAYS AS (to_tsvector(''english'', coalesce(chunk_content, ''''))) STORED,
            
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),

            PRIMARY KEY (record_id, chunk_index, published_at, content_type)
        )', full_table_name, dims);
        
    BEGIN
        PERFORM create_hypertable(full_table_name, 'published_at', if_not_exists => TRUE);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Table % skipped hypertable creation.', full_table_name;
    END;

    -- 4. Create Partial HNSW and GIN Indexes
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''news''', table_name || '_vec_news_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''wiki''', table_name || '_vec_wiki_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING HNSW (embedding vector_cosine_ops) WHERE content_type = ''tweet''', table_name || '_vec_tweet_', full_table_name);
    
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING GIN (fts)', table_name || '_fts_idx_', full_table_name);
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s USING GIN (metadata)', table_name || '_meta_idx_', full_table_name);

    EXECUTE format('CALL set_auto_update(%L)', full_table_name);
END;
$$;